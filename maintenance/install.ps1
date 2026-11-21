# -*- coding: utf-8 -*-
# ============================================================
#  Auto Maintenance - 설치 (1회만 실행)
#  - 관리자 권한을 자동으로 요청합니다.
#  - 6일 주기 자동 점검 예약 작업을 등록합니다.
#  - 바탕화면 바로가기를 만듭니다 (v1.7.0: 시스템 언어에 따라 이름 결정).
#      한국어: 자동 유지보수 점검 / 자동 유지보수 피드백 / 자동 유지보수 제거
#      그 외  : auto-maintenance / feedback maintenance / remove maintenance
#  - 첫 점검을 지금 실행합니다(35초 내외).
#  컴맹용: 이 파일을 더블클릭 → "예" → 끝.
# ============================================================
param([switch]$NoFirstRun, [string]$ReportTo = '', [switch]$NoPause)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# --- 인자 안전 조인 (PS 5.1 대응) ---
# Start-Process -ArgumentList / 예약 작업 / 바로가기는 문자열로 넘긴다.
# 경로에 공백·따옴표·$ 가 있어도 인자로 분리되지 않도록 Windows 커맨드라인 규칙으로 이스케이프한다.
# CANONICAL HELPER v1: 아래 2개 함수는 6개 스크립트 사본이 모두 동일해야 함. 변경 시 전부 갱신 + tests\verify-helper-parity.ps1 검증.
function ConvertTo-CliArg {
  param([AllowNull()][string]$Value)
  if ($null -eq $Value) { return '""' }
  $v = [string]$Value
  $v = [regex]::Replace($v, '(\\*)"', '$1$1\"')
  $v = [regex]::Replace($v, '(\\+)$', '$1$1')
  if ($v -match '[\s"]') { return '"' + $v + '"' }
  return $v
}
function Join-CliArgs {
  param([string[]]$Arguments)
  return (@($Arguments | ForEach-Object { ConvertTo-CliArg $_ }) -join ' ')
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$sm = Join-Path $root 'Simple maintenance'
$wrapper = Join-Path $root 'run-maintenance.ps1'
$maint = Join-Path $sm 'maintenance.ps1'
$runNow = Join-Path $root 'run-now.ps1'
$uninstall = Join-Path $root 'uninstall.ps1'
$feedback = Join-Path $root 'feedback.ps1'

# v1.16.0: Ulanzi 버튼용 버전 안내 (현재/다음/예약 수 + 메모장 요약)
$versionGuide = Join-Path $root '버전안내.ps1'
$launcher = Join-Path $root 'install.cmd'
$taskName = 'OpenCode-Maintenance'

# --- 버전 (2026-11-14) --- VERSION 파일(1줄: 버전, 2줄: 날짜)이 기준.
function Get-KitVersionText {
  try {
    $vf = Join-Path $root 'VERSION'
    if (Test-Path -LiteralPath $vf) {
      $vlines = @(Get-Content -LiteralPath $vf -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
      if ($vlines.Count -ge 1) {
        $v = ([string]$vlines[0]).Trim()
        if ($vlines.Count -ge 2) { return ("v$v (" + ([string]$vlines[1]).Trim() + ")") }
        return "v$v"
      }
    }
  } catch { }
  return 'vunknown'
}
$kitVersionText = Get-KitVersionText

# --- Windows 언어 감지 (v1.6.0): 한국어면 ko, 아니면 en ---
# PowerShell 5.1 의 CurrentUICulture 는 설치 언어(en-US)일 수 있어 모든 후보를 훑는다.
function Get-KitLanguage {
  $tags = @()
  try {
    $t = [System.Globalization.CultureInfo]::CurrentUICulture.Name
    if (-not [string]::IsNullOrWhiteSpace($t)) { $tags += $t }
  } catch { }
  try {
    $l = @(Get-WinUserLanguageList) | Select-Object -First 1
    if ($l -and -not [string]::IsNullOrWhiteSpace($l.LanguageTag)) { $tags += $l.LanguageTag }
  } catch { }
  try {
    $t = [System.Globalization.CultureInfo]::CurrentCulture.Name
    if (-not [string]::IsNullOrWhiteSpace($t)) { $tags += $t }
  } catch { }
  try {
    $t = (Get-WinSystemLocale).Name
    if (-not [string]::IsNullOrWhiteSpace($t)) { $tags += $t }
  } catch { }
  foreach ($tag in @($tags | Where-Object { $_ })) {
    if ($tag -match '^ko([-_]|$)') { return 'ko' }
  }
  return 'en'
}
$kitLang = Get-KitLanguage
function L {
  param([string]$Ko, [string]$En)
  if ($kitLang -eq 'ko') { return $Ko }
  return $En
}
# 바로가기 이름 (v1.7.0): 한국어=한글 이름 / 그 외=auto-maintenance 계열
$shortcutNames = if ($kitLang -eq 'ko') {
  @{ Check = '자동 유지보수 점검.lnk'; Feedback = '자동 유지보수 피드백.lnk'; Remove = '자동 유지보수 제거.lnk'; VersionGuide = '자동 유지보수 버전 안내.lnk' }
} else {
  @{ Check = 'auto-maintenance.lnk'; Feedback = 'feedback maintenance.lnk'; Remove = 'remove maintenance.lnk'; VersionGuide = 'version guide.lnk' }
}
# 언어 전환 후 재설치 시 이전 언어의 바로가기가 남지 않도록 모든 세트(구 이름 포함)를 정리한다.
$allShortcutNames = @(
  '자동 유지보수 점검.lnk', '자동 유지보수 피드백.lnk', '자동 유지보수 제거.lnk', '자동 유지보수 버전 안내.lnk',
  'maintenance.lnk', 'maintenance feedback.lnk', 'maintenance remove.lnk', 'version guide.lnk',
  'auto-maintenance.lnk', 'feedback maintenance.lnk', 'remove maintenance.lnk'
)

function Test-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Step($msg) { Write-Host "  $msg" }

# --- 1. 관리자 권한 (없으면 스스로 다시 실행) ---
if (-not (Test-Admin)) {
  Write-Host (L '관리자 권한이 필요합니다. 확인 창에서 "예"를 누르세요...' 'Administrator rights are required. Click "Yes" in the prompt...')
  # 사용자 바탕화면 경로를 미리 잡아 관리자 권한으로 넘긴다(관리자 계정이 다를 때 대비).
  $userDesktop = [Environment]::GetFolderPath('Desktop')
  # $PSCommandPath(자기 자신)만 사용하고, 인자는 배열로 분리한 뒤 안전하게 조인한다.
  $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-ReportTo', $userDesktop)
  if ($NoFirstRun) { $argList += '-NoFirstRun' }
  if ($NoPause) { $argList += '-NoPause' }
  try {
    Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList (Join-CliArgs $argList) | Out-Null
  } catch {
    Write-Host (L '설치를 취소했습니다(관리자 권한 거부).' 'Installation cancelled (admin rights denied).')
  }
  exit
}

if ([string]::IsNullOrWhiteSpace($ReportTo)) { $ReportTo = [Environment]::GetFolderPath('Desktop') }

Write-Host ''
Write-Host '=========================================='
Write-Host (L '   자동 유지보수 설치' '   Auto Maintenance - Install')
Write-Host ("   {0}" -f $kitVersionText)
Write-Host '=========================================='
Write-Host ''

# --- 2. 파일 확인 ---
# .cmd 런처도 배포 패키지의 일부이므로 존재와 기본 내용을 함께 확인한다.
# 내용 무결성은 릴리즈 ZIP 전체의 .sha256 으로 이미 검증되지만, 패키징 누락은 여기서 막는다.
foreach ($f in @($launcher, $wrapper, $maint, $runNow, $uninstall, $feedback, $versionGuide)) {
  if (-not (Test-Path -LiteralPath $f)) {
    Write-Host (L "오류: 필요한 파일이 없습니다 → $f" "Error: required file missing → $f")
    Write-Host (L '압축을 풀지 않았거나 파일이 이동되었습니다. 폴더째로 다시 받아 실행하세요.' 'The ZIP was not extracted or files were moved. Re-download the whole folder and run it.')
    Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close')
    exit 1
  }
}
$launcherText = [IO.File]::ReadAllText($launcher)
if ($launcherText -notmatch '(?i)install\.ps1') {
  Write-Host (L "오류: 런처 내용이 올바르지 않습니다 → $launcher" "Error: invalid launcher content → $launcher")
  Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close')
  exit 1
}
Write-Step (L '파일 확인 완료' 'Files verified')

# --- 3. 스크립트 문법 검사 (깨진 파일로 예약 작업을 걸지 않기 위해) ---
# 지정된 파일만이 아니라 dot-source/하위 호출 대상까지 포함해 설치 폴더 전체를 재귀 검사한다.
$allScripts = @(Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Extension -in '.ps1', '.psm1' })
if ($allScripts.Count -eq 0) { $allScripts = @(Get-Item -LiteralPath $maint) }
foreach ($f in $allScripts) {
  $tok = $null; $err = $null
  $null = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tok, [ref]$err)
  if ($err -and $err.Count -gt 0) {
    Write-Host (L "오류: 스크립트가 손상되었습니다 → $($f.FullName)" "Error: script is corrupted → $($f.FullName)")
    Write-Host ('  ' + $err[0].Message)
    Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close')
    exit 1
  }
}
Write-Step (L "스크립트 검사 완료 ($($allScripts.Count)개)" "Scripts checked ($($allScripts.Count))")

