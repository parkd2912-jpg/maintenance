# -*- coding: utf-8 -*-
# ============================================================
#  Auto Maintenance - 버전 안내 (Ulanzi 버튼용)
#  바탕화면 "자동 유지보수 버전 안내" 바로가기가 실행하는 파일.
#  - Ulanzi 버튼 화면용 3줄 문구를 바탕화면에 저장한다
#      현재 vX.Y.Z / 다음 vX.Y.Z / 예약 N건
#  - 현재 버전 기능 → 다음 버전 추가·변경 기능을 요약해 메모장으로 연다
#  - 읽기 전용: 설치본·예약 작업·설정은 절대 바꾸지 않는다
# ============================================================
param([switch]$NoOpen, [switch]$NoWriteButtonFile)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$desktop = [Environment]::GetFolderPath('Desktop')

function L([string]$ko, [string]$en) {
  try {
    if ([Globalization.CultureInfo]::CurrentUICulture.Name -like 'ko*') { return $ko }
    if ([Globalization.CultureInfo]::CurrentCulture.Name -like 'ko*') { return $ko }
  } catch { }
  return $en
}

# --- 현재 버전 (VERSION 파일이 유일 기준) ---
function Get-CurrentVersion {
  $vf = Join-Path $root 'VERSION'
  $lines = @(Get-Content -LiteralPath $vf -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  $v = ([string]$lines[0]).Trim()
  $d = if ($lines.Count -ge 2) { ([string]$lines[1]).Trim() } else { '' }
  return [pscustomobject]@{ Ver = $v; Date = $d }
}

# --- 예약 슬롯 (UPDATE_SCHEDULE.md 의 W1~W4 / M1 행) ---
function Get-ScheduleRows {
  $p = Join-Path $root 'UPDATE_SCHEDULE.md'
  $rows = New-Object System.Collections.ArrayList
  if (-not (Test-Path -LiteralPath $p)) { return @($rows) }
  foreach ($line in (Get-Content -LiteralPath $p -Encoding UTF8)) {
    if ($line -match '^\|\s*(W\d+|M1)\s*\|') {
      $cells = @($line -split '\|' | ForEach-Object { $_.Trim() })
      if ($cells.Count -ge 5) {
        $parsed = $null
        $raw = [string]$cells[3]
        $candidate = $raw -replace '^v', ''
        if ($candidate -match '^\d+\.\d+\.\d+$') { [void][version]::TryParse($candidate, [ref]$parsed) }
        [void]$rows.Add([pscustomobject]@{
          Slot = $cells[1]; Date = $cells[2]; Ver = $raw; Parsed = $parsed
          Desc = $cells[4]; Status = $(if ($cells.Count -ge 6) { $cells[5] } else { '' })
        })
      }
    }
  }
  return @($rows)
}

# --- 설명 문구를 메모장용 불릿으로 정리 ---
function Format-Description {
  param([string]$Text)
  $t = [string]$Text
  $t = $t -replace '\*\*|__|`', ''
  $t = $t -replace '^\s*우선처리\s*:\s*', ''
  $t = [regex]::Replace($t, '\s+', ' ').Trim()
  # ' · ' 기준으로만 나눈다. ' — ' 는 괄호 안 설명에서 쓰이므로 불릿 경계로 쓰지 않는다.
  $parts = @($t -split '\s+·\s+')
  $lines = New-Object System.Collections.ArrayList
  foreach ($p in $parts) {
    $p = ([string]$p).Trim()
    if ($p.Length -lt 2) { continue }
    while ($p.Length -gt 88) {
      $cut = $p.LastIndexOf(' ', 88)
      if ($cut -lt 40) { $cut = 88 }
      [void]$lines.Add('  · ' + $p.Substring(0, $cut).Trim())
      $p = $p.Substring($cut).Trim()
    }
    if ($p.Length -gt 0) { [void]$lines.Add('  · ' + $p) }
  }
  if ($lines.Count -eq 0) { [void]$lines.Add('  · ' + (L '설명 없음' 'no description')) }
  return @($lines)
}

# --- 현재 버전 기능: README 버전 표에서 해당 행을 읽는다 ---
function Get-CurrentFeatureLines {
  param([string]$Version)
  $p = Join-Path $root 'README.md'
  if (-not (Test-Path -LiteralPath $p)) { return @('  · ' + (L '설명 없음' 'no description')) }
  foreach ($line in (Get-Content -LiteralPath $p -Encoding UTF8)) {
    if ($line -match ('^\|\s*' + [regex]::Escape($Version) + '\s*\|')) {
      $cells = @($line -split '\|' | ForEach-Object { $_.Trim() })
      if ($cells.Count -ge 4) { return @(Format-Description -Text $cells[3]) }
    }
  }
  return @('  · ' + (L '버전 표에 설명 없음' 'no entry in version table'))
}

$cur = Get-CurrentVersion
$curV = $null
[void][version]::TryParse($cur.Ver, [ref]$curV)
$sched = @(Get-ScheduleRows)
$cands = @($sched | Where-Object {
    $null -ne $_.Parsed -and $null -ne $curV -and $_.Parsed -gt $curV
  } | Sort-Object Parsed)
$next = if ($cands.Count -gt 0) { $cands[0] } else { $null }
$nextVer = if ($null -ne $next) { ($next.Ver -replace '^v', '') } else { (L '없음' 'none') }
$count = $sched.Count

# --- Ulanzi 버튼 화면용 3줄 ---
$btn = (L '현재' 'Current') + ' v' + $cur.Ver + "`n" +
       (L '다음' 'Next') + ' v' + $nextVer + "`n" +
       (L '예약' 'Scheduled') + ' ' + $count + (L '건' ' items')
$btnPath = Join-Path $desktop '자동유지보수_버튼화면.txt'
if (-not $NoWriteButtonFile) {
  [IO.File]::WriteAllText($btnPath, $btn, (New-Object System.Text.UTF8Encoding($false)))
}

# --- 메모장 본문 ---
$m = New-Object System.Collections.ArrayList
[void]$m.Add('==========================================')
[void]$m.Add('  ' + (L '자동 유지보수 - 버전 안내' 'Auto Maintenance - Version Guide'))
[void]$m.Add('==========================================')
[void]$m.Add((L '생성 시각' 'Created') + ': ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
[void]$m.Add('')
[void]$m.Add('[ ' + (L '버튼 화면에 표시할 3줄' '3 lines for the button display') + ' ]')
foreach ($ln in ($btn -split "`n")) { [void]$m.Add('  ' + $ln) }
[void]$m.Add('')
[void]$m.Add('[ ' + (L '현재 버전' 'Current version') + ' v' + $cur.Ver + ' ' + $cur.Date + ' ]')
foreach ($ln in @(Get-CurrentFeatureLines -Version $cur.Ver)) { [void]$m.Add($ln) }
[void]$m.Add('')
if ($null -ne $next) {
  [void]$m.Add('[ ' + (L '다음 버전' 'Next version') + ' ' + $next.Ver + ' ' + $next.Date + ' — ' + (L '추가·변경 기능' 'added / changed') + ' ]')
  foreach ($ln in @(Format-Description -Text $next.Desc)) { [void]$m.Add($ln) }
} else {
  [void]$m.Add('[ ' + (L '다음 버전' 'Next version') + ' ]')
  [void]$m.Add('  · ' + (L '예약된 다음 버전이 없습니다' 'no scheduled next version'))
}
[void]$m.Add('')
[void]$m.Add('[ ' + (L '예약 일정' 'Schedule') + ' - ' + $count + (L '건' ' items') + ' ]')
foreach ($r in $sched) {
  $d = [string]$r.Desc
  $d = $d -replace '\*\*|__|`', ''
  $d = [regex]::Replace($d, '\s+', ' ').Trim()
  if ($d.Length -gt 104) { $d = $d.Substring(0, 102) + '…' }
  [void]$m.Add('  ' + $r.Slot.PadRight(3) + ' ' + $r.Date.PadRight(12) + ' ' + $r.Ver.PadRight(10) + ' ' + $d)
}
[void]$m.Add('')
[void]$m.Add((L '설치본은 그대로입니다. 버튼 화면용 3줄 파일' 'Installed kit is unchanged. Button display text file') + ': ' + $btnPath)

$memoPath = Join-Path $desktop '자동유지보수_버전안내.txt'
[IO.File]::WriteAllText($memoPath, ($m -join "`r`n"), (New-Object System.Text.UTF8Encoding($true)))
if (-not $NoOpen) {
  try {
    Start-Process -FilePath "$env:SystemRoot\System32\notepad.exe" -ArgumentList ('"' + $memoPath + '"') | Out-Null
  } catch {
    Write-Host ((L '메모장을 열지 못했습니다' 'Could not open Notepad') + ': ' + $memoPath)
  }
}
Write-Host ($m -join "`n")
