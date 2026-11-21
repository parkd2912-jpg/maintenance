# Maintenance (Windows / PowerShell)

자동 유지보수 키트 (윈도우용) — 시스템을 6일에 한 번 스스로 점검하고, 안전한 범위에서 자동 수리합니다. 🪟🔧✨
Auto Maintenance Kit for Windows — checks itself every 6 days and auto-repairs within safe limits.
自動メンテナンスキット（Windows 用）— 6日ごとに自動点検し、安全な範囲で自動修復します。
自动维护工具（Windows 用）— 每 6 天自动检查一次，并在安全范围内自动修复。

> **면책 / DISCLAIMER / 免責事項 / 免责声明**
> 한국어: 개인용 비공식 도구이며 Microsoft·제조사와 무관합니다. 서비스/예약작업/레지스트리/hosts/광고설정을 변경해 백신이 반응할 수 있으나 악성코드가 아닙니다. 사용자 파일은 절대 자동 삭제하지 않습니다. 임시·캐시·휴지통은 기본적으로 `y` 확인 후에만 정리하며, `A`를 누르면 **그 항목만** 이후 자동 정리합니다(v1.14.0). 광고 차단은 선택 사항이며 제거 스크립트로 되돌릴 수 있습니다. **제공은 "있는 그대로(As-Is)"이며 사용 결과에 대한 책임은 사용자에게 있습니다.**
> English: Unofficial personal tool, not affiliated with Microsoft or any vendor. It changes services/tasks/registry/hosts/ad settings, so antivirus may flag it — it is not malware. It never auto-deletes user files; temp/cache/recycle-bin cleanup requires `y` by default. Pressing `A` opts only that category into automatic cleanup afterwards (v1.14.0). Ad blocking is opt-in and reversible. **Provided AS IS; use at your own risk.**
> 日本語: 非公式の個人用ツールで、Microsoft や各メーカーとは無関係です。サービス・タスク・レジストリ・hosts・広告設定を変更するためウイルス対策ソフトが反応する場合がありますが、マルウェアではありません。ユーザーファイルは自動削除せず、一時/キャッシュ/ごみ箱も基本は `y` の確認後のみ削除します。`A` を押すとその項目だけ今後自動削除します(v1.14.0)。**現状のまま(AS IS)で提供し、使用結果は自己責任です。**
> 中文: 非官方个人工具，与 Microsoft 及各厂商无关。会修改服务/任务/注册表/hosts/广告设置，杀毒软件可能报警，但并非恶意软件。绝不自动删除用户文件，临时/缓存/回收站默认需按 `y` 确认后才清理；按 `A` 后仅该项以后自动清理(v1.14.0)。**按"原样(AS IS)"提供，使用风险自负。**

시스템 유지보수 자동화. 스케줄 태스크 → wrapper(주기 게이트) → 실제 점검 스크립트 순서로 실행된다.

```
install.ps1 (1회)  → 예약 작업 등록 + 바탕화면 바로가기
OpenCode-Maintenance (예약: 매일 04:00 + 로그온 5분 후)
  └─ run-maintenance.ps1      주기(cadence) 확인, status.json 갱신
       └─ Simple maintenance\maintenance.ps1 -Mode scheduled   실제 점검/자동 수리

run-now.ps1 (바탕화면 "자동 유지보수 점검" / "auto-maintenance")  → run-maintenance.ps1 -Force → 즉시 점검 + 리포트
uninstall.ps1 (바탕화면 "자동 유지보수 제거" / "remove maintenance") → 예약 작업/바로가기 제거
```