# --- 4. 설정 파일 (없을 때만 기본값 생성) ---
$cfgPath = Join-Path $sm 'config.json'
if (-not (Test-Path -LiteralPath $cfgPath)) {
  $cfg = [ordered]@{
    setupComplete            = $true
    schedule                 = $false
    logToFile                = $false
    closeBehavior            = 'none'
    registerTask             = $false
    enableLogging            = $false
    maintenanceCadenceHours  = 144
    idleConsoleMinutes       = 5
    resultRetentionDays      = 90
    chkdskDays               = 12
    heavyCheckDays           = 30
    licenseCheckDays         = 30
    watchedTasks             = @('\OpenCode-Maintenance', '\FixNetworkMetric', '\opencode-cleanup', '\OpenCode-ReplayCleanup-3mo')
    watchedTaskMaxAgeDays    = 8
    eventLookbackDays        = 7
    notifyOnFail             = $true
    hfCacheWarnGB            = 150
    # 삭제 전 확인 + 임시 폴더 정리 안전장치 (2026-11-12 사고 후 추가)
    #   ※ 삭제는 항상 목록 확인 + y 입력 후에만 실행된다(끄는 설정 없음).
    tempMinAgeDays           = 1
    tempCleanupMaxGB         = 5
    # 광고/추천 정리: 기본은 "조용히"만 (hosts/DNS 차단은 사용자가 켜야 동작)
    adQuiet                  = $true
    adQuietKeepLockScreen    = $true
    adQuietMutePromoToasts   = $true
    adQuietDisableTipsTasks  = $true
    adBlockEnabled           = $false
    adBlockCategories        = @('ads')
    adBlockExtraDomains      = @()
    adBlockAllowDomains      = @()
    adBlockMaxDomains        = 500
    adDnsEnabled             = $false
    adDnsServers             = @('94.140.14.14', '94.140.15.15')
  }
  $cfg | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $cfgPath -Encoding UTF8
  Write-Step (L '설정 파일 생성' 'Config file created')
} else {
  Write-Step (L '설정 파일 유지(기존 설정 사용)' 'Config file kept (existing settings used)')
}

