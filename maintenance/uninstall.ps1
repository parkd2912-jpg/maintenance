# -*- coding: utf-8 -*-
# ============================================================
#  Auto Maintenance - 제거
#  바탕화면 "자동 유지보수 제거" / "remove maintenance" 바로가기가 실행하는 파일.
#  - 예약 작업(자동 점검)을 끄고 바로가기를 지웁니다.
#    (v1.7.0: 언어 전환 전에 만들어 둔 바로가기까지 모든 이름 정리)
#  - 로그/설정/이전 결과는 지우지 않습니다(나중에 다시 설치해도 이어짐).
#  - -RestoreAds : 광고/추천 설정(레지스트리·hosts·DNS·예약 작업)만 원래대로 되돌립니다.
# ============================================================

param([switch]$RestoreAds)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# --- 인자 안전 조인 (PS 5.1 대응) ---
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
# 설치 시 언어에 상관없이 모든 세트(구 이름 포함)를 지운다(언어 전환 후 잔여 바로가기 방지).
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

# 광고/추천 설정 복원 (adbackup\ad-state.json / dns-state.json / hosts 마커 블록).
#   maintenance.ps1 의 AdQuiet/AdFilter 로 바꾼 것만 되돌린다. 사용자가 직접 만든 hosts 줄은 건드리지 않는다.
function Restore-AdSettings {
  $backupDir = Join-Path $root 'Simple maintenance\adbackup'
  $adStatePath = Join-Path $backupDir 'ad-state.json'
  $dnsStatePath = Join-Path $backupDir 'dns-state.json'
  $restored = 0
  $warn = @()

  # (1) HKCU 값 + SoftLanding 예약 작업
  if (Test-Path -LiteralPath $adStatePath) {
    try {
      $st = Get-Content -LiteralPath $adStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($sv in @($st.values)) {
        if ($null -eq $sv) { continue }
        try {
          if ($sv.existed) { Set-ItemProperty -Path $sv.path -Name $sv.name -Value $sv.value -ErrorAction Stop }
          else { Remove-ItemProperty -Path $sv.path -Name $sv.name -ErrorAction SilentlyContinue }
          $restored++
        } catch { $warn += "레지스트리 복원 실패: $($sv.name)" }
      }
      foreach ($tk in @($st.tasks)) {
        if ($null -eq $tk) { continue }
        try {
          $null = Enable-ScheduledTask -TaskPath $tk.path -TaskName $tk.name -ErrorAction Stop
          $restored++
        } catch { $warn += "예약 작업 복원 실패: $($tk.name)" }
      }
      Remove-Item -LiteralPath $adStatePath -Force -ErrorAction SilentlyContinue
      Write-Host '  레지스트리/예약 작업 복원'
    } catch { $warn += "ad-state.json 읽기 실패: $($_.Exception.Message)" }
  }

  # (2) hosts 마커 블록 제거 (최초 백업 hosts.orig.bak 은 지우지 않는다)
  $hostsPath = Join-Path $env:SystemRoot 'System32\drivers\etc\hosts'
  $ms = '# >>> AutoMaintenance AdBlock v1 >>>'
  $me = '# <<< AutoMaintenance AdBlock v1 <<<'
  if (Test-Path -LiteralPath $hostsPath) {
    try {
      $raw = [IO.File]::ReadAllText($hostsPath, [Text.Encoding]::Default)
      if ($raw.Contains($ms)) {
        $kept = New-Object System.Collections.ArrayList
        $inBlock = $false
        foreach ($ln in @($raw -split "`r?`n")) {
          $t = $ln.Trim()
          if ($t -eq $ms) { $inBlock = $true; continue }
          if ($t -eq $me) { $inBlock = $false; continue }
          if (-not $inBlock) { $null = $kept.Add($ln) }
        }
        while ($kept.Count -gt 0 -and [string]::IsNullOrWhiteSpace([string]$kept[$kept.Count - 1])) { $kept.RemoveAt($kept.Count - 1) }
        $new = (($kept -join "`r`n").TrimEnd()) + "`r`n"
        [IO.File]::WriteAllText($hostsPath, $new, [Text.Encoding]::Default)
        $restored++
        Write-Host '  hosts 차단 목록 제거'
      }
    } catch { $warn += "hosts 복원 실패: $($_.Exception.Message)" }
  }

  # (3) DNS 서버 원래대로
  if (Test-Path -LiteralPath $dnsStatePath) {
    try {
      $ds = Get-Content -LiteralPath $dnsStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($rec in @($ds.adapters)) {
        if ($null -eq $rec) { continue }
        try {
          $ad = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { [string]$_.InterfaceGuid -eq [string]$rec.guid } | Select-Object -First 1
          if (-not $ad) { continue }
          $prev = @($rec.servers | Where-Object { $_ })
          if ($prev.Count -gt 0) {
            Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ServerAddresses $prev -ErrorAction Stop
          } else {
            Set-DnsClientServerAddress -InterfaceIndex $ad.ifIndex -ResetServerAddresses -ErrorAction Stop
          }
          $restored++
          Write-Host "  DNS 복원: $($rec.alias)"
        } catch { $warn += "DNS 복원 실패($($rec.alias)): $($_.Exception.Message)" }
      }
      Remove-Item -LiteralPath $dnsStatePath -Force -ErrorAction SilentlyContinue
    } catch { $warn += "dns-state.json 읽기 실패: $($_.Exception.Message)" }
  }

  if ($restored -gt 0) { try { $null = ipconfig /flushdns 2>&1 } catch { } }
  if ($restored -eq 0) { Write-Host '  (복원할 광고 설정이 없습니다)' }
  else { Write-Host "  광고 설정 복원 완료: $restored 항목" }
  foreach ($w in $warn) { Write-Host "  (경고) $w" }
  return ($warn.Count -eq 0)
}

