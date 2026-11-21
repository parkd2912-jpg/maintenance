# -*- coding: utf-8 -*-
# ============================================================
#  Auto Maintenance - 미리검증(Pre-Verify) [로컬 운영 스크립트 / ZIP 미포함]
#  - GitHub 의 미리검증 릴리스(tag vX.Y.Z-rcN, prerelease)를 내려받아
#    현재 설치를 건드리지 않는 별도 canary 폴더에 펼친 뒤
#    파일구성 / 구문 / UTF-8 BOM / VERSION / 회귀 SelfTest 를 검사한다.
#  - 결과는 바탕화면 '자동유지보수_미리검증결과.txt' 에 보고만 한다.
#  - 자동 삭제·변경·업로드 없음. RC 는 [version] 파서가 무시하므로
#    주간 자동업데이트(안정 채널)는 이 릴리스를 절대 설치하지 않는다.
#  - UTF-8 BOM 유지 필수 (PowerShell 5.1)
# ============================================================
param([switch]$NoPause)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$log     = 'H:\AutoMaintenance_PreVerify.log'
$desktop = [Environment]::GetFolderPath('Desktop')
$report  = Join-Path $desktop '자동유지보수_미리검증결과.txt'
$api     = 'https://api.github.com/repos/argenluna/maintenance/releases?per_page=100'

function L([string]$s) {
  $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $s
  try { Add-Content -LiteralPath $log -Value $line -Encoding UTF8 } catch { }
  Write-Host $line
}

$script:rows = New-Object System.Collections.ArrayList
function Add-Row([string]$name, [bool]$ok, [string]$detail) {
  $mark = if ($ok) { 'PASS' } else { 'FAIL' }
  $null = $script:rows.Add([pscustomobject]@{ Name = $name; Ok = $ok; Detail = $detail })
  L ("{0}  {1} - {2}" -f $mark, $name, $detail)
}

function Test-TrustedUrl {
  param([AllowNull()][string]$Url)
  if ([string]::IsNullOrWhiteSpace($Url)) { return $false }
  try {
    $u = [Uri]$Url
    if ($u.Scheme -ne [Uri]::UriSchemeHttps) { return $false }
    $h = $u.Host.ToLowerInvariant()
    if ($h -eq 'github.com') { return ($u.AbsolutePath -match '^/argenluna/maintenance/releases/download/') }
    if ($h -eq 'objects.githubusercontent.com') { return $true }
    return $false
  } catch { return $false }
}

function Write-VerifyReport {
  param([string]$Tag, [string]$Summary, [string]$Note)
  $bad = @($script:rows | Where-Object { -not $_.Ok })
  $out = New-Object System.Collections.ArrayList
  $null = $out.Add('[ 자동유지보수 미리검증 결과 ]')
  $null = $out.Add('')
  $null = $out.Add("대상: $Tag")
  $null = $out.Add("검사 시각: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
  $null = $out.Add("결과: $Summary")
  $null = $out.Add('')
  $null = $out.Add('[ 검사 항목 ]')
  foreach ($r in $script:rows) {
    $null = $out.Add(('  {0}  {1} - {2}' -f $(if ($r.Ok) { 'PASS' } else { 'FAIL' }), $r.Name, $r.Detail))
  }
  if ($bad.Count -gt 0) {
    $null = $out.Add('')
    $null = $out.Add('[ 문제가 발견된 부분 ]')
    foreach ($r in $bad) {
      $null = $out.Add("  · $($r.Name): $($r.Detail)")
    }
    $null = $out.Add('')
    $null = $out.Add('→ 위 항목을 확인하기 전에는 예약일 본배포를 진행하지 마세요.')
  }
  if ($Note) {
    $null = $out.Add('')
    $null = $out.Add($Note)
  }
  $null = $out.Add('')
  $null = $out.Add("상세 로그: $log")
  [IO.File]::WriteAllText($report, ($out -join "`r`n") + "`r`n", (New-Object System.Text.UTF8Encoding($true)))
  L "보고서 저장: $report"
}

L '미리검증 시작 (설치본은 변경하지 않습니다)'

# --- 1. RC 릴리스 찾기 (태그 vX.Y.Z-rcN 만) ---
$rels = @()
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $headers = @{ 'User-Agent' = 'AutoMaintenanceKit/1.8'; 'Accept' = 'application/vnd.github+json' }
  $res = Invoke-WebRequest -Uri $api -Headers $headers -UseBasicParsing -TimeoutSec 25
  $data = $res.Content | ConvertFrom-Json
  if ($null -eq $data) { $data = @() }
  # PS 5.1 ConvertFrom-Json 은 루트 배열을 열거하지 않고 넘긴다. 변수에 담은 뒤 @() 로 펼쳐야 한다.
  $rels = @($data)
} catch {
  Add-Row '릴리스 조회' $false ("GitHub 접속 실패: " + $_.Exception.Message)
  Write-VerifyReport -Tag '(조회 실패)' -Summary '확인 불가' -Note '인터넷 연결을 확인한 뒤 다시 실행하세요.'
  exit 1
}