# wrapper(주기 게이트)가 읽는 최상위 config.json — 없으면 wrapper 가 즉시 exit 1 로 죽는다.
$runnerCfgPath = Join-Path $root 'config.json'
if (-not (Test-Path -LiteralPath $runnerCfgPath)) {
  $runnerCfg = [ordered]@{
    diskThresholdGB       = 10
    maintenanceCadenceHours = 144
    maintenanceEnabled    = $true
    setupComplete         = $true
    logToFile             = $false
    closeBehavior         = 'once'
    registerTask          = $false
    enableLogging         = $false
    schedule              = $false
    idleConsoleMinutes    = 5
  }
  $runnerCfg | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $runnerCfgPath -Encoding UTF8
  Write-Step (L '실행 설정 생성 (config.json)' 'Runner config created (config.json)')
}

# --- 5. 예약 작업 등록 (매일 04:00 + 로그온 시, 실제 실행 여부는 6일 주기 게이트가 판단) ---
try {
  $taskArgText = Join-CliArgs @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', $wrapper)
  $action = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument $taskArgText
  $triggers = @(
    (New-ScheduledTaskTrigger -Daily -At '04:00'),
    (New-ScheduledTaskTrigger -AtLogOn -User ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME))
  )
  $triggers[1].Delay = 'PT5M'
  $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit (New-TimeSpan -Hours 72) -MultipleInstances IgnoreNew
  $principal = New-ScheduledTaskPrincipal -UserId ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME) -LogonType Interactive -RunLevel Highest
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers -Settings $settings -Principal $principal -Force | Out-Null
  Write-Step (L '자동 점검 예약 등록 완료 (6일에 1번, PC가 꺼져 있었으면 다음에 켤 때)' 'Scheduled task registered (once every 6 days; next startup if PC was off)')
} catch {
  Write-Host (L "오류: 예약 작업 등록 실패 → $($_.Exception.Message)" "Error: failed to register scheduled task → $($_.Exception.Message)")
  Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close')
  exit 1
}