if (-not (Test-Admin)) {
  Write-Host (L '관리자 권한이 필요합니다. 확인 창에서 "예"를 누르세요...' 'Administrator rights are required. Click "Yes" in the prompt...')
  try {
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)
    if ($RestoreAds) { $argList += '-RestoreAds' }
    Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Verb RunAs -ArgumentList (Join-CliArgs $argList) | Out-Null
  } catch {
    Write-Host (L '제거를 취소했습니다.' 'Removal cancelled.')
    Start-Sleep -Seconds 2
  }
  exit
}

# --- 광고 설정만 복원하고 끝내는 경로 (uninstall.ps1 -RestoreAds) ---
if ($RestoreAds) {
  Write-Host ''
  Write-Host '=========================================='
  Write-Host (L '   광고/추천 설정 복원' '   Restore ad/recommendation settings')
  Write-Host ("   {0}" -f $kitVersionText)
  Write-Host '=========================================='
  Write-Host ''
  $ok = Restore-AdSettings
  Write-Host ''
  if ($ok) { Write-Host (L '완료. 필요한 프로그램을 다시 시작하면 원래대로 돌아옵니다.' 'Done. Restart any affected programs to see the changes.') }
  else { Write-Host (L '일부 항목을 복원하지 못했습니다. 위 경고를 확인하세요.' 'Some items could not be restored. Check the warnings above.') }
  Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close')
  exit 0
}

Write-Host ''
Write-Host '=========================================='
Write-Host (L '   자동 유지보수 제거' '   Auto Maintenance - Remove')
Write-Host ("   {0}" -f $kitVersionText)
Write-Host '=========================================='
Write-Host ''
$answer = Read-Host (L '자동 점검을 끌까요? (y = 예, 그 외 = 취소)' 'Turn off the automatic check? (y = yes, anything else = cancel)')
if ($answer -notmatch '^(y|Y|ㅛ|예)$') {
  Write-Host (L '취소했습니다. 아무것도 바뀌지 않았습니다.' 'Cancelled. Nothing was changed.')
  Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close')
  exit 0
}

# 광고/추천 설정을 켜 둔 적이 있으면 함께 되돌릴지 묻는다(권장: 예).
$adBackup = Join-Path $root 'Simple maintenance\adbackup'
$restoreAds = $false
if (Test-Path -LiteralPath $adBackup) {
  Write-Host ''
  $a2 = Read-Host (L '광고/추천 설정도 원래대로 되돌릴까요? (y = 예, 그 외 = 그대로 두기)' 'Restore ad/recommendation settings too? (y = yes, anything else = leave as is)')
  if ($a2 -match '^(y|Y|ㅛ|예)$') { $restoreAds = $true }
  Write-Host ''
}

# --- 예약 작업 제거 ---
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($task) {
  try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
    Write-Host (L "  예약 작업 제거: $taskName" "  Scheduled task removed: $taskName")
  } catch {
    Write-Host (L "  (경고) 예약 작업 제거 실패: $($_.Exception.Message)" "  (Warning) Failed to remove scheduled task: $($_.Exception.Message)")
  }
} else {
  Write-Host (L '  예약 작업이 이미 없습니다.' '  No scheduled task found.')
}

# --- 바로가기 제거 (양쪽 언어 세트 모두) ---
$desktop = [Environment]::GetFolderPath('Desktop')
foreach ($lnk in $allShortcutNames) {
  $p = Join-Path $desktop $lnk
  if (Test-Path -LiteralPath $p) {
    try { Remove-Item -LiteralPath $p -Force -ErrorAction Stop; Write-Host (L "  바로가기 제거: $lnk" "  Shortcut removed: $lnk") } catch { }
  }
}

if ($restoreAds) {
  Write-Host (L '[광고/추천 설정 복원]' '[Restoring ad/recommendation settings]')
  $null = Restore-AdSettings
  Write-Host ''
}

Write-Host ''
Write-Host (L '제거 완료. 로그와 설정은 그대로 남아 있습니다.' 'Removal complete. Logs and settings were left untouched.')
Write-Host (L '다시 쓰려면 install.ps1 을 실행하세요.' 'To use it again, run install.ps1.')
Read-Host (L 'Enter 키를 누르면 닫힙니다' 'Press Enter to close')