$rcs = @()
foreach ($r in $rels) {
  $tag = [string]$r.tag_name
  if ($tag -match '^v?(\d+\.\d+\.\d+)-rc(\d+)$') {
    $rv = $null
    if ([version]::TryParse($Matches[1], [ref]$rv)) {
      $rcs += [pscustomobject]@{ Tag = $tag; Ver = $rv; Rc = [int]$Matches[2]; Rel = $r }
    }
  }
}
$rcs = @($rcs | Sort-Object Ver, Rc -Descending)
if ($rcs.Count -eq 0) {
  # 매일 실행되므로 RC 가 없을 때는 바탕화면 보고서를 덮어쓰지 않고 로그에만 남긴다.
  L '검사할 RC 가 없어 종료합니다 (대기 중 / 실패 아님). 예약 1주 전에 RC 가 올라오면 자동으로 검사합니다.'
  exit 0
}
$pick = $rcs[0]
L "대상 RC: $($pick.Tag)"

# --- 2. ZIP / 해시 자산 확인 ---
$zipUrl = $null; $hashUrl = $null
foreach ($a in @($pick.Rel.assets)) {
  $nm = [string]$a.name
  $url = [string]$a.browser_download_url
  if (-not (Test-TrustedUrl $url)) { continue }
  if ($nm -match '\.zip$' -and -not $zipUrl) { $zipUrl = $url }
  if ($nm -match '\.sha256$' -and -not $hashUrl) { $hashUrl = $url }
}
if (-not $zipUrl -or -not $hashUrl) {
  Add-Row '배포 자산' $false 'RC 릴리스에 ZIP 또는 .sha256 이 없습니다.'
  Write-VerifyReport -Tag $pick.Tag -Summary '문제 발견' -Note ''
  exit 1
}
Add-Row '배포 자산' $true 'ZIP + .sha256 확인'