# --- 6. 바탕화면 바로가기 (v1.7.0: 시스템 언어에 따라 이름 결정) ---
try {
  $desktop = [Environment]::GetFolderPath('Desktop')
  # 이전 언어로 만들어 둔 바로가기가 있으면 먼저 정리한다(언어 전환/재설치 대비).
  foreach ($oldName in $allShortcutNames) {
    $oldPath = Join-Path $desktop $oldName
    if (Test-Path -LiteralPath $oldPath) {
      Remove-Item -LiteralPath $oldPath -Force -ErrorAction SilentlyContinue
    }
  }
  $ws = New-Object -ComObject WScript.Shell
  $defs = @(
    @{ Name = $shortcutNames.Check;    Script = $runNow;    Desc = (L '지금 바로 점검하고 결과를 보여줍니다' 'Run a check now and show the result') },
    @{ Name = $shortcutNames.Feedback; Script = $feedback;  Desc = (L '개인정보·위험코드를 지운 뒤 동의/비동의를 선택해 GitHub에 올립니다' 'Masks personal info and risky code, then asks consent before uploading to GitHub') },
    @{ Name = $shortcutNames.Remove;   Script = $uninstall; Desc = (L '자동 점검을 끄고 바로가기를 지웁니다' 'Turns off the automatic check and removes the shortcuts') },
    @{ Name = $shortcutNames.VersionGuide; Script = $versionGuide; Desc = (L '현재/다음 버전과 예약 현황을 메모장으로 보여줍니다 (Ulanzi 버튼용)' 'Shows current/next version and schedule in Notepad (for Ulanzi button)') }
  )
  foreach ($d in $defs) {
    $lnkPath = Join-Path $desktop $d.Name
    $lnk = $ws.CreateShortcut($lnkPath)
    $lnk.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
    $lnk.Arguments = Join-CliArgs @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $d.Script)
    $lnk.WorkingDirectory = $root
    $lnk.IconLocation = "$env:SystemRoot\System32\imageres.dll,68"
    $lnk.Description = $d.Desc
    $lnk.Save()
  }
  Write-Step (L '바탕화면 바로가기 생성 (점검 / 피드백 / 제거 / 버전 안내)' 'Desktop shortcuts created (check / feedback / remove / version guide)')
  Write-Step (L "바로가기 이름: $($shortcutNames.Check) / $($shortcutNames.Feedback) / $($shortcutNames.Remove) / $($shortcutNames.VersionGuide)" "Shortcut names: $($shortcutNames.Check) / $($shortcutNames.Feedback) / $($shortcutNames.Remove) / $($shortcutNames.VersionGuide)")
} catch {
  Write-Host (L "  (경고) 바로가기 생성 실패: $($_.Exception.Message)" "  (Warning) Failed to create shortcuts: $($_.Exception.Message)")
}