> **시스템 언어 대응 (v1.6.0~v1.7.0)** — Windows 언어를 감지해 한국어면 한글 이름/한글 결과 txt,
> 그 외 언어면 영어 바로가기 이름/**영어 결과 txt**를 만듭니다. SelfTest·피드백 상태 파일·콘솔 메시지도 같은 언어를 따릅니다.
>
> | 용도 | 한국어 | 그 외 언어 (v1.7.0) |
> |---|---|---|
> | 점검 | `자동 유지보수 점검.lnk` | `auto-maintenance.lnk` |
> | 제거 | `자동 유지보수 제거.lnk` | `remove maintenance.lnk` |
> | 피드백 | `자동 유지보수 피드백.lnk` | `feedback maintenance.lnk` |
> | 버전 안내 (Ulanzi 버튼용) | `자동 유지보수 버전 안내.lnk` | `version guide.lnk` |
> | 결과 txt | `자동유지보수_yyyyMMdd_HHmm.txt` | `auto-maintenance_yyyyMMdd_HHmm.txt` |
> | 실패 txt | `자동유지보수_실패_*.txt` | `auto-maintenance_failed_*.txt` |
> | 결과 보관 폴더 | `자동점검결과` | `maintenance results` |
>
> 감지 순서: `CurrentUICulture` → `Get-WinUserLanguageList[0]` → `CurrentCulture` → `Get-WinSystemLocale`
> 중 하나라도 `ko-*`면 한국어, 아니면 영어. (PowerShell 5.1의 UI 문화권은 설치 언어 `en-US`일 수 있어
> 첫 값만 보지 않고 **모든 후보를 확인**합니다.) 언어를 바꾼 뒤 재설치하면 이전 언어 바로가기는 모두 정리됩니다.
> 영어 모드 결과 txt 는 요약·상세 로그 전체가 영어로 출력되며(한글 문구는 `L()`/치환 맵으로 변환),
> 이전 버전에서 만든 한글 결과 파일도 정리·피드백 대상에 그대로 포함됩니다.

## 빠른 시작 (컴맹용, 3단계)

1. **`install.cmd` 더블클릭** → 파란 확인 창에서 **"예"** → 첫 점검이 끝날 때까지 대기(약 1분).
   (`.ps1` 은 더블클릭하면 메모장으로 열리므로 `install.cmd` 를 쓰세요.)
> 컴퓨터를 전혀 모르는 분께는 **`newbie.txt`** 를 먼저 보여주세요. 40개 검사를 레고·집·주방 비유로 설명합니다.
2. 평소에는 **아무것도 하지 않아도 됩니다.** PC가 켜져 있으면 6일에 한 번 자동으로 점검합니다
   (매일 04:00 + 로그온 5분 후에 "할 차례인지" 확인만 하고, 실제 실행은 6일 주기).
3. 결과는 바탕화면 `자동유지보수_날짜시간.txt`(영어권: `auto-maintenance_날짜시간.txt`) — **맨 위 3줄만** 보면 됩니다.
   - 즉시 점검하고 싶을 때: 바탕화면 **자동 유지보수 점검**(영어권: `auto-maintenance`) 더블클릭
   - 자동 점검을 끄고 싶을 때: 바탕화면 **자동 유지보수 제거**(영어권: `remove maintenance`) 더블클릭 (로그·설정은 보존)

`install.ps1` 이 하는 일: 관리자 권한 요청 → 파일/문법 검사 → 예약 작업 `OpenCode-Maintenance` 등록 →
바탕화면 바로가기 2개 생성 → 첫 점검 실행 + 결과 파일 열기.

예약 작업은 **현재 로그온한 사용자** 권한(관리자)으로 실행된다(시스템 복원 지점 생성·바탕화면 리포트 때문에).
그래서 그 사용자가 로그온했을 때만 돌고, 04:00 에 PC가 꺼져 있었으면 다음 로그온/부팅 후에 실행된다
(`StartWhenAvailable`).

## 설치 폴더와 업데이트 안전 수칙 (v1.12.0)

예약 작업이 **관리자 최고 권한(`-RunLevel Highest`)** 으로 이 폴더의 스크립트를 실행하므로, 폴더 자체를 아무나 쓸 수 있는 곳에 두면 안 됩니다.

- **압축 파일 안에서 실행하지 말고, 반드시 전용 폴더에 완전히 풀어서** `install.cmd` 를 실행하세요.
  (예: `H:\AutoMaintenance_v1.12.0` 처럼 이 키트만 쓰는 폴더. 공용 폴더·공유 드라이브·`C:\` 루트는 피하세요.)
  (다른 사용자 계정이나 외부 프로그램이 이 폴더의 `.ps1`/`.json` 파일에 **쓰기 권한을 갖지 않도록 개인 경로를 사용하세요.**)
- **신뢰할 수 있는 출처에서만 받으세요.** 공식 릴리즈는 <https://github.com/argenluna/maintenance/releases> 뿐입니다.
  다른 사이트/메일 첨부로 받은 ZIP 은 설치하지 마세요.
  압축을 푼 뒤 Windows 보안 경고나 파일의 "차단" 표시가 뜨면, 출처가 위 주소임을 확인한 뒤 **차단 해제**하세요.
  (Defender 경고가 뜨면 "위험한 파일을 다운로드했을 수 있습니다" 안내에서 출처를 확인하고, 알 수 없는 경로면 실행하지 마세요.)
- 자동 업데이트는 **`.sha256` 해시 파일이 반드시 있는 릴리즈만** 설치합니다.
  해시가 없거나 다르면 설치 전에 중단합니다. 다운로드는 HTTPS + GitHub 릴리즈 호스트만 허용하고,
  **302 리다이렉트 후의 최종 URL도 같은 호스트로 검증**합니다.
  압축을 풀기 전에 `..`/절대경로 엔트리(Zip Slip)를 검사하고, 푼 뒤에는 설치 폴더의 **모든 `.ps1`/`.psm1` 구문 검사**를 통과해야 `install.ps1` 을 실행합니다.
- 관리자 재실행·예약 작업·바로가기는 스크립트 자기 경로(`$PSCommandPath`/`$PSScriptRoot`)만 사용하고
  인자를 하나하나 이스케이프해서 넘깁니다. 경로에 공백이나 특수문자가 있어도 안전합니다.
  `chkdsk /f` 예약도 같은 인자 조인(`Join-CliArgs`)을 거치므로 문자열을 직접 이어 붙이지 않습니다.
- 모든 파일 조회는 `-LiteralPath` 를 씁니다. 설치 폴더나 결과 경로에 대괄호(`[`, `]`)가 있어도
  와일드카드로 오해하지 않고 그대로 찾습니다.
- `chkdsk` 는 드라이브(`^[A-Za-z]:$`)와 스위치(`/scan`,`/spotfix`,`/f`)를 화이트리스트로 제한한 뒤 호출합니다.
- `install.cmd` 런처도 패키지 필수 파일로 확인합니다. 런처 내용 무결성은 릴리즈 ZIP 전체의 `.sha256` 으로 검증됩니다.
- PSGallery 에서 가져오는 `PSWindowsUpdate` 모듈은 **게시자 서명 검증을 유지**합니다(`-SkipPublisherCheck` 미사용).
- **`config.json` 검증**: `tempDirs` 는 드라이브 루트/사용자 데이터 폴더를 거부하고, `adDnsServers` 는 각 옥텟이 0~255인 IPv4 만 받습니다.
  타입이 잘못된 값은 안전한 기본값으로 되돌립니다.

### 개발자용 검증

인자 이스케이프 헬퍼(`ConvertTo-CliArg`/`Join-CliArgs`)는 진입점마다 복사해 두어,
한 곳만 수정하면 예약 작업·바로가기·업데이트의 인자가 서로 달라질 수 있습니다.
사본이 모두 같은지 아래로 확인하세요 (줄바꿈 차이는 무시합니다).

```
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tests\verify-helper-parity.ps1
```

### 구버전 폴더(롤백) 관리 기준

업데이트는 **새 폴더를 옆에 만들고 기존 폴더는 지우지 않고 남깁니다** (문제 생기면 옛 폴더로 돌아갈 수 있게).

- 예약 작업과 바탕화면 바로가기는 **항상 최신 폴더만** 가리킵니다. 설치 시 이전 버전의 바로가기 이름은 정리됩니다.
- 남아 있는 구버전 폴더에는 자동 점검이 등록되어 있지 않습니다. 폴더 안의 스크립트를 **직접 더블클릭하지 마세요.**
  새 버전이 며칠간 정상이면 구버전 폴더는 직접 지워도 됩니다 (설정·로그는 새 폴더로 이미 이어받았습니다).

> 참고: 초보자도 그냥 더블클릭할 수 있게 `-ExecutionPolicy Bypass` 는 유지합니다.
> 대신 위의 **전용 폴더 + 공식 릴리즈 + 해시/경로/구문 검증**으로 실행 파일 변조 위험을 막습니다.

## "지금 점검" 창이 사라지거나 결과 메모장이 안 생길 때 (2026-11-14 수정)

다른 PC에서 **"점검을 누르면 잠깐 진행되다가 창이 꺼지고 바탕화면에 결과 메모장이 안 생긴다"** 는
증상이 있었다. 원인은 두 가지였고, 둘 다 고쳤다.

| 원인 | 증상 | 수정 |
|------|------|------|
| `maintenance.ps1` 이 scheduled 모드에서 **콘솔 창을 숨겼다**(자동 실행용). `run-now.ps1` 은 같은 콘솔에서 자식을 띄우므로 **사용자 창까지 사라졌다** | "잠깐 되다가 프로그램이 꺼진 것처럼" 보임 | 수동 실행은 `-NoHideConsole` 로 창을 유지한다(`-PromptForDelete` 도 동일). 자동/예약 실행만 숨긴다 |
| `[Environment]::GetFolderPath('Desktop')` 은 **관리자 계정의 바탕화면**을 돌려준다. 표준 사용자 + UAC 승격이면 결과가 관리자 계정 바탕화면에 생겨 **사용자는 못 본다** | "결과 메모장이 안 생긴다" | `run-now.ps1`/`install.ps1` 이 **사용자 바탕화면 경로를 `-ReportTo` 로 넘긴다**. 결과 txt 는 항상 그 경로에 쓴다 |

추가로, **어떤 이유로든 점검이 끝나지 않아도 파일을 남긴다.**

| 상황 | 남는 파일 (사용자 바탕화면) |
|------|------------------------------|
| 정상 완료 | `자동유지보수_yyyyMMdd_HHmm.txt` (영어권 `auto-maintenance_yyyyMMdd_HHmm.txt`) (+ `Simple maintenance\logs\last-report.txt` 사본) |
| 실행 중 치명적 오류 | `자동유지보수_실패_yyyyMMdd_HHmm.txt` (영어권 `auto-maintenance_failed_yyyyMMdd_HHmm.txt`) — 오류 메시지·위치·로그 경로. `maintenance.ps1` 의 `trap` |
| 결과 파일조차 못 남김(스크립트 파싱 실패, 백신 차단, 중복 실행으로 즉시 종료) | `자동유지보수_안내_yyyyMMdd_HHmm.txt` — 가능한 원인 3가지 + 로그 경로. wrapper 가 생성 |
| 위 두 경우 | 콘솔에도 "이번에는 점검이 완료되지 않았습니다" + 로그 경로를 보여주고 **지난 결과를 정상인 것처럼 보여주지 않는다** |

> 확인 위치: 바탕화면 `자동유지보수_*.txt`, 로그는 `logs\runner-YYYY-MM.log`(wrapper) 와
> `Simple maintenance\logs\maintain-YYYY-MM-DD.log`(본체). 결과 txt 가 없으면 이 두 로그를 보내면 원인을 알 수 있다.

## 버전 (현재 **v1.16.0**, 2026-11-21)

수정할 때마다 버전을 올린다. **`VERSION` 파일(킷 루트)이 유일한 기준**이고, 각 스크립트가 이 파일을 읽어
콘솔·결과 txt·로그에 찍는다. "친구 PC에서 어느 버전이 돌았는지"를 파일만 보고 확인할 수 있다.

```
VERSION 파일 (2줄)
  1.16.0
  2026-11-21
```

| 확인 위치 | 표시 예 |
|--------|---------|
| "지금 점검" 콘솔 | `자동 유지보수 점검 (지금 실행)` / `v1.16.0 (2026-11-21)` |
| 결과 txt | `실행: 2026-11-21 12:30` 아래 `버전: v1.16.0 (2026-11-21)` (영어권 `Run:` / `Version:`) |
| 실패/안내 txt | `버전: v1.16.0 (2026-11-21)` |
| 로그 | `maintain-*.log` → `VERSION: v1.16.0 (2026-11-21)`, `runner-*.log` → `Kit version: …` |
| JSON | `status.json`, `Simple maintenance\last-result.json` 의 `version` |
| 설치 폴더 | `VERSION` 파일 |

**올리는 규칙** (같은 날 여러 번 고쳐도 매번 올린다)

| 변경 종류 | 예 | 버전 |
|-----------|----|------|
| 오류 수정·문구 수정 | 창 숨김 버그, 경로 수정 | `1.1.0` → `1.1.1` |
| 기능 추가·동작 변경 | 새 검사 항목, 삭제 확인 방식 변경 | `1.1.x` → `1.2.0` |
| 구조 변경 | 파일 구성/설정 키 변경(재설치 필요) | `1.x.y` → `2.0.0` |

**ZIP 이름도 버전을 포함한다** — `dist\AutoMaintenance_v1.7.0_20261118.zip`
(예전 `AutoMaintenance_20261111.zip` 처럼 날짜만 쓰면, 내용만 바뀌었을 때 최신인지 구분할 수 없다.)

| 버전 | 날짜 | 내용 |
|------|------|------|
| 1.0.0 | 2026-11-11 | 첫 배포본(친구 PC에 전달된 ZIP). 광고 끄기·삭제 전 확인 포함 |
| 1.1.0 | 2026-11-14 | "지금 점검" 창이 사라지던 문제(콘솔 숨김), 관리자 계정 바탕화면 문제(`-ReportTo`), 중단 시 실패/안내 파일 — §12.14 |
| 1.1.1 | 2026-11-15 | 재부팅 판정 통일(`REBOOT`/`Updates` 모순), CHKDSK 복구 성공을 리포트에 표시, 차단 의심 드라이버·chkdsk 실제 출력·크래시 오류 모듈을 리포트에 기재 — §12.16 |
| 1.1.2 | 2026-11-16 | SFC 결과가 리포트에 아예 없던 버그(기호 로그 → PASS/WARN/FAIL), SFC 복구 성공 시 실패 사유 제거, AdQuiet 보호 작업 WARN → SKIP, 10분 이상 실행 시 "가장 오래 걸린 단계" 표시 — §12.17 |
| 1.1.3 | 2026-11-16 | 반복 크래시 앱을 제품명으로 해석(NGS·Vanguard·ACE·XignCode·EAC·BattlEye), 안티치트 드라이버를 차단 의심 목록에 추가, "드라이버 제거" 대신 게임 종료 → 재부팅 직후 → 안전 모드 순서 안내 — §12.18 |
| 1.2.0 | 2026-11-16 | **삭제 확인을 한 번만** — 시작할 때 `y`(모두 지움) / `n`(모두 그대로) / `s`(항목마다) 를 한 번 묻고 그 결정을 4개 삭제 단계에 그대로 적용. 이전에는 최대 4번 물었다 — §12.19 |
| 1.3.0 | 2026-11-17 | **바탕화면 결과 파일 자동 정리**(4개 이상이면 `자동점검결과` 폴더로 이동, 지우지 않음), **자동 실행 콘솔 표시 분기**(유휴 = 창 보임 / 사용 중 = 헤드리스, 직접 실행은 항상 보임), 첫 실행 로그 유실 버그(`logs` 폴더 조기 생성) — §12.20 |
| 1.3.1 | 2026-11-17 | `logs` 가 **파일**로 남은 옛 설치본에서 로그가 계속 유실되던 문제 — 그 파일을 `logs-legacy-<시각>.txt` 로 이름만 바꿔 보존하고 폴더를 만든다(이 PC 실측) — §12.21 |
| 1.4.0 | 2026-11-17 | **결과 파일 정리 방식 변경** — 4개 이상이면 최신 것까지 **전부** `자동점검결과` 폴더로 이동(바탕화면에는 이번 결과 1개만), 안내를 결과 txt·콘솔 양쪽에 표시. **3개월(90일) 지난 결과 파일 자동 삭제**(`resultRetentionDays`, 묻지 않음, 이 키트가 만든 결과 txt만) — §12.22 |
| 1.5.0 | 2026-11-18 | **피드백 GitHub 자동 업로드** — 동의(y)/비동의(n·Enter) 선택, 동의 시 GraphQL `createDiscussion` 로 업로드 후 로컬 파일 삭제. **개인정보 마스킹 + 악성/이상 코드 검증**(`<BLOCKED>` 치환, 15/15 SelfTest). 실행 결과를 바탕화면 `자동유지보수_피드백상태.txt` 에 기록. REST 404 문제를 GraphQL로 해결 |
| 1.6.0 | 2026-11-18 | **시스템 언어 대응** — 한국어가 아니면 바탕화면 바로가기를 `maintenance` / `maintenance remove` / `maintenance feedback` 로 생성. SelfTest(테스트 결과)·피드백 상태 파일·콘솔·차단 패턴 이름까지 `L(한/영)` 헬퍼로 언어 추종. PowerShell 5.1 UI 문화권이 `en-US`여도 사용자 언어 목록·시스템 로캘을 확인해 한글을 놓치지 않음. 언어 전환 재설치 시 이전 바로가기 양쪽 세트 정리 |
| 1.7.0 | 2026-11-18 | **영어권 이름/결과 txt 영어 출력** — 바로가기를 `auto-maintenance` / `remove maintenance` / `feedback maintenance` 로 변경(v1.6 이름도 제거 대상에 포함). 결과 txt 파일명·보관 폴더(`maintenance results`)·요약·상세 로그 전체를 영어로 출력(한글 문구 치환 맵, 실측 한글 0자). 실패 리포트 `auto-maintenance_failed_*.txt`, 정리/피드백 결과 파일 탐지에 영어 패턴 추가. 한국어 모드는 기존 동작 그대로 |
| 1.13.0 | 2026-11-19 | **오래된 드라이버 정리** — 같은 제조사·클래스·INF 의 새 버전이 이미 설치됐는데 남은 이전 드라이버를 30일 주기로 감지, 목록은 보여주되 삭제는 직접 실행에서 `y` 확인 후에만 |
| 1.14.0 | 2026-11-20 | **삭제 확인에 A/Y/N 추가** — 단계마다 묻고 `A`=언제나 삭제(설정에 기억 → 이후 자동), `Y`=현재만 삭제, `N`=거부. `tempAutoDelete`·`browserCacheAutoDelete`·`recycleAutoDelete` 설정 키 추가 — §삭제 전 확인 |
| 1.14.1 | 2026-11-21 | **피드백 업로드 토큰 동봉** — 배포 ZIP 에 `feedback-token.txt`(Discussions 쓰기 전용 최소 권한)를 포함해 상대 PC 는 토큰 입력 없이 `y` 한 번으로 업로드. `feedback.ps1` 이 동봉 토큰을 읽어 사용 — §피드백 내보내기 |
| 1.14.2 | 2026-11-21 | **만료 없는 토큰으로 교체 + 예약 업데이트 보강** — 동봉 토큰 갱신. `업데이트.ps1` 이 `-NoPause` 예약 실행에서 메시지 상자 대신 상태 파일에 기록하고, "새 버전 없음"을 실패로 오인하지 않음. 1개월 후 자동 업데이트 예약 작업 추가 |
| 1.14.3 | 2026-11-21 | **점검 종료 화면에 피드백 안내 + A/Y/N 전송 선택** — 종료 직전 "바탕화면 피드백 바로가기 / 아래 선택으로 의견·점검 결과를 보내면 기능 개선·문제 수정에 도움" 안내. `A`=항상 자동(설정 저장), `Y`=이번만, `N`=보내지 않기(기본). 예약 실행은 묻지 않음 |
| 1.14.4 | 2026-11-21 | **피드백 마스킹 오탐 수정 + 안내 문구 명확화** — 드라이버 버전이 `<IP>`로, `Simple maintenance\` 가 `<DOMAIN>` 으로 뭉개지던 문제 수정(SelfTest 12+5). 종료 안내는 "A/Y/N은 보고서만, 의견은 피드백 파일 실행"으로 정리. 삭제 목록 제목도 "복구용" → "업로드 시 경로 생략"으로 수정 |
| 1.14.5 | 2026-11-21 | **보고서 PC 구분 + 상세 로그 접기** — Discussion 제목에 `(GPU 모델)`, 본문에 `[ 보낸 PC ]`(GUID 해시 앞 6자리 / CPU / GPU) 추가. GUID 원본은 공개 업로드하지 않음. 상세 로그는 `<details>` 로 접어 가독성 개선. SecureBoot 권고에 "누적 업데이트 후 재부팅 2회" 추가 |
| 1.14.6 | 2026-11-21 | **결과 설명 수준 한 번 선택 + 초보자용 결과표** — 첫 대화형 점검에서 "컴퓨터를 잘 아시나요? Y/N"을 한 번만 묻고 `config.json`의 `explainMode`에 고정. `N`이면 `newbie.txt`의 39개 비유를 실제 검사 결과에 연결한 `[ 초보자용 결과표 ]`와 쉽게 풀어 쓴 `[ 직접 확인할 부분 ]`을 화면·결과 txt에 출력. 예약 실행은 질문 없이 저장값 사용. 기술 로그·피드백 마스킹은 그대로 |
| 1.14.7 | 2026-11-21 | **보고서 자동 업로드 연결 + 안내 문구 + 뉴비 보고서 표기** — 바탕화면 "지금 점검"(`-PromptForDelete`)에서도 종료 시 A/Y/N 전송 선택이 뜨고, `A`를 한 번 누르면 `autoFeedback='always'` 저장 후 이후 질문 없이 자동 업로드. 진짜 예약 실행은 사람이 없으므로 묻지도 올리지도 않음. 종료 화면·시작 화면에 전송 안내 명확화. 초보자용 결과표가 든 보고서는 GitHub 본문 상단에도 안내 줄 추가. |
| 1.14.8 | 2026-11-21 | **`always`면 예약 실행도 자동 업로드 + 업로드 원본 버그 수정** — A를 한 번 누르면 `autoFeedback='always'`가 저장되고, 이후 **예약 실행(사람 없음)에서도 질문 없이 보고서가 자동 업로드**된다(질문은 사람이 있을 때만). `feedback.ps1`에 `-NoPause` 추가해 창 없는 예약 실행에서 Enter 대기로 멈추던 문제 해결. 피드백 원본 고를 때 `자동유지보수_업데이트상태.txt`를 점검 결과로 오인하던 버그 수정. |
| 1.15.0 | 2026-11-21 | **업데이트 실패 이력 읽기 + 오류 코드 해석(보고만)** — Microsoft 공식 오류 코드 표를 근거로, 최근 30일 `Microsoft-Windows-WindowsUpdateClient` 설치/다운로드 실패 이벤트(20/31)를 읽어 `0x80070002` 같은 숫자를 쉬운 말로 해석해 결과표·권고에 표시. **복구 명령(DISM/sfc)은 절대 실행하지 않고 읽기만 함.** 초보자용 결과표에 `[40] 업데이트 실패 메모` 항목 추가, `newbie.txt` 40개 설명 동기화, `-SelfTestUpdateFail` 회귀 검증 추가. |
| 1.15.1 | 2026-11-21 | **3단계 검증 배포 + 미리 해보기 채널** — 예약일 2주 전 로컬 설치 검증 → 1주 전 RC(`vX.Y.Z-rcN`) 공개·매일 미리검증 → 예약일 안정본 공개·자동업데이트. 안내창에 `[ 현 버전 다운로드 ]`(안정화된 기능 + 추가된 기능 n가지)와 아래 작은 **미리 해보기** 버튼(RC = "이런 기능이 준비 중", 문제 시 제작자 연락, 최소 로컬 검증 완료)을 표시. RC 는 예약 작업이 절대 설치하지 않고, 누르면 별도 canary 폴더 + 전용 바로가기만 만들어 현재 설치본을 건드리지 않음. `PreVerify.ps1`(ZIP 미포함)이 RC 의 파일/구문/BOM/VERSION/회귀 SelfTest 를 매일 검사해 바탕화면 `자동유지보수_미리검증결과.txt` 에 보고. |
| 1.15.2 | 2026-11-21 | **피드백 개인정보 범위·후속 수정 안내** — 피드백 파일·동의 질문·점검 종료 화면·`newbie.txt` 에 "오류 확인용으로 CPU 모델·GPU 모델만 올라가고 이름·경로·시리얼·IP 등은 자동 삭제(보고서 구분용 해시 6자리 포함)", "보내주신 문제는 대부분 다음 버전에서 수정" 문구 추가. |
| 1.16.0 | 2026-11-21 | **Ulanzi 버튼용 버전 안내** — 새 `버전안내.ps1` + 바탕화면 `자동 유지보수 버전 안내` 바로가기. 버튼 화면용 3줄(`현재 vX / 다음 vY / 예약 N건`)을 `자동유지보수_버튼화면.txt` 에 저장하고, 현재 버전 기능 → 다음 예약 버전의 추가·변경 기능·예약 일정을 `자동유지보수_버전안내.txt` 에 요약해 메모장으로 연다. 읽기 전용(설치본·예약작업 변경 없음). `UPDATE_SCHEDULE.md` 를 ZIP 에 포함. |

## 바탕화면 결과 파일 정리 + 자동 실행 콘솔 표시 (2026-11-17, v1.3.0 / v1.4.0)

### ① 결과 파일이 4개 이상이면 `자동점검결과` 폴더로 **전부** 옮긴다 (v1.4.0)

바탕화면에 `자동유지보수_*.txt` 가 쌓이면 바탕화면이 지저분해진다. 이제 **이번에 만들 파일까지 합쳐
4개 이상**이 되면,

1. 바탕화면에 `자동점검결과` 폴더를 만든다(이미 있으면 그대로 사용)
2. **기존 결과 파일 전부**(최신 것 포함)를 그 폴더로 **이동**한다
   → 바탕화면에는 **이번에 새로 만든 결과 1개만** 남는다
3. 옮긴 개수·폴더 경로·옮긴 파일 목록을 결과 txt 의 `[바탕화면 정리]` 절, 콘솔 출력, 로그(`REPORT: CHANGE`),
   `last-result.json`(`desktopReportMove`)에 남긴다

**지우지 않는다 — 이동만 한다.** 대신 **3개월(기본 90일)이 지난 결과 파일은 묻지 않고 자동 삭제**한다
(아래 ③). 검색 경로는 바탕화면 + `자동점검결과` 폴더 둘 다 본다.
`run-now.ps1`/`install.ps1` 은 최신 리포트를 찾을 때 두 위치를 함께 본다(폴더로 옮겨져도 결과 창이 열린다).

### ③ 3개월(90일) 지난 결과 파일은 자동 삭제한다 (v1.4.0)

- 대상은 **이 키트가 만든 결과 txt 만** — `자동유지보수_*.txt`, `MaintenanceReport_*.txt`, `auto-maintenance_*.txt`(v1.7.0).
  사용자가 만든 다른 파일·폴더는 절대 건드리지 않는다.
- 기준은 파일의 수정 날짜(마지막으로 쓴 시각)이며 `resultRetentionDays`(기본 **90일**)를 넘으면 지운다.
  `0` 이하로 두면 자동 삭제를 끈다.
- 지운 파일의 **전체 경로·크기·날짜**를 결과 txt `[오래된 결과 파일 자동 삭제]` 절, 로그, `last-result.json`
  (`resultCleanup`)에 남긴다(복구 확인용).
- v1.3.1 이전에는 "7일 이상 지난 결과 파일"을 **지우기 전 확인 목록**으로 물어봤다(기본 보류). v1.4.0 부터는
  그 목록을 없애고 3개월 자동 삭제로 바꿨다 — 삭제 확인 질문(`y/n/s`)의 4번째 항목이 사라져 **묻는 항목이 3개**가 된다.

### ② 자동 실행은 "유휴 = 창 보임 / 사용 중 = 헤드리스"

| 상황 | 콘솔 창 | 결과 파일 |
|------|---------|-----------|
| 직접 실행(바탕화면 "지금 점검", 설치 첫 점검) | **항상 보임** (사용자가 보던 창 그대로) | 생성 |
| 자동 실행 + 사용자가 자리를 비움(유휴) | **별도로 새 PowerShell 창이 하나 더 떠서** 진행 상황이 보임 (예약 작업 자신은 숨겨진 상태) | 생성 |
| 자동 실행 + 사용 중 | **창을 만들지 않음(헤드리스)** | 생성 (txt/json/로그) |

- "새 창"이란: 예약 작업(`OpenCode-Maintenance`)은 Windows 가 `-WindowStyle Hidden` 로 띄우므로 **창이 없고**,
  wrapper 가 유휴를 감지하면 `Start-Process powershell.exe`(기본값 = 새 콘솔 창)로 `maintenance.ps1` 을
  **한 번 더** 실행한다. 그 **두 번째 프로세스의 검은 창**이 보이는 것이다. 이미 떠 있던 내 창이 갑자기
  바뀌는 것도, 예약 작업 창이/drag 돼서 나타나는 것도 아니다. 끝나면 그 창도 저절로 닫힌다.
- 유휴 판정: `idleConsoleMinutes`(기본 **5분**) 이상 마우스/키보드 입력이 없으면 유휴.
  `0` = 항상 창 보이게, `N` = N분 이상 유휴면 보이게.
- 헤드리스 실행은 `CreateNoWindow` 로 **콘솔 창을 아예 만들지 않는다**(창 핸들 0).
  이전 `-NoNewWindow` 방식은 부모가 숨김이어도 자식 콘솔 창이 생겨(실측 `visible=True`) 화면에 잠깐 깜빡였다.
- 헤드리스일 때 표준출력/표준에러는 `logs\console-yyyy-MM.log` 에 남는다(문제 추적용).
- 판정은 `run-maintenance.ps1` 한 곳에서만 하고, `maintenance.ps1` 에는 `-NoHideConsole`/`-HideConsole` 로
  결과만 전달한다(양쪽에서 따로 판정해 창이 사라지던 2026-11-14 사고의 재발 방지).
- `-Mode idle` 로 직접 실행하는 옛 방식도 같은 규칙을 따른다(유휴면 창 보임).

## 이 키트가 보장하는 것 / 못 하는 것

**자동으로 하는 것 (검사 + 안전한 수리)**
- 서비스·방화벽·VSS·WinRE·WMI·Defender 보호 상태 확인 후 **자동 복구**
- 임시파일·브라우저 캐시·휴지통·pip/conda 캐시 정리, 디스크 부족 시 정리
  (**파일을 지울 때는 목록을 먼저 보여주고 단계마다 A/Y/N 을 묻는다** → 아래 "삭제 전 확인")
- 시간 동기화(`w32tm /resync`), 볼륨 최적화는 Windows `ScheduledDefrag` 에 위임·상태 확인
- 시스템 복원 활성화 + 24시간 내 복원 지점 없으면 생성
- 이벤트 기반 반복 고장 자동 치유(스풀러/검색/방화벽/TPM 등), 유령 장치·드라이버 저장소 용량 확인
- **오래된 드라이버 감지** — 새 버전이 이미 설치됐는데 남은 이전 드라이버를 목록으로 보여주고, 직접 실행에서 `y` 를 누르면 삭제 (v1.13.0, 아래 "오래된 드라이버 정리" 참고)
- 디스크 SMART/SSD wear, BSOD 덤프, WHEA 하드웨어 오류, 부팅 시간 추세
- 보안 부팅/TPM/UEFI CA 2023, 인증서 만료, Windows 정품 인증, 예약 작업 생존, CRITICAL 서비스
- Windows **광고/추천 스위치 끄기**(HKCU, 가역) — hosts/DNS 광고 차단은 기본 꺼짐(opt-in)

**자동으로 하지 않는 것 (권고만)**
- **파일 백업/복구** — 사진·문서는 별도 백업 필요. 이 키트는 백업 도구가 아니다
- 맬웨어 **치료** — Defender 정의·보호 상태만 확인하고, 전체 검사는 Windows 가 자체 스케줄로 수행
- 하드웨어 "곧 고장" 단정 — SMART 수치는 보지만 교체 시점 판정은 아님
- 드라이버/BIOS/펌웨어 **업데이트(설치)**, Windows 기능 업데이트 설치(`autoInstallUpdates` 기본 꺼짐) — 오래된 드라이버 "감지·삭제"는 위에서 `y` 확인 후에만 함
- 드라이버를 **인터넷에서 최신version인지 조회/자동 설치** — 오직 로컬 드라이버 저장소에 이미 설치된 버전끼리만 비교한다
- 프로그램 충돌 원인 수정, 계정/암호 정책, 랜섬웨어 피해 복구, 하드웨어 교체
- **광고 앱 삭제/코드 패치** — 스위치·hosts·DNS 로만 줄인다. 앱 안에 내장된 광고는 막지 못한다

> 결론: **"이 검사만 하면 모든 게 완벽"은 아니다.** 이 키트는 *돌보기(정기 점검·청소·복구)* 자동화이고,
> 백업·백신·하드웨어 수리는 대체하지 않는다. 대신 "컴맹이 방치해서 생기는 고장"의 대부분을 잡는다.



## 실행 주기: 144시간 (6일)

`maintenanceCadenceHours = 144` (config.json 2곳 모두 동일해야 함)
- `maintenance\config.json` … wrapper가 읽는 설정
- `maintenance\Simple maintenance\config.json` … 실제 스크립트가 읽는 설정

근거 (2026-10-30 ~ 11-05, 7회 실행 실측):
1. **비용**: 벽시계 기준 1회 평균 **약 24분**(1,442초, 16~33분). 계측 합계는 426초뿐이었고
   **61~77%(평균 70%)는 계측되지 않았다**(마지막 Auto-Heal 단계 시간 누락 — 수정 후 벽시계와 일치).
   개편 후 일반 실행은 **1.6~2.1분**, 30일 무거운 검사가 포함된 실행은 **6분**.
2. **디스크**: 여유 공간이 로그 전 구간에서 **1,124~1,137GB로 거의 일정**(C: 1,862GB 중). 디스크는 주기를 제한하지 않는다.
3. **검출 창**: 이벤트 조회가 **최근 7일** → 주기가 7일을 넘으면 그 사이 이벤트를 영구히 놓친다. 따라서 **T ≤ 168h**.
4. **수리 항목 수는 간격과 무관** — 자주 돌려도 얻는 것이 없고, 같은 이벤트를 다시 "수리"하기만 했다.

→ 7일 경계값이 최적. 재부팅/절전으로 틱이 밀리는 것을 감안해 144h(6일)로 운용한다.
12시간 틱 + 2시간 허용오차 → 실제 6.0~6.5일 간격.

> 전체 근거·검증 기록: [`REPORT-2026-11-05.md`](REPORT-2026-11-05.md)

### 이중 게이트 허용오차
wrapper는 `status.json`(마지막 **시작** 시각), 내부 스크립트는 `.last_run`(마지막 **완료** 시각)을
기준으로 주기를 검사한다. 두 기준점 차이 때문에 주기 경계에서 한 번 더 SKIP 되던 문제를 막기 위해
양쪽 모두 `cadence - min(2h, cadence×10%)` 로 비교한다.

## 검사 항목 (39단계)과 주기

주기는 **비용(실측)** 과 **검출 지연의 대가**로 정했다. 가벼운 검사는 매 실행(6일)이 가장 싸고,
무거운 검사만 "이상이 없던 횟수"를 근거로 늘렸다.

| 구분 | 단계 | 주기 | 근거 (실측) |
|------|------|------|-------------|
| 기본 | OS, CPU, Memory, Disk, Service, VSS, DiskHealth, SysFix, SecureBoot, Recovery, WMI, CertStore, TaskHealth, GPU, Battery, WHEA, DriverStore, BrowserCache, HostFile, DNS, **AdQuiet, AdFilter**, Network, GhostDev, PkgCache, Startup, RecycleBin, RegHive, BSOD | 매 실행 (6일) | 각 단계 5초 미만(신규 5단계 합계 **0.6초**). Disk/Service/VSS 는 "지금 고쳐야 하는" 항목이라 늘리면 손해 |
| 오래된 드라이버 | OldDrivers — 새 버전이 설치됐는데 남은 이전 드라이버 감지 | **30일** (`oldDriverCheckDays`) | 드라이버 목록은 거의 안 바뀐다. SFC/WinSxS 와 함께 **가장 긴 주기**. 목록은 보여주되 삭제는 직접 실행에서 `y` 확인 후에만 |
| 인증 상태 | OS 정품 인증 (`licenseCheckDays`) | **30일** (`licenseCheckDays`) | 첫 조회가 **콜드 15초**(`sppsvc` 기동), 워밍 1.5초. 거의 변하지 않는 값이라 30일 게이트 |
| 위임 확인 | Defrag — 최적화는 **하지 않고** `ScheduledDefrag` 작업 상태만 확인 | 매 실행 | 실제 최적화는 Windows가 주 1회(유지보수 창) 수행 |
| 파일시스템 | CHKDSK (`chkdsk /scan`, 모든 NTFS 볼륨) | **12일** (`chkdskDays`) | 실측 130~190초/회. 144h의 정확히 2배 → 2회마다 1번 |
| 시스템 파일 | SFC (`/verifyonly`) + WinSxS (DISM 분석/정리) | **30일** (`heavyCheckDays`) | 실측 SFC 112~240초, DISM 30~60초. 2026-10~11 7회 연속 무결성 이상 0건 |
| 추세/상태 | TimeSync, Stability, BootPerf, Updates | 매 실행 | Updates COM 검색 10~12초, TimeSync 3샘플 약 3초 |
| 자동 치유 | Auto-Heal | 매 실행 | 이벤트 7일 창, RecordId 중복 제거 |

실행 시간(측정): 일반 실행 **약 33~45초**(2026-11-10, 38단계 · 광고 단계 포함 / v1.13.0에서 OldDrivers 1단계 추가), CHKDSK 포함 **약 194초**, SFC/WinSxS 포함 **약 6분**.
광고 단계(AdQuiet·AdFilter)는 실측 **1초 미만**(hosts 읽기/쓰기 + HKCU 값 20여 개). 오래된 드라이버 감지도 드라이버 목록 읽기만 해서 수 초 내외.
시스템 복원이 꺼져 있던 실행은 복원 지점 생성 때문에 **약 66초**(16초 추가)가 걸린다.

### 자동 조치 (검출 → 자동 해결)

안전하고 **되돌릴 수 있는** 것만 자동으로 한다. 조치 내역은 로그 `FIX:` 줄,
`last-result.json`의 `autoFixes`, `status.json`의 `autoFixes` 에 남는다.

| 검사 | 검출 조건 | 자동 조치 |
|------|-----------|-----------|
| Service | `Spooler` 등 `restartServices` 가 중지 | 서비스 재시작 |
| VSS | 볼륨 섀도 복사본 서비스 중지 | 서비스 재시작 |
| Disk | 여유 공간 < **그 드라이브 용량의 10%** | TEMP/Windows Temp 정리 (**삭제 전 확인** + 4중 안전장치) |
| BrowserCache | 30일 이상 된 캐시 파일 | 파일 삭제 (**삭제 전 확인**) |
| RecycleBin | 30일 이상 된 휴지통 항목 | 비우기 (**삭제 전 확인**) |
| PkgCache | pip/conda 캐시 > 2GB | `pip cache purge` / `conda clean --all` |
| SysFix | 덤프 형식/복원/로그 크기/섀도 저장소/대화형 서비스 이상 | 설정 복구 (+복원 지점 생성) |
| SysFix (시간) | W32Time 서비스 중지, 소스가 `Local CMOS Clock`/`Free-running`/**오류 문자열** | 서비스 시작 → `/config` + `/resync /rediscover` (**`/unregister` 금지**) |
| Defrag | `ScheduledDefrag` 가 Disabled | 작업 재활성화 (**2026-11-06 추가**) |
| TimeSync | NTP 오차 ≥ 1초 | `w32tm /resync /force` 후 **재측정** (**추가**) |
| Updates | `wuauserv` 가 Disabled | Manual 로 복구 (**추가**) |
| Updates | WU COM 검색 실패 | `wuauserv`/`bits`/`cryptsvc` 시작 후 1회 재검색 (**추가**) |
| Updates | Defender 서명 > 3일 | `Update-MpSignature` 후 나이 재확인 (**추가**) |
| Updates | Defender 실시간/동작/안티바이러스 보호 꺼짐 | `Set-MpPreference` + `WinDefend` 시작 후 **재확인** (**2026-11-09 추가**) |
| Recovery | WinRE 비활성(`reagentc /info`) | `reagentc /enable` 후 재확인 (**추가**) |
| WMI | 리포지토리 `inconsistent` | `winmgmt /salvagerepository` 후 재확인 (**추가**) |
| Updates | 대기 업데이트 존재 + `autoInstallUpdates: true` | 다운로드/설치 (**옵션, 기본 꺼짐**) |
| Auto-Heal | 이벤트 목록의 자동 복구 가능 항목 | 기존 복구 동작(스풀러/검색/방화벽/WMI/TPM 등) |

보고만 하는 단계: `CertStore`(인증서 갱신은 소유자 판단), `TaskHealth`(예약 작업 재등록은 스크립트별 인수·트리거가
달라 위험), `SecureBoot`(BIOS 설정 변경 불가). 셋 다 문제가 있으면 `recommendations` 에 남는다.

**자동화하지 않는 것(권고만)**: `catroot2`/SoftwareDistribution 삭제, `netsh int ip reset`,
`ipconfig /release`, `WlanSvc` 재시작, SFC/DISM 강제 복구, `wsreset`, Defender 전체 검사,
NTP 피어 재설정 시 `w32tm /unregister`, 드라이버 강제 제거, 유령 장치 삭제,
`winmgmt /resetrepository`(리포지토리 파괴적 재생성), `reagentc /disable`, Secure Boot/TPM 설정 변경,
인증서 삭제·갱신(소유자 판단 필요) — 되돌릴 수 없거나 무효/위험한 조치.

> `w32tm /unregister` 는 **서비스 등록을 삭제**한다(2026-11-06 실제 사고). 복구는 `/register` + `StartupType Automatic`.

## 삭제 전 확인 (단계마다 A / Y / N)

사용자 요청(2026-11-12): **"자료를 지우기 전에 지우려는 목록을 보여주고 yes/no 를 고르게 해달라"**.
사용자 요청(2026-11-20, v1.14.0): **"임시파일 및 휴지통 삭제할 때 A 를 추가해. A는 언제나 삭제,
Y는 현재 삭제, N은 거부야."**

파일을 지우는 단계는 모두 `Invoke-DeleteReview` 를 거친다 — 임시 폴더(여유 공간 부족할 때),
브라우저 캐시(30일↑), 휴지통(30일↑). 이 키트가 만든 결과 txt(3개월↑)는 **묻지 않고 자동 삭제**한다
(v1.4.0, `resultRetentionDays`). 오래된 드라이버는 별도 `y` 확인을 쓴다.

**v1.14.0 부터는 각 삭제 단계에서 한 번씩 묻는다.** (v1.2.0~v1.13.0 은 시작할 때 한 번만 물었다.)

| 단계별 입력 | 동작 | 설정 변경 | 결과 txt 표기 |
|------------|------|-----------|---------------|
| `A` (또는 `all`/`언제나`/`항상`) | **언제나 삭제** — 지금 지우고, 해당 항목의 config 키를 `true` 로 저장 | 저장됨 | `지움 (A — 언제나 삭제 선택)` |
| `Y` (또는 `y`/`yes`/`예`) | **현재만 삭제** — 이번 실행에서만 지움 | 없음 | `지움 (Y — 현재만 삭제)` |
| `N` 또는 Enter | **거부** — 아무것도 지우지 않음 (기본값) | 없음 | `그대로 둠 (N — 거부)` |
| (물어볼 수 없음) 예약 실행 | 저장된 `A`가 없으면 **아무것도 지우지 않고 보류** | 없음 | `그대로 둠 (자동 실행 — 물어볼 사람이 없어 보류)` |
| `A` 저장 후 예약 실행 | 묻지 않고 **자동 삭제** | 이미 저장됨 | `지움 (A — 설정에 기억된 자동 삭제)` |

`A` 가 저장되는 설정 키 (기본값 모두 `false`):

| 설정 키 | 대상 단계 |
|--------|----------|
| `tempAutoDelete` | 임시 폴더의 오래된 파일 |
| `browserCacheAutoDelete` | 브라우저 캐시 (30일 이상) |
| `recycleAutoDelete` | 휴지통 (30일 이상) |

`config.json` 에서 해당 키를 `false` 로 되돌리면 다시 단계마다 묻는다. `A` 는 사용자가 명시적으로
누른 경우에만 저장되며, 저장에 실패하면 이번 실행만 삭제하고 경고를 남긴다.

- **지울 파일이 없으면 아무것도 묻지 않는다** — 후보가 0개인 단계는 조용히 넘어간다.
- 화면 목록은 **큰 파일부터 20개**(나머지는 `... 외 N개`) + 총 개수/용량을 보여준다.
- **기록에는 20개 제한이 없다** — 결과 txt·로그·`last-result.json`(`deleteReview.paths`)에는
  **모든 파일의 전체 경로(폴더 + 파일명)** 가 남는다(아래 "삭제한 파일의 전체 경로" 참고).
- 결정과 목록은 **로그 + 데스크톱 결과 txt + `last-result.json`(`deleteReview`)** 에 남는다.
- `A` 로 자동 삭제를 켜도 **삭제 대상 후보 자체는 그대로 제한된다** — 30일 경과, 임시 폴더 안전 검사
  (드라이브 루트·사용자 데이터 폴더 제외), 한 번에 5GB 상한 등은 유지된다.
- 프롬프트는 사용자가 직접 실행한 경우에만 전달된다(`run-maintenance.ps1 -Force` → `-PromptForDelete`).
  단, `A` 가 저장된 항목은 예약 실행에서도 자동 삭제된다(v1.14.0 사용자 결정).

## 오래된 드라이버 정리 (v1.13.0, 2026-11-19)

새 버전이 **이미 드라이버 저장소에 설치되어 있는데** 이전 버전이 남아 있는 것만 찾는다.
인터넷 조회도, 드라이버 자동 설치도 하지 않는다.

- **감지 주기: 30일** (`oldDriverCheckDays`) — SFC/WinSxS 와 함께 이 키트에서 가장 긴 주기다.
  드라이버 목록은 거의 안 바뀌므로 6일마다 볼 필요가 없다. 마지막 실행은
  `Simple maintenance\.last_olddrivers` 스탬프에 기록된다(조회가 실패해도 30일 뒤 재시도).
- **판정 기준**: 같은 제조사(`ProviderName`)·장치 클래스(`ClassName`)·INF 파일명끼리 묶어
  버전을 비교하고, 더 새 버전이 있으면 이전 것만 후보로 삼는다.
- **장치 이름 표시**: `Win32_PnPSignedDriver` 에서 INF 별 장치 이름을 읽어
  `oemNN.inf [장치: ...]` 형태로 함께 적는다. 한 INF 가 여러 장치에 쓰이면 앞 2개만 표시한다.
- **절대 후보에서 제외**: 현재 장치가 사용 중인 드라이버(`Win32_PnPSignedDriver.InfName`),
  부팅 필수(`BootCritical`), 기본 제공(`Inbox`), 그리고 System/Filter/Boot/HAL/Disk/SCSI/
  Volume/FileSystem/Keyboard/Mouse 등 보호 클래스.
- **기본 켜짐**(`oldDriverCleanup=true`)이지만, **삭제는 사람이 보는 창에서 `y` 를 누를 때만**
  실행한다. 예약/유휴 실행에서는 후보 목록만 결과 txt 에 남기고 아무것도 지우지 않는다.
- 실제 삭제는 `pnputil /delete-driver oemNN.inf` 이며 `/uninstall` 은 쓰지 않는다
  (장치에 설치된 드라이버를 건드리지 않기 위함). INF 이름은 `^oem\d+\.inf$` 로 엄격 검증한다.

결과 txt 에는 이렇게 적힌다:

```
[오래된 드라이버] 새 버전이 있음에도 남아 있는 이전 드라이버 2개
  · oem3.inf — ACME / Net / a.inf 1.0.0.0 [장치: ACME Gigabit Ethernet] → 최신 2.0.0.0 (oem4.inf)
  · oem9.inf — ACME / Media / b.inf 3.0.0.0 [장치: ACME Sound Card] → 최신 4.0.0.0 (oem10.inf)  [보류: 현재 장치가 사용 중]
  삭제: 1개
    · oem3.inf [장치: ACME Gigabit Ethernet] 삭제 완료
  삭제되지 않음: 1개 — 확인해보세요. 직접 실행하여 삭제 질문에 y를 누르면 삭제됩니다.
    · oem9.inf [장치: ACME Sound Card] — 현재 장치가 사용 중
```

`oldDriverCleanup=false` 로 바꾸면 감지 자체를 끌 수 있다.

### 삭제한 파일의 전체 경로를 남긴다 — 복구용 (2026-11-13)

사용자 지시: **"삭제하려는 파일 경로와 폴더 및 파일 이름은 남아있지? 결과 txt에도 남아있어야 하고.
복구할 수 있게. 만화 폴더 안에 1.jpg 2.jpg 3.jpg 이렇게 있는데 만화 폴더가 수십개면
뭐가 지워졌는지 구분을 못하잖아."**

파일명만 남기면 폴더가 여러 개일 때 어느 폴더의 `1.jpg` 인지 알 수 없다 → **전체 경로**를 세 곳에 남긴다.

| 위치 | 내용 | 보관 |
|------|------|------|
| 데스크톱 결과 txt `[삭제 전 확인 목록 — 지운/보류한 파일의 전체 경로 (복구용)]` | 지운(또는 보류한) **모든 파일의 전체 경로** + 크기 + 날짜, 기록 파일 경로 안내 | 사용자가 지우기 전까지 |
| `Simple maintenance\logs\deleted-<시각>.txt` | 승인(y)해서 **실제로 지운** 파일만, 탭 구분(전체경로 / 크기 / 날짜) — 복구 도구에 붙여넣기 좋은 형태 | **최소 30일** |
| `last-result.json` → `deleteReview[].paths` / `deletedFile` | 같은 목록(JSON) | 다음 실행까지 |

- 휴지통 항목도 **원래 있던 폴더 경로**를 붙여서 기록한다(예: `C:\Users\me\Pictures\여행\IMG_2231.jpg`).
- 예약(자동) 실행은 아무것도 지우지 않으므로 `deleted-*.txt` 도 만들지 않는다(목록만 결과 txt 에 남는다).
- `deleted-*.txt` 는 로그 정리(`logsRetentionDays`)와 무관하게 **최소 30일** 보관한다.

```
[삭제 전 확인 목록 — 지운/보류한 파일의 전체 경로 (복구용)]
  · [임시 폴더 (C:\Users\me\AppData\Local\Temp)] 3개 / 3.0MB → 지움 (앞에서 한 번에 승인)
      지금 C 드라이브 여유 공간은 0.4GB 입니다.
      C:\Users\me\AppData\Local\Temp\만화01\1.jpg  (1.0MB, 2024-03-01 00:00)
      C:\Users\me\AppData\Local\Temp\만화02\1.jpg  (1.0MB, 2024-03-01 00:00)
      C:\Users\me\AppData\Local\Temp\만화03\1.jpg  (1.0MB, 2024-03-01 00:00)
      → 이 목록은 파일로도 저장했습니다: C:\...\logs\deleted-20261113-143658.txt (30일 보관)
```

### 용량이 부족해도 "최소 용량 확보"를 위해 자동 삭제하지 않는다 (2026-11-12)

사용자 지시: **"용량이 적게 남았더라도(극단적으로 100MB만 남았더라도) 최소 용량을 확보하게 하지 마라.
용량이 이만큼 남았으니 오래된 파일부터 삭제합니다. 필요한 자료가 있으시면 백업하세요.
삭제하시겠습니까? yes or no 로 해서 y 를 눌러야만 삭제해."**

- 디스크 여유가 **그 드라이브 용량의 10%** 미만이어도 **자동으로 지우지 않는다.** 후보 목록만 만들고 물어본다.
- 삭제 후에도 **목표 용량까지 채우려고 추가로 지우지 않는다.** 여유 공간은 참고로 기록만 한다.
- `A` 또는 `y` 를 입력하지 않으면(Enter·n·시간 초과·자동 실행) **아무것도 지우지 않고** 그대로 둔다.
  단, 이전에 `A` 를 눌러 저장한 항목은 예약 실행에서도 자동 삭제한다(v1.14.0).
- 프롬프트에는 **남은 용량 + 백업 안내**가 항상 나오고, `현재 용량으로는 디스크 속도나 이용에 문제가
  있을 수 있습니다` 라는 경고는 **5GB 미만으로 정말 위험할 때만** 나온다(2026-11-13 지시: "500GB·3TB
  남았는데 몇 GB 남았습니다, 문제가 생길 수 있습니다 라고 띄우는 게 말이 되냐").

### "부족"의 기준은 드라이브마다 그 용량의 10% (2026-11-13)

사용자 지시: **"디스크 용량은 각 드라이브 용량의 10%를 기준으로 해. 일괄 100GB로 하지 말고."**

| 드라이브 용량 | 부족 판정 기준(10%) | 500GB 남음 | 3TB 남음 |
|---------------|--------------------|-----------|----------|
| 512GB SSD | 51GB | 정상 | — |
| 1.86TB (이 PC의 C) | 186GB | 정상 | 정상 |
| 4TB HDD | 400GB | 정상 | 정상 |
| 64GB (USB) | 6.4GB | — | — |

- 기준 미만이면 결과 txt 에 `[Disk] C 드라이브의 여유 공간이 150GB 입니다. … 186.2GB 이상 확보 권장`
  이라고 남는다(자동 삭제 없음).
- `diskThresholdGB` 설정은 **드라이브 용량을 알 수 없을 때만** 쓰는 대체값이다(기본 10GB).
  예전처럼 "일괄 100GB" 같은 상한을 두지 않는다.
- `현재 용량으로는 디스크 속도나 이용에 문제가 있을 수 있습니다` 경고는 **5GB 미만**일 때만 붙는다.

```
[삭제 확인] 임시 폴더 (C:\Users\me\AppData\Local\Temp) — 34개 / 4.8GB
  지금 C 드라이브 여유 공간은 412.3MB 입니다.
  현재 용량으로는 디스크 속도나 이용에 문제가 있을 수 있습니다.
  용량이 이만큼 남았으니 오래된 파일부터 삭제합니다.
  필요한 자료가 있으시면 백업을 하세요.
  지우려는 목록:
    · setup_2024.tmp (1.2GB, 2024-03-11)
    · ... 외 33 개
  A = 언제나 삭제(설정에 기억) / Y = 현재만 삭제 / N 또는 Enter = 거부: a
  → A: 앞으로 이 항목은 묻지 않고 자동 삭제합니다. (설정에 저장됨)
```

다음 실행부터 이 항목은 묻지 않고 지운다.

```
[삭제 확인] 임시 폴더 (C:\Users\me\AppData\Local\Temp) — 12개 / 1.1GB
  → A(언제나 삭제)가 설정에 저장되어 있어 묻지 않고 지웁니다.
```

`Y` 를 누르면 이번 실행에서만 지우고 설정은 바뀌지 않는다. `N`(또는 Enter)은 거부다.
`config.json` 의 `tempAutoDelete` / `browserCacheAutoDelete` / `recycleAutoDelete` 를 `false` 로
되돌리면 다시 단계마다 묻는다.

### 임시 폴더 정리의 4중 안전장치 (2026-11-12 사고 후 추가)

> **사고**: 배포받은 PC의 `TEMP`/`TMP` 가 드라이브 루트(`I:\`)를 가리키고 있었고, 디스크 부족 판정이 나자
> "임시 폴더"로 보고 그 드라이브의 사진·문서를 전부 지웠다. 확인 프롬프트도, 나이 제한도 없었다.
> 상세 경위는 `REPORT-2026-11-05.md` §12.10.

이제 임시 폴더 정리는 아래를 **모두** 만족할 때만 동작한다.

| 안전장치 | 내용 |
|----------|------|
| 경로 검사 | `Test-SafeTempDir` — **드라이브 루트 금지**, 바탕화면·문서·사진·다운로드·OneDrive·설치 폴더 금지, 이름이 임시 폴더(`Temp`/`Tmp`/`Cache`/`AppData\Local\Temp`/`Windows\Temp`)가 아니면 제외 |
| 드라이브 일치 | **부족한 그 드라이브 안에 있는 임시 폴더만** 정리(다른 드라이브/USB 때문에 엉뚱한 폴더를 지우지 않음) |
| 나이 제한 | `tempMinAgeDays`(기본 1일) 이내에 수정된 파일은 **삭제 금지** |
| 용량 상한 | `tempCleanupMaxGB`(기본 5GB)까지만. **목표 용량까지 채우려고 추가 삭제하지 않는다** |

- 제외된 경로는 조용히 넘어가지 않고 결과 txt 에 `[정리 제외] '경로' — 드라이브 루트는 정리 대상이 될 수 없음`
  처럼 이유와 함께 남는다. (`TEMP`가 드라이브 루트인 PC는 자동 정리를 건너뛴다.)
- 임시 폴더 안의 **정션/심볼릭 링크(바로가기 폴더)는 따라가지 않는다**(`Get-FilesNoReparse`).
  링크를 따라가면 링크 대상(예: 사진 폴더)의 실제 파일을 지울 수 있기 때문.
- 즉, **`TEMP` 위치가 어디든 사진/문서 폴더는 지우지 않는다.**

결과 txt 에는 이렇게 남는다(전체 경로 — 복구용).

```
[삭제 전 확인 목록 — 지운/보류한 파일의 전체 경로 (복구용)]
  · [휴지통 (30일 이상 지난 파일)] 12개 / 340.5MB → 그대로 둠 (앞에서 한 번에 보류)
      C:\Users\me\Documents\보고서_최종.docx  (120.0MB, 2026-09-30 09:12)
      C:\Users\me\Pictures\여행\IMG_2231.jpg  (12.3MB, 2026-10-01 18:40)
      ...
```


### 2026-11-05 개편 요약
**추가**
- `TimeSync`: NTP 오프셋 실측(`w32tm /stripchart`, 3샘플 중앙값). 1초↑ WARN, 5초↑ FAIL.
  기존 Time-Service 134/135 이벤트는 **전부 부팅 0~2초**에 발생하는 정상 노이즈(네트워크 준비 전 NTP 조회)라
  재설정 자동화를 제거하고 측정만 남겼다.
- `Stability`: 7일 경고/오류를 Provider/EventID로 집계 + **앱 크래시(이벤트 1000) 프로세스별 횟수**.
  5회 이상 반복 크래시는 WARN. 이전 실행에 없던 오류 유형은 `CHANGE`로 보고(`stability-state.json`).
- `BootPerf`: Diagnostics-Performance 100/101/200 + Kernel-Power 41. 바탕화면까지 평균 45초↑ WARN.
  (기존 "시작 프로그램 15개 초과" 검사는 부팅 시간과 상관이 약해 제거)
- `Updates`: Windows Update COM 검색(대기 항목), 마지막 누적 패치 경과일, Defender 서명 나이, 재부팅 대기 여부.
  Defender 정의 업데이트는 "대기"로 세지 않는다.
- `last-result.json`: 매 실행 결과 요약(상태/벽시계 시간/실패 사유/권장 사항). FAIL 시 **토스트 알림**.
  (기존에는 데스크톱 리포트가 오래되면 삭제되어 FAIL을 아무도 보지 못했다 — v1.4.0 부터 3개월 뒤 자동 삭제)

**제거/게이트**
- SFC·WinSxS: 6일 → **30일**. 7회 연속 이상 없음(실측 SFC 112~240s/회).
- CHKDSK: 30일 → **12일** (2026-11-06). `-Optimize` 대신 주기적으로 파일시스템을 검사하도록 조정.
  144h의 2배라 2회마다 1번, 실측 130~190초/회.
- **Optimize 단계 제거(2026-11-06)**: 볼륨 최적화(조각모음/TRIM)를 Windows 기본 작업에 위임했다.
  `\Microsoft\Windows\Defrag\ScheduledDefrag`(`defrag.exe -c -h -o -$`)를 **다시 켰고**, `/O`가 볼륨별로
  HDD→조각모음 / SSD→retrim / 티어공간→TierOptimize를 알아서 고른다(문서: "Perform the proper optimization for each media type").
  스크립트에는 **상태 확인만** 남겼다(Disabled면 WARN + 권고, 실행은 하지 않음). `defragThreshold` 키도 삭제.
- `Hide-ProblematicDriverUpdates` 호출 제거: Chipset/Firmware/BIOS 업데이트까지 숨겨 필요한 드라이버 수정을 차단하고,
  네트워크 조회로 30~120초를 매번 소모했다. (PSWindowsUpdate 2.2.1.5는 설치되어 있어 실제로 매번 실행 중이었음)
- PkgCache: 총량 5GB 초과 시 무조건 WARN + pip/conda 강제 정리 → **pip/conda 2GB 초과일 때만 정리**,
  HuggingFace 캐시(113.6GB, gemma-4 74.6GB 사용 중)는 **절대 자동 삭제하지 않고** `hfCacheWarnGB`(150GB) 초과 시에만 알림.
- Startup: "15개 초과 WARN"(25개 고정 → 영구 노이즈) → **기준선 대비 신규 항목만 WARN**(`startup-baseline.json`).

**자동 복구 → 권고 전용으로 전환 (위험/무효)**
- Windows Update `catroot2`/SoftwareDistribution 삭제, `netsh int ip reset`/`winsock reset`,
  `ipconfig /release`, `WlanSvc` 재시작, Auto-Heal 내부 `sfc`/`DISM`, `wsreset`, Defender 빠른 검사,
  시간 동기화 피어 재설정.
- 근거: WLAN-AutoConfig 10003 33건 + `WLANExt.exe` 크래시 19건은 Intel 드라이버(`IntelIHVRouter10.dll`) 문제로
  서비스 재시작으로 해결되지 않고, 재시작할 때마다 Wi-Fi 메트릭이 35로 초기화됐다(메트릭 churn의 원인).
  Defender는 이미 매일 빠른 검사를 자체 스케줄로 수행한다.
- Auto-Heal은 이제 `autoheal-state.json`의 마지막 RecordId로 **이미 처리한 이벤트를 재처리하지 않는다**
  (7일 조회창 때문에 매 실행마다 같은 서비스를 다시 재시작하던 문제).

**검증 중 발견해 고친 버그 6개** (상세: `REPORT-2026-11-05.md`)
1. 마지막 단계(Auto-Heal) 시간이 계측에서 누락 → 요약 전 flush.
2. 리디렉션 환경에서 `[Console]::CursorTop` 실패로 네이티브 명령 래퍼 전체가 예외 → `IsOutputRedirected`면 스피너 생략.
3. `"$skippedHandled건"` — PowerShell이 한글을 변수명에 포함시켜 StrictMode 오류 → `${skippedHandled}건`.
4. 실패 사유가 있어도 `Overall Status: PASS` (34개 실패 분기 중 24개가 `$allPass` 미설정) → 요약에서 보정.
5. `FixNetworkMetric.ps1`이 모든 어댑터를 metric 1로 설정 → 0/1/2 규칙으로 통일.
6. wrapper가 이전 실행의 `last-result.json`을 새 결과로 읽음 → "실행 시작 이후에 쓰인 파일"만 인정.

### 2026-11-06 개편 요약 (주기 재설계 + 자동 조치)

**주기**
- CHKDSK 를 30일 → **12일**(`chkdskDays`)로 당겨 144h 주기의 2회마다 실행. `Optimize`(볼륨 최적화)는
  Windows `ScheduledDefrag` 에 위임하고 스크립트에서는 제거(→ `Defrag` 상태 확인 단계).
- WinSxS 게이트의 하드코딩 30일을 `heavyCheckDays` 로 통일(설정 하나로 SFC와 함께 움직임).
- 나머지 검사는 실측 5초 미만이라 매 실행(6일) 유지 — 늘리면 검출이 늦어질 뿐 이득이 없다.

**자동 조치 (`Add-AutoFix`)**
- 새 헬퍼 `Add-AutoFix` 로 "자동으로 고친 일"을 로그(`FIX:`)/`last-result.json`/`status.json`/데스크톱 리포트에 남긴다.
- 새로 자동화한 것: `ScheduledDefrag` Disabled → 재활성화, NTP 오차 ≥1초 → `w32tm /resync /force` + 재측정,
  `wuauserv` Disabled → Manual, WU 검색 실패 → 관련 서비스 시작 후 재검색, Defender 서명 >3일 → `Update-MpSignature`.
- 옵션 `autoInstallUpdates`(기본 false): 대기 업데이트 자동 다운로드/설치. 재부팅 대기 중이면 건너뛴다.
- 기존 자동 복구(서비스/VSS/임시파일/캐시/휴지통/pip·conda/SysFix/Auto-Heal)도 모두 `autoFixes` 에 집계된다.
- **시간 동기화 사고 수정**: `w32tm /unregister` 제거(서비스 등록이 삭제됨), 서비스가 멈춘 상태의
  오류 문자열을 "정상 소스"로 오인하던 버그 수정. 복구 후 `Running/Automatic` + 소스 `kr.pool.ntp.org` 확인.

### 2026-11-09 추가 검사 (36단계로 확장)

인터넷의 범용 점검 목록을 조사한 뒤 **이 PC 실측 비용**과 **안전/가역** 기준으로 5개만 채택했다.
새 5단계 합계 비용 **0.6초**, 전체 실행은 **33~36초**로 개편 전과 동일하다.

| 단계 | 근거 | 비용 |
|------|------|------|
| `SecureBoot` | 2011년 Secure Boot 인증서가 2026-06 부터 만료 → `UEFICA2023Status`(CA 2023 갱신), TPM, Secure Boot | 0.2s |
| `Recovery` | WinRE 등록(`reagentc /info`)이 끊기면 복구/안전 모드 진입 불가 | 0.2s |
| `WMI` | 리포지토리 손상 시 CIM 기반 검사가 **조용히** 실패(거짓 PASS) | 0.1s |
| `CertStore` | `LocalMachine\My`·`WebHosting` 만료/30일 임박 보고 | 0.0s |
| `TaskHealth` | 자동화 예약 작업 생존 확인(`watchedTasks`) — 2026-11-01 "한 번도 실행 안 된 태스크" 사고 재발 방지 | 0.1s |

- `OS` 정품 인증 추가하되 **30일 게이트**(`licenseCheckDays`): 첫 조회가 `sppsvc` 기동으로 **콜드 15초**.
- `Updates`: Defender 실시간/동작/안티바이러스 보호가 꺼지면 자동 재활성화 후 재확인.
- `last-result.json` 에 `stepTimings`(단계별 소요 초) 추가 → 다음부터 느린 단계가 바로 보인다.
- 제외한 후보와 근거는 `REPORT-2026-11-05.md` 11.2 절(페이지파일/BitLocker/SMART self-test/전체 예약작업 스캔 등).

## 광고/추천 끄기 · 광고 도메인 차단 (2026-11-10, 38단계)

Windows 11 은 기본값이 "광고 ON" 이라 새 PC/재설치 후 프로모션이 다시 나타난다. 이 키트는
**끄는 스위치가 있으면 스위치를 끄고, 없으면 트리거(예약 작업)를 비활성**한다.
**파일 삭제·앱 제거·코드 패치는 하지 않는다.**

| 단계 | 기본값 | 하는 일 | 되돌리기 |
|------|--------|---------|----------|
| `AdQuiet` | **켜짐** (`adQuiet=true`) | HKCU 20여 개 값(ContentDeliveryManager, AdvertisingInfo, Scoobe, 시작 메뉴 추천 등) + 프로모션 알림 + `SoftLanding` 예약 작업 비활성. 잠금화면 **사진 로테이션은 유지** | `adQuiet=false` → 다음 실행에서 자동 복원, 또는 `uninstall.ps1 -RestoreAds` |
| `AdFilter` (hosts) | **꺼짐** (`adBlockEnabled=false`) | hosts 에 마커 블록으로 광고/추적 도메인 추가(정확한 호스트명만, 기본 `ads` 27개) | `adBlockEnabled=false` → 다음 실행에서 마커 블록 제거(사용자 줄은 보존) |
| `AdFilter` (DNS) | **꺼짐** (`adDnsEnabled=false`) | 유선/무선 어댑터 DNS 를 `adDnsServers`(기본 AdGuard DNS)로 변경 | `adDnsEnabled=false` → 저장해 둔 원래 DNS 로 복원 |

### ⚠ 이 기능을 켜면 생길 수 있는 문제

- **광고/추천 스위치**: 설정·시작 메뉴의 "추천/팁", 잠금화면 문구가 달라진다(기능 정상 동작에는 영향 없음).
- **hosts 차단**: Windows hosts 는 **와일드카드를 지원하지 않는다**(`*.example.com` 은 아무것도 막지 못함).
  정확한 도메인만 막히며, 드물게 **앱 로그인·설치·업데이트가 실패**할 수 있다
  → `adBlockAllowDomains` 에 예외를 넣거나 `adBlockEnabled=false`.
- **DNS 변경**: 공유기·프린터·NAS 같은 **내부 주소를 못 찾거나**, VPN·보안 프로그램과 충돌할 수 있다
  → `adDnsEnabled=false`.
- **광고 차단은 100%가 아니다**: 앱 안에 직접 그려지는 광고와 이미 설치된 광고 앱은 막지 못한다.
- 공통: 이 키트는 **파일을 지우거나 앱을 제거하지 않는다**. 되돌리기 데이터는 `Simple maintenance\adbackup\`
  (`ad-state.json`, `hosts.orig.bak`, `dns-state.json`)에 남고 `uninstall.ps1 -RestoreAds` 로 한 번에 복원한다.

위 경고는 매 실행 **데스크톱 리포트의 `[광고 설정 주의]` 블록**, `last-result.json` 의 `adWarnings`,
`run-now.ps1` 콘솔에 그대로 출력된다(켜 둔 기능이 있을 때만).

### 광고를 끄는 방법 (실측 근거)

- `Microsoft.Windows.ContentDeliveryManager` 앱은 `NonRemovable=True` + `TrustedInstaller` 소유 → **삭제 불가**.
  그래서 삭제 대신 `ContentDeliveryAllowed` 등 **스위치**를 껐다(즉시 되돌릴 수 있음).
- 위젯(`TaskbarDa`)은 2026-11-09 실측에서 **Windows 가 쓰기를 거부**(Access denied)했고 화면에 바로 보이는
  UI 변경이라 자동 목록에서 제외했다. 필요하면 사용자가 직접 끈다.
- DNS 로그(`Microsoft-Windows-DNS-Client/Operational`)로 "어느 프로그램이 광고를 부르는지" 추적하는 기능은
  로그를 켜고 끄는 비용/위험이 있어 **이번 범위에서 제외**했다.

## 네트워크 메트릭

`FixNetworkMetric`(부팅/로그온 태스크)과 본 스크립트의 `Network` 단계가 **같은 규칙**을 쓴다:

> **0순위 = 가장 빠른 유선, 나머지 = 실측 속도 내림차순 (0, 1, 2, 3 …)** (`AutomaticMetric Disabled`)

| 상황 | 순위 |
|------|------|
| 유선 1개 + Wi-Fi 1개 | **유선 0**, Wi-Fi 1 — Wi-Fi 가 더 빨라도 유선이 0순위 |
| 유선 2개 이상 | 가장 빠른 유선 = 0, **나머지는 속도순** (다른 유선 + Wi-Fi) |
| 유선 없이 Wi-Fi 만 | 연결된 것 전체를 속도순 |
| 연결 끊김 | 속도를 알 수 없으므로(0 bps) 맨 뒤 → 다시 연결되면 다음 실행/부팅 태스크에서 재정렬 |

- 속도가 같으면 **유선 → 무선 → 이름** 순으로 순위를 깬다. 값이 겹치면 경로 선택이 비결정적이 되므로
  항상 서로 다른 값을 유지한다.
- 적용 내역은 로그에 남는다: `Network Metrics: 순위(유선 최우선 → 나머지 속도순) - 이더넷(1Gbps)=0, Wi-Fi(866.7Mbps)=1, 이더넷 2(미연결)=2`
- 파일: `C:\ProgramData\FixNetworkMetric.ps1` (저장소 사본 `scripts\FixNetworkMetric_boot.ps1`), 로그: `C:\ProgramData\FixNetworkMetric.log`
- VPN 어댑터가 있으면 경로 보존을 위해 **아무것도 바꾸지 않는다**.

## 수동 실행

```powershell
# 주기 무시하고 즉시 점검 (check 모드, 데스크톱 리포트 없음)
powershell -NoProfile -ExecutionPolicy Bypass -File "I:\code\maintenance\Simple maintenance\maintenance.ps1" -Mode check

# 주기 무시 + 데스크톱 리포트 생성 (바탕화면 "자동 유지보수 점검"과 동일)
powershell -NoProfile -ExecutionPolicy Bypass -File "I:\code\maintenance\run-now.ps1"

# wrapper 경유 (주기 지켜서 실행)
powershell -NoProfile -ExecutionPolicy Bypass -File "I:\code\maintenance\run-maintenance.ps1"

# 스케줄 태스크 강제 시작
Start-ScheduledTask -TaskName 'OpenCode-Maintenance'

# 광고 설정만 원래대로 복원 (레지스트리·hosts·DNS·SoftLanding 작업)
powershell -NoProfile -ExecutionPolicy Bypass -File "I:\code\maintenance\uninstall.ps1" -RestoreAds
```

## 로그/상태
- 실행 로그: `Simple maintenance\logs\maintain-yyyy-MM-dd.log` (7일 보관, **UTF-8**)
  - `FIX:` 줄 = 자동 조치를 실제로 수행한 기록, `Auto Fixes:` 블록 = 요약
- 실행 결과 요약: `Simple maintenance\last-result.json` — `status`(PASS/FAIL), `wallSeconds`, `stepSeconds`,
  `stepTimings`(단계별 초), `failureReasons`, `recommendations`, `autoFixes`, `adStatus`(광고 단계 상태),
  `adWarnings`(광고 기능 주의문), `log` (PASS여도 권고/자동 조치가 기록된다)
- wrapper 상태: `status.json` — `status`(passed/failed/completed), `result`, `failureReasons`,
  `recommendations`, `autoFixes`, `wallSeconds`
  (`maintenance.ps1`은 항상 exit 0이므로 wrapper는 `last-result.json`을 읽어 판정한다)
- wrapper 로그: `logs\runner-yyyy-MM.log`
- 헤드리스(사용 중 자동 실행) 콘솔 출력: `logs\console-yyyy-MM.log` (2026-11-17, v1.3.0)
- 옛 설치본에서 `Simple maintenance\logs` 가 **파일**로 남아 있으면, 실행 시 `logs-legacy-<시각>.txt` 로
  이름만 바꿔 보존하고 `logs` 폴더를 새로 만든다(로그 유실 방지, 2026-11-17, v1.3.1)
- 주기 기준: `status.json`(wrapper), `Simple maintenance\.last_run`(내부)
- 무거운 검사 스탬프: `.last_chkdsk`(12일), `.last_sfc`/`.last_winsxs_clean`(30일), `.last_license`(30일)
- 이력/기준선: `diskhealth-state.json`, `startup-baseline.json`, `stability-state.json`, `autoheal-state.json`
- 광고 복원 데이터(런타임): `Simple maintenance\adbackup\` — `ad-state.json`(HKCU 원래 값 + SoftLanding 작업),
  `hosts.orig.bak`(최초 hosts), `dns-state.json`(어댑터별 원래 DNS). **git 미포함** (`.gitignore`)

## 설정 키 (config.json)
`maintenanceCadenceHours`(144), `chkdskDays`(12), `heavyCheckDays`(30), `licenseCheckDays`(30),
`watchedTasks`(감시 예약 작업), `watchedTaskMaxAgeDays`(8), `eventLookbackDays`(7),
`notifyOnFail`(true), `hfCacheWarnGB`(150), `autoInstallUpdates`(false),
`tempMinAgeDays`(1 — 이 일수보다 최근 파일은 삭제 금지), `tempCleanupMaxGB`(5 — 1회 정리 상한),
`diskThresholdGB`(10 — **드라이브 용량을 알 수 없을 때만** 쓰는 대체 기준. 실제 판정은 그 드라이브 용량의 10%),
`tempDirs`, `servicesToCheck`, `restartServices`, `criticalServices`,
`idleConsoleMinutes`(5 — 자동 실행 시 이 시간 이상 유휴면 콘솔 창을 보여준다. `0` = 항상 보이게. 직접 실행은 항상 보임),
`resultRetentionDays`(90 — 이 키트가 만든 결과 txt 를 이 일수(3개월) 넘게 지나면 자동 삭제. `0` 이하 = 끄기),
`oldDriverCleanup`(true — 오래된 드라이버 감지·삭제 기능. `false` 면 목록도 만들지 않음),
`oldDriverCheckDays`(30 — 오래된 드라이버 감지 주기. 가장 긴 주기. `0` 이하면 매 실행)
— 없는 키는 스크립트 기본값이 적용된다. (`deleteConfirm` 은 2026-11-12 안전 정책으로 제거 — 삭제는 A/Y 확인)

**광고 관련 키** (`Simple maintenance\config.json`):

| 키 | 기본값 | 설명 |
|----|--------|------|
| `adQuiet` | `true` | Windows 광고/추천 스위치 끄기. `false` 로 바꾸면 이전에 바꾼 값을 **자동 복원** |
| `adQuietKeepLockScreen` | `true` | 잠금화면 **사진 로테이션 유지**(광고/프로모션 문구만 끔) |
| `adQuietMutePromoToasts` | `true` | Store/Office/날씨 등 프로모션 알림 끔 |
| `adQuietDisableTipsTasks` | `true` | `\SoftLanding\*` 팁/광고 예약 작업 비활성 |
| `adBlockEnabled` | `false` | hosts 광고 차단 (**opt-in**) |
| `adBlockCategories` | `["ads"]` | `ads` / `trackers` |
| `adBlockExtraDomains` | `[]` | 추가로 막을 **정확한 호스트명**(와일드카드/URL 불가, 잘못된 값은 로그에 경고) |
| `adBlockAllowDomains` | `[]` | 앱이 깨질 때 예외로 둘 도메인 |
| `adBlockMaxDomains` | `500` | 안전 상한(초과 시 앞에서부터 적용) |
| `adDnsEnabled` | `false` | DNS 필터링 (**opt-in**) |
| `adDnsServers` | `["94.140.14.14","94.140.15.15"]` | AdGuard DNS(광고+트래커). IPv4 만 허용 |

## 버전 안내 버튼 (v1.16.0) — Ulanzi 조회/다운/보고 다음 버튼

바탕화면 **"자동 유지보수 버전 안내"** (`version guide.lnk`) 를 누르면 `버전안내.ps1` 이 실행됩니다.
Ulanzi 버튼에 **"버전"** 라벨을 붙여 이 바로가기를 연결하면 됩니다.

- **버튼 화면용 3줄** — `자동유지보수_버튼화면.txt` 에 저장 (조회/다운/보고 버튼과 같은 방식으로 기기 앱에서 읽어 표시)
  ```
  현재 v1.16.0
  다음 v1.16.1
  예약 5건
  ```
- **메모장 요약** — `자동유지보수_버전안내.txt` 를 열어 보여줌
  - 현재 버전 기능 목록 (README 버전 표에서 읽음)
  - 다음 예약 버전의 추가·변경 기능 (UPDATE_SCHEDULE.md W1 행에서 읽음)
  - 예약 일정 전체 (W1~W4 + M1)
- **읽기 전용** — 설치본·예약 작업·설정을 바꾸지 않습니다. `UPDATE_SCHEDULE.md` 를 ZIP 에 포함해 어느 PC 에서나 같은 값이 나오게 합니다.
- 테스트: `powershell -File 버전안내.ps1 -NoOpen` (메모장을 열지 않고 출력만 확인)

## 피드백 내보내기 (v1.6.0) — GitHub 자동 업로드 + 시스템 언어 추종

바탕화면의 **"자동 유지보수 피드백"** 바로가기를 누르면 `feedback.ps1` 이 실행되어
결과 파일에서 **민감정보와 위험 코드를 지운 사본**을 바탕화면에 만든 뒤,
**"이 내용을 GitHub 에 자동 업로드할까요?"** 를 묻는다.

| 선택 | 동작 |
|---|---|
| `y` (동의) | GraphQL `createDiscussion` 으로 GitHub Discussion 에 자동 업로드 → **성공 시 로컬 피드백 파일 삭제** |
| `n` / Enter (비동의) | 업로드하지 않고 **파일을 바탕화면에 유지** (직접 확인·편집해서 올릴 수 있음) |
| 업로드 실패 | 오류를 표시하고 **파일을 유지** (재시도 또는 직접 업로드 가능) |

### 업로드되는 내 컴퓨터 정보 (v1.15.2 안내)

오류 확인용으로 **CPU 모델과 GPU 모델만** 올라갑니다. 이름·경로·시리얼·IP 등 개인정보는 자동으로 지우고,
보고서를 서로 구분하기 위한 **해시 앞 6자리**만 함께 올라갑니다(원본 머신 GUID는 올리지 않음).
보내주신 문제는 **대부분 다음 버전에서 수정**됩니다. 이 안내는 피드백 파일, 동의 질문, 점검 종료 화면, `newbie.txt` 에 모두 표시됩니다.

### 3중 안전장치

1. **개인정보 마스킹** — `C:\Users\<이름>`, `도메인\사용자`, hosts 도메인, IP, MAC, 이메일, SSID, 시리얼, 컴퓨터명, 개별 삭제 경로를 제거.
2. **악성/이상 코드 검증** — `<script>`, `javascript:` URL, HTML 엔티티, `powershell -enc`, `IEX(`/`FromBase64String`, `eval`, 긴 base64 blob, 셸 주입 패턴을 `<BLOCKED:종류>` 로 치환하고 건수를 보고. 진단용 `PASS/WARN/FAIL`, KB 번호, 하드웨어 모델은 유지.
3. **업로드는 명시적 동의 후에만** — 기본은 비동의. 토큰은 `GH_TOKEN`/`GITHUB_TOKEN` → **배포본 동봉 `feedback-token.txt`** → `gh auth token` → 사용자 입력(저장 안 함) 순으로 얻는다.

### 배포본 동봉 토큰 (v1.14.1)

ZIP 에 포함된 `feedback-token.txt` 덕분에 **별도 토큰 입력 없이 `y`만 누르면 업로드**된다.
동봉 토큰은 **Discussions 쓰기 권한만 가진 fine-grained PAT** 이며, 접근 저장소는 `argenluna/maintenance` 하나뿐이다.
`repo`/`workflow` 같은 광범위한 토큰을 절대 넣지 말 것 — 공개 ZIP 을 통해 전체 권한이 유출된다.
동봉 토큰을 쓰고 싶지 않으면 `feedback-token.txt` 를 삭제하면 된다(이전처럼 `gh auth` 또는 직접 입력으로 동작).

### 실행 결과 확인

- 콘솔에 `실행 결과: 성공 (업로드 완료)` / `실패 (업로드 오류)` / `비동의` 배너를 표시한다.
- 바탕화면 **`자동유지보수_피드백상태.txt`** 에 시각·버전·결과·업로드 URL·오류·차단 건수를 **덮어써서** 남긴다(파일이 쌓이지 않음).
- Discussion 본문 하단에도 버전·생성 시각·안전검증 결과를 자동으로 붙인다.

### 기술 메모

- GitHub **REST 는 Discussion 생성을 지원하지 않는다** (`POST /repos/.../discussions` → 404). 따라서 **GraphQL `createDiscussion`** 을 사용한다 (`discussions:write` 또는 classic `repo` 스코프면 충분).
- 저장소 node ID / General 카테고리 ID 는 GraphQL 로 매번 동적으로 조회한다(조회 실패 시에만 공개 ID fallback).
- 자체 검사: `powershell -File feedback.ps1 -SelfTest` → **15/15 PASS** (마스킹 10 + 안전검증 5).
  **v1.6.0**: SelfTest 결과(테스트 결과)·상태 파일·콘솔·`<BLOCKED:...>` 종류 이름이 시스템 언어를 따라갑니다.
  한국어면 `자체검사: 15 PASS / ...`, 영어면 `Self-test: 15 PASS / ...` 로 출력됩니다.
- 검증 옵션: `-DryRun` (업로드 없이 대상·payload·차단 건수만 출력), `-NoUpload` (예전처럼 파일만 생성), `-Yes` (동의 질문 생략), `-Token` (테스트용).

Discussions: https://github.com/argenluna/maintenance/discussions

## 파일 구성

| 경로 | 역할 | 비고 |
|------|------|------|
| `install.cmd` | 컴맹용 더블클릭 진입점 (ASCII 전용) | `install.ps1` 호출 |
| `install.ps1` | 설치: 승격 → 문법검사 → 예약 작업 등록 → 바로가기 3개 → 첫 점검 | 1회 |
| `readme.txt` | 사용 방법 (일반 사용자용 요약) | |
| `newbie.txt` | **완전 초보자용 안내서** — 40개 검사를 레고·집·주방 비유로 설명 | |
| `run-now.ps1` | "지금 점검" (`run-maintenance.ps1 -Force` + 결과 요약) | 바로가기 대상 |
| `update-common.ps1` | GitHub Releases 조회 / 버전 비교 / 3버튼 알림창 / `update-skip.txt` 관리 (v1.12.0) | `run-maintenance.ps1`·`업데이트.ps1` 이 dot-source |
| `업데이트.ps1` / `update.ps1` | 최신 ZIP+SHA256 검증 → 새 버전 폴더 생성 → 상태 이어받기 → `install.ps1 -NoFirstRun` 재등록 (v1.8.0) | 알림창 "업데이트" 버튼 대상 |
| `update-skip.txt` | "다시 알리지 않음"으로 지정한 버전 (런타임 생성) | git 미포함 |
| `feedback.ps1` | **마스킹+악성코드 검증 → 동의/비동의 선택 → GitHub Discussion 자동 업로드** (`-SelfTest`, `-DryRun` 지원) | 바로가기 대상 |
| `자동유지보수_피드백상태.txt` (바탕화면) | 마지막 피드백 실행 결과(성공/실패/비동의·URL·오류·차단 건수), 덮어쓰기 | 실행 결과 가시화 |
| `uninstall.ps1` | 예약 작업/바로가기 제거 (로그·설정 보존) · `-RestoreAds` = 광고 설정만 복원 | 바로가기 대상 |
| `run-maintenance.ps1` | 주기 게이트, **`새 버전 안내창(직접/자동 공통)`**, `status.json` 갱신, `maintenance.ps1` 호출 | 예약 작업 대상 |
| `Simple maintenance\maintenance.ps1` | 실제 점검/자동 수리 (38단계) | |
| `config.json` / `Simple maintenance\config.json` | 설정 (wrapper용 / 실행용) | 키는 아래 참고 |
| `logs\`, `Simple maintenance\logs\` | 런타임 로그 | **git 미포함** (`.gitignore`) |

**2026-11-09 구버전 정리** — 아래 파일들은 삭제했다(참조 0건 확인 후).
`maintenance.bat`(구 래퍼) · `maintenance.bat.lnk`(바탕화면 구 바로가기) ·
`maintenance.exe` 계열(`.bak`/`.config`/`maintenance_new.exe.config`/`.ico`/`.png` — 폐기된 EXE 전환 잔재) ·
`DCOM-SOLVED.exe`(출처 불명·미서명 바이너리) · `test_err.txt`/`test_error.txt`/`test_output.txt` ·
`maintenance.ps1.bak-*` · `do-maintenance.ps1`/`idle_maintain.ps1`/`util.ps1`(SUPERSEDED 스텁) ·
`config.json.bak` · `.task_registered`(구 자동 등록 센티널).

같은 이유로 `maintenance.ps1` 내부의 **대화형 설정 프롬프트**(`Invoke-SetupPrompts`)와
**구 자동 등록 블록**(`OpenCode-Maintenance-Scheduled`/`-Idle`, SYSTEM 12h/1h)도 제거했다.
이제 예약 작업은 `install.ps1` 이 등록하는 `OpenCode-Maintenance` **하나뿐**이다.
(구 check 모드는 `registerTask=false` 일 때 `OpenCode-Maintenance-*` 를 일괄 삭제하는 부작용도 있었다.)

## 새 버전 알림 / 업데이트 (v1.12.0)

- **1단계(기본)**: `run-maintenance.ps1`이 `update-common.ps1`을 dot-source 해서
  `https://api.github.com/repos/argenluna/maintenance/releases?per_page=100` 을 조회한다.
  현재 `VERSION`보다 높은 릴리스가 있으면 **화면 중앙에 커스텀 WinForms 창**을 띄운다.
  - **직접 실행이든 예약(자동) 실행이든 동일하게 띄운다.** 알림은 wrapper 한 곳에만 있어
    한 번의 실행에서 두 번 열리지 않는다(`run-now.ps1`에는 알림 코드가 없다).
    주기 게이트를 통과한 뒤에 조회하므로, 건너뛰는 실행에서는 네트워크/팝업이 없다.
  - 문구: `자동유지보수 새 버전이 나왔습니다 / 현재 vX → vY (n버전 뒤) / 새 기능 m가지가 생겼습니다 / [기능 목록]`
  - `n` = 현재보다 새 릴리스 수, `m` = 새 릴리스 본문의 목록 항목(`-`, `*`, `·`, `1.`) 수.
    목록은 마크다운 장식을 벗겨 최대 6개까지 창에 표시하고, 나머지는 "외 N건"으로 줄인다.
  - 버튼: **업데이트**(OK) / **취소**(Cancel) / **다시 알리지 않음**(Ignore).
  - **자동 실행은 30초 뒤 자동으로 닫힌다**(취소로 처리되어 점검은 계속 진행).
    수동 실행(`-Force`)은 사용자가 선택할 때까지 기다린다.
  - 창은 `CenterScreen` + `TopMost` 라 다른 창 위 중앙에 뜬다.
  - GitHub 연결 실패·팝업 오류는 조용히 무시하고 점검을 계속한다. 선택/오류는 `logs\runner-*.log` 에 기록된다.
- **2단계**: `업데이트` 클릭 시 ZIP에 포함된 `업데이트.ps1`(영문 `update.ps1`)이 관리자 권한으로 실행된다.
  1. 최신 릴리스의 `AutoMaintenance_v*.zip` 과 `.sha256`을 내려받아 **SHA-256 검증**
  2. 기존 설치 폴더 **옆**에 `AutoMaintenance_v<새버전>` 폴더 생성
  3. `.last_*`, `config.json`, `*-state.json`, `last-result.json`, `status.json`, `adbackup`, `update-skip.txt`, `logs` 를 복사(기존 폴더는 유지)
  4. 새 폴더의 `install.ps1 -NoFirstRun -NoPause` 로 예약 작업·바로가기를 새 경로로 재등록
  5. 기존 폴더는 **삭제하지 않고 롤백용으로 남김**
- 배포 시 **반드시 GitHub Release(v1.8.0)에 ZIP과 `.sha256`을 첨부**해야 한다.
  (ZIP만 저장소 `dist/`에 두면 `/releases/latest`가 비어 알림이 동작하지 않는다)
- `run-maintenance.ps1`: `status.json`이 없을 때 강제 실행 로그에 `17758482h since last run`이
  찍히던 문제를 `no previous run`으로 표시하도록 수정(v1.8.0).

## v1.8.1 (문서·배포 정비)

- 기능 변경 없음. **오류·문구 수정 PATCH** (AGENTS.md 규칙: 오류·문구=PATCH).
- `LICENSE` 추가 — **비상업적 이용만 허용**, 악성코드·피싱·사기·스캠 목적의 변조·사용·배포 명시 금지, 출처 표시 필수.
- GitHub 저장소 상단 README에 버전/Windows/라이선스 배지, 큰 다운로드 버튼, 실제 동작 GIF(`docs/preview.gif`) 추가.
- Releases 페이지에 ZIP + `.sha256` 첨부. **공식 배포처는 `https://github.com/argenluna/maintenance/releases` 한 곳뿐**임을 명시.

## v1.13.0 (오래된 드라이버 정리)

- **기능 추가(MINOR)** — 새 버전이 이미 설치됐는데 남은 이전 드라이버를 감지하고,
  직접 실행에서 `y` 확인 후에만 `pnputil /delete-driver` 로 삭제한다.
  사용 중/부팅 필수/보호 클래스는 제외하고, 예약·유휴 실행은 목록만 남긴다.
  감지 주기는 **30일**(`oldDriverCheckDays`)로 이 키트에서 가장 길다.
- 검사 항목 38 → **39단계**. `-SelfTestDrivers` 자기검증 10/10 통과.

## 참고
- 관리자 권한 필요 (`-Mode check`가 아니면 자동 상승).
- `idle` 모드는 유휴 1시간 + GPU 사용률 20% 미만일 때만 동작. 현재 스케줄 태스크는 `scheduled`만 사용.
- 2026-09월에 만든 1회성 태스크(`winter_sfc_verify`, `winter_defender_fullscan`, `winter_fullscan_run`)와
  `SilentMemoryClean`(메모리 강제 정리 — 효과 없음)은 2026-11-05 삭제됨.