$tmp = Join-Path $env:TEMP ('AutoMaintenance_PreVerify_' + $pick.Tag + '_' + (Get-Date -Format yyyyMMdd_HHmmss))
try {
  New-Item -ItemType Directory -Path $tmp -Force | Out-Null
  $zipPath = Join-Path $tmp 'rc.zip'
  Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 180 | Out-Null
  $hashPath = Join-Path $tmp 'rc.sha256'
  Invoke-WebRequest -Uri $hashUrl -OutFile $hashPath -UseBasicParsing -TimeoutSec 60 | Out-Null
  $expected = @((Get-Content -LiteralPath $hashPath -Raw) -split '\s+' | Where-Object { $_ -match '^[0-9a-fA-F]{64}$' } | Select-Object -First 1)
  $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($expected.Count -eq 0 -or $actual -ne ([string]$expected[0]).ToLowerInvariant()) {
    Add-Row '해시 검증' $false "SHA256 불일치 (기대: $(if($expected.Count){$expected[0]}else{'없음'}))"
    Write-VerifyReport -Tag $pick.Tag -Summary '문제 발견' -Note ''
    exit 1
  }
  Add-Row '해시 검증' $true 'SHA256 일치'

  # --- 3. Zip Slip 방어 후 canary 폴더에 펼치기 ---
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $extractDir = Join-Path $tmp 'extract'
  $arc = $null
  try {
    $arc = [IO.Compression.ZipFile]::OpenRead($zipPath)
    $base = [IO.Path]::GetFullPath($extractDir).TrimEnd([char[]]@('\','/')) + '\'
    foreach ($e in $arc.Entries) {
      $n = [string]$e.FullName
      if ([string]::IsNullOrWhiteSpace($n)) { continue }
      if ($n.StartsWith('\') -or $n.StartsWith('/') -or $n -match '^[A-Za-z]:') {
        Add-Row '압축 경로 안전' $false "절대경로 항목: $n"
        Write-VerifyReport -Tag $pick.Tag -Summary '문제 발견' -Note ''
        exit 1
      }
      $d = [IO.Path]::GetFullPath((Join-Path $extractDir $n))
      if (-not $d.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) {
        Add-Row '압축 경로 안전' $false "추출 폴더 이탈: $n"
        Write-VerifyReport -Tag $pick.Tag -Summary '문제 발견' -Note ''
        exit 1
      }
    }
  } finally { if ($null -ne $arc) { $arc.Dispose() } }
  Add-Row '압축 경로 안전' $true '이탈 경로 없음'
  Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

  $newRoot = $extractDir
  if (-not (Test-Path -LiteralPath (Join-Path $newRoot 'install.ps1'))) {
    $sub = Get-ChildItem -LiteralPath $extractDir -Directory -ErrorAction SilentlyContinue |
      Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'install.ps1') } | Select-Object -First 1
    if ($null -eq $sub) {
      Add-Row '압축 구조' $false 'install.ps1 이 없습니다.'
      Write-VerifyReport -Tag $pick.Tag -Summary '문제 발견' -Note ''
      exit 1
    }
    $newRoot = $sub.FullName
  }

  # 같은 ZIP 이면 같은 폴더를 재사용(삭제하지 않음). 다른 ZIP 이면 새 폴더.
  $canary = Join-Path 'H:\' ('AutoMaintenance_Canary_' + $pick.Tag + '_' + $actual.Substring(0, 8))
  Copy-Item -LiteralPath $newRoot -Destination $canary -Recurse -Force
  L "Canary 폴더: $canary"

  # --- 4. 필수 파일 / VERSION / 구문 / BOM ---
  $required = @('install.ps1','install.cmd','run-maintenance.ps1','run-now.ps1','uninstall.ps1',
    'update.ps1','update-common.ps1','업데이트.ps1','feedback.ps1','config.json','VERSION',
    'README.md','readme.txt','newbie.txt','LICENSE','버전안내.ps1','UPDATE_SCHEDULE.md',
    (Join-Path 'Simple maintenance' 'maintenance.ps1'), (Join-Path 'Simple maintenance' 'config.json'))
  $missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $canary $_) -PathType Leaf) })
  Add-Row '필수 파일' ($missing.Count -eq 0) $(if ($missing.Count -eq 0) { "$($required.Count)개 모두 존재" } else { "누락: $($missing -join ', ')" })

  $vf = Join-Path $canary 'VERSION'
  $vline = if (Test-Path -LiteralPath $vf) { ([string](Get-Content -LiteralPath $vf -Raw -Encoding UTF8)).Trim().Split("`n")[0].Trim() } else { '' }
  Add-Row 'VERSION 일치' ($vline -eq [string]$pick.Ver) "VERSION=$vline / 태그=$($pick.Ver)"

  $scripts = @(Get-ChildItem -LiteralPath $canary -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.ps1','.psm1' })
  $parseBad = @()
  foreach ($f in $scripts) {
    $tk = $null; $pe = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$tk, [ref]$pe)
    if ($pe -and $pe.Count -gt 0) { $parseBad += ($f.FullName.Substring($canary.Length + 1) + ': ' + $pe[0].Message) }
  }
  Add-Row '스크립트 구문' ($parseBad.Count -eq 0) $(if ($parseBad.Count -eq 0) { "$($scripts.Count)개 정상" } else { $parseBad[0] })

  $noBom = @()
  foreach ($f in @($scripts | Where-Object { $_.Extension -eq '.ps1' })) {
    $b = [IO.File]::ReadAllBytes($f.FullName)
    if ($b.Length -lt 3 -or $b[0] -ne 0xEF -or $b[1] -ne 0xBB -or $b[2] -ne 0xBF) {
      $noBom += $f.FullName.Substring($canary.Length + 1)
    }
  }
  Add-Row 'UTF-8 BOM' ($noBom.Count -eq 0) $(if ($noBom.Count -eq 0) { '모든 .ps1 BOM 유지' } else { "BOM 누락: $($noBom -join ', ')" })

  # --- 5. 회귀 SelfTest (각각 별도 프로세스 — 서로 exit 하므로) ---
  $maint = Join-Path $canary (Join-Path 'Simple maintenance' 'maintenance.ps1')
  if (-not (Test-Path -LiteralPath $maint)) {
    Add-Row '회귀 SelfTest' $false 'maintenance.ps1 이 없습니다.'
  } else {
    foreach ($case in @(
        @{ Name='SelfTestExplain'; Flag='-SelfTestExplain'; Need='SelfTestExplain:'; Fail='fail=0' },
        @{ Name='SelfTestUpdateFail'; Flag='-SelfTestUpdateFail'; Need='SelfTestUpdateFail:'; Fail='fail=0' },
        @{ Name='SelfTestDrivers'; Flag='-SelfTestDrivers'; Need='SelfTestDrivers:'; Fail='fail=0' }
      )) {
      $o = ''
      $code = -1
      try {
        $o = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $maint $case.Flag 2>&1 | Out-String
        $code = $LASTEXITCODE
      } catch { $o = $_.Exception.Message }
      $ok = ($code -eq 0) -and ($o -match [regex]::Escape($case.Need))
      $tail = @($o -split "`r?`n" | Where-Object { $_ -match 'SelfTest|FAIL|^OK:' } | Select-Object -Last 2) -join ' | '
      Add-Row $case.Name $ok "exit=$code / $tail"
    }
  }
} catch {
  Add-Row '미리검증 진행' $false $_.Exception.Message
}

$bad = @($script:rows | Where-Object { -not $_.Ok })
if ($bad.Count -eq 0) {
  $summary = '문제 없음 — 예약일 본배포 진행 가능'
  $note = "이 검사는 설치본을 바꾸지 않습니다. 예약일 04:00 에 안정버전(v$($pick.Ver))이 공개되면 자동업데이트가 설치합니다."
  L "미리검증 통과: $($pick.Tag)"
  Write-VerifyReport -Tag $pick.Tag -Summary $summary -Note $note
  exit 0
} else {
  $summary = "문제 발견 — $($bad.Count)건 (본배포 보류)"
  L "미리검증 실패: $($bad.Count)건"
  Write-VerifyReport -Tag $pick.Tag -Summary $summary -Note '위 문제를 고친 RC 를 다시 올리면 다음 예약 검사에서 재검사합니다.'
  exit 1
}