# --- 7. 첫 점검 ---
if (-not $NoFirstRun) {
  Write-Host ''
  Write-Host (L '첫 점검을 시작합니다. 창을 닫지 마세요 (35초 내외).' 'Starting the first check. Do not close this window (about 35 seconds).')
  Write-Host ''
  & $wrapper -Force -ReportTo $ReportTo
  $resPath = Join-Path $sm 'last-result.json'
  if (Test-Path -LiteralPath $resPath) {
    $r = Get-Content -LiteralPath $resPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host ''
    Write-Host (L '--------------- 결과 ---------------' '--------------- Result ---------------')
    Write-Host $(if ($r.status -eq 'PASS') { (L '결과: 정상 — 문제를 찾지 못했습니다.' 'Result: OK — no issues found.') } else { (L '결과: 확인이 필요한 항목이 있습니다.' 'Result: some items need your attention.') })
    $fixLine = L "자동으로 고친 것: {0}건 / 직접 확인할 것: {1}건" "Auto-fixed: {0} / needs manual review: {1}"
    Write-Host ($fixLine -f @($r.autoFixes).Count, @($r.recommendations).Count)
    $latest = $null
    foreach ($dir in @($ReportTo, ([Environment]::GetFolderPath('Desktop')))) {
      if ([string]::IsNullOrWhiteSpace($dir) -or -not (Test-Path -LiteralPath $dir)) { continue }
      # 2026-11-17 (v1.3.0): 4개 이상이면 '자동점검결과' 폴더로 옮겨지므로 그 폴더도 본다.
      foreach ($scanDir in @($dir, (Join-Path $dir '자동점검결과'))) {
        if (-not (Test-Path -LiteralPath $scanDir -PathType Container)) { continue }
        $cand = Get-ChildItem -LiteralPath $scanDir -Filter '자동유지보수_*.txt' -File -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($cand -and (-not $latest -or $cand.LastWriteTime -gt $latest.LastWriteTime)) { $latest = $cand }
      }
      if ($latest) { break }
    }
    if (-not $latest) {
      $copy = Join-Path $sm 'logs\last-report.txt'
      if (Test-Path -LiteralPath $copy) { $latest = Get-Item -LiteralPath $copy }
    }
    if ($latest) {
      Write-Host (L "자세한 결과 파일: $($latest.FullName)" "Detailed result file: $($latest.FullName)")
      try { Invoke-Item $latest.FullName } catch { }
    }
  } else {
    Write-Host ''
    Write-Host (L '첫 점검이 완료되지 않았습니다. 로그를 확인하세요:' 'The first check did not finish. Check the logs:')
    Write-Host ("  " + (Join-Path $root 'logs\runner-*.log'))
  }
}

Write-Host ''
Write-Host (L '설치 완료. 이제부터 6일에 한 번 자동으로 점검합니다.' 'Install complete. Automatic checks now run every 6 days.')
$checkDisplayName = $shortcutNames.Check -replace '\.lnk$',''
Write-Host (L "바탕화면의 ""$checkDisplayName""을 더블클릭하면 언제든 직접 점검할 수 있습니다." "Double-click ""$checkDisplayName"" on the Desktop to run a check anytime.")
Write-Host (L '컴퓨터를 잘 모르면 "newbie.txt"를, 의견을 보내려면 피드백 바로가기를 사용하세요.' 'If you are new to PCs, see "newbie.txt"; to send feedback, use the feedback shortcut.')
# v1.8.0: 업데이트 스크립트에서 호출할 때는 Enter 입력을 기다리지 않는다.
if (-not $NoPause) { Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close') }
