# Gap Analysis: workledger-mvp

> Date: 2026-06-13 | Phase: check candidate | Scope: 삭제 기능 확장 반영 후 Flutter Android MVP 구현 vs plan/design/mockup

## Match Rate: 100%

현재 구현은 WorkLedger MVP의 Must Have 19개 FR을 모두 충족한다. 추가 조사에서 P0로 분류된 오늘 근무 기록 삭제와 연차 사용 내역 삭제가 구현됐고, 월간 요약 기록 목록에서 이전 근무 기록도 삭제할 수 있어 잘못 입력한 핵심 사용자 데이터에 대한 복구 경로가 확장됐다.

`bkit_pdca_analyze` 실행 결과 bkit 상태는 `check` 단계로 올라갔다. 다만 사용자 승인 없이 phase 완료 처리는 하지 않았으며, 다음 결정은 최종 QA/Check 결과를 보고 진행한다.

## Sources Checked

| Source | Purpose |
|---|---|
| `AGENTS.md` | 제품 범위, 제외 범위, bkit workflow |
| `docs/01-plan/features/workledger-mvp.plan.md` | FR-01~FR-19, NFR, scope guard |
| `docs/02-design/features/workledger-mvp.design.md` | 아키텍처, 알림 액션, fake-door, 테스트 계획 |
| `docs/02-design/mockup.md` | S-01~S-07 화면 기준 |
| `docs/02-design/user-flow.md` | 홈, 알림, 수정, 월간, 연차, 가격 흐름 |
| `docs/03-analysis/workledger-mvp.analysis.md` | 직전 95% gap analysis 기준 |
| `pubspec.yaml` | Flutter l10n, `intl`, `flutter_localizations` 설정 |
| `l10n.yaml` | ARB 입력, 출력 경로, locale 순서 |
| `lib/l10n/` | 한국어/영어 ARB와 생성된 `AppLocalizations` |
| `lib/app/workledger_app.dart` | `MaterialApp` localization wiring |
| `lib/features/work_record/presentation/` | 홈 S-01/S-02/S-03와 주요 공통 문자열 |
| `lib/features/monthly_summary/presentation/` | 월간 요약 S-05 |
| `lib/features/leave/presentation/` | 연차 관리 S-06 |
| `lib/features/pricing/presentation/` | 가격 fake-door S-07 |
| `lib/core/notifications/` | Android persistent notification action |
| `lib/core/storage/` | `KeyValueStorage.delete` 계약과 memory/persistent adapter |
| `test/widget_test.dart` | 기본 locale, 한국어 UI, 영어 locale 구조 검증 |

## Functional Requirement Status

| FR | Requirement | Status | Evidence |
|---|---|---|---|
| FR-01 | 계정 없이 앱 시작 | Done | `WorkLedgerApp`이 로그인 없이 홈 표시 |
| FR-02 | 오늘 출근 1탭 기록 | Done | `WorkRecordRepository.clockIn`, 홈 primary CTA |
| FR-03 | 오늘 퇴근 1탭 기록 | Done | `WorkRecordRepository.clockOut`, 홈 primary CTA |
| FR-04 | 상시 알림 출근/퇴근 액션 | Done | `WorkLedgerNotificationService`, `handleWorkLedgerNotificationAction`, Android notification action 2개 |
| FR-05 | 출근/퇴근 시간 수동 수정 | Done | `EditTodayWorkRecordScreen`, `updateTodayWorkRecord` |
| FR-06 | 야근/퇴근 지연/휴일근무 태그 | Done | `WorkRecordTag`, 수정 화면 tag 입력 |
| FR-07 | 짧은 메모 | Done | `WorkRecord.memo`, 수정 화면 memo 입력 |
| FR-08 | 총 연차 수동 입력 | Done | `saveTotalLeave`, `LeaveManagementScreen` |
| FR-09 | 연차 사용 일수 기록 | Done | `addLeaveUsage`, 사용 내역 저장 |
| FR-10 | 총 연차/사용 연차 기반 잔여 표시 | Done | `loadLeaveSummary`, `remainingLeaveMinutes` |
| FR-11 | 월간 근무시간 합계 | Done | `calculateMonthlySummary` |
| FR-12 | 월간 초과근무 합계 | Done | tag 기반 `overtimeReferenceDuration` |
| FR-13 | 월간 연차 사용/잔여 요약 | Done | `MonthlySummaryViewData`, `loadMonthlySummary` |
| FR-14 | 월간 리포트 만들기 버튼 | Done | `MonthlySummaryScreen._openPricingFakeDoor` |
| FR-15 | 리포트 버튼 후 가격표 화면 | Done | `PricingFakeDoorScreen` navigation |
| FR-16 | Report Pass / Pro 클릭 이벤트 기록 | Done | `LocalStoragePricingIntentRepository`, pricing tests |
| FR-17 | 실제 PDF/CSV 없이 fake-door 결과 표시 | Done | `PricingFakeDoorScreen` success copy, 결제/PDF/CSV 없음 |
| FR-18 | 한국어 기본 UI | Done | `locale: const Locale('ko')`, 한국어 ARB, widget test 한국어 문구 검증 |
| FR-19 | 영어 i18n 구조 | Done | `l10n.yaml`, `app_ko.arb`, `app_en.arb`, `AppLocalizations`, `supportedLocales` ko/en |

## Newly Done Since Previous Analysis

| Area | Status | Evidence |
|---|---|---|
| Flutter l10n 설정 | Done | `l10n.yaml`, `flutter: generate: true` |
| l10n dependencies | Done | `flutter_localizations`, `intl` |
| 한국어 ARB | Done | `lib/l10n/app_ko.arb` |
| 영어 ARB | Done | `lib/l10n/app_en.arb` |
| 생성된 localization API | Done | `lib/l10n/app_localizations.dart`, locale별 generated files |
| MaterialApp 연결 | Done | `localizationsDelegates`, `supportedLocales`, `onGenerateTitle` |
| 한국어 기본 locale 유지 | Done | `locale: const Locale('ko')` |
| 홈 공통 문자열 연결 | Done | 앱 이름, 로컬 기록, 이번 달, 월간 요약, 연차 관리 등 |
| widget test 보강 | Done | 기본 locale 한국어, 영어 locale 지원, l10n getter 검증 |
| P0 오늘 근무 기록 삭제 | Done | `WorkRecordRepository.deleteToday`, 오늘 기록 수정 화면의 확인 다이얼로그 |
| 이전 근무 기록 삭제 | Done | `WorkRecordRepository.deleteByDate`, 월간 요약 기록 목록의 삭제 액션과 확인 다이얼로그 |
| P0 연차 사용 내역 삭제 | Done | `LeaveRepository.deleteUsage`, 연차 관리 사용 내역 행의 삭제 액션 |
| 저장소 삭제 계약 | Done | `KeyValueStorage.delete`, `MemoryKeyValueStorage`, `PersistentKeyValueStorage` |

## Implemented Items

| Area | Status | Evidence |
|---|---|---|
| Core models | Done | `WorkRecord`, `LeaveBalance`, `LeaveUsage`, `PricingIntentEvent` |
| 모델 직렬화/검증 | Done | `copyWith`, `toMap`, `fromMap`, validation tests |
| Local storage abstraction | Done | `KeyValueStorage`, `delete`, persistent JSON storage, in-memory test adapter |
| 런타임 영속 저장소 연결 | Done | `main.dart`가 persistent JSON storage와 repositories 연결 |
| WorkRecord repository | Done | `findToday`, `findByMonth`, `clockIn`, `clockOut`, `updateToday`, `deleteToday`, `deleteByDate` |
| TodayWorkSummary | Done | 출근 전/근무 중/퇴근 후 상태 변환 |
| 홈 S-01/S-02/S-03 | Done | 홈 상태별 UI와 primary CTA |
| 홈 월간 preview | Done | 이번 달 총 근무와 남은 연차를 월간/연차 요약 계산값으로 표시 |
| 오늘 기록 수정 S-04 | Done | 시간, 태그, 메모 수정, 오늘 기록 삭제 |
| 월간 요약 S-05 | Done | 근무 합계, 근무일, 초과 참고, 태그별 참고, 연차 요약, 기록 목록, 이전 기록 삭제 |
| 연차 관리 S-06 | Done | 총 연차, 사용 추가, 사용 내역 삭제, 남은 연차, 초과 상태 |
| 가격 fake-door S-07 | Done | Report Pass/Pro 관심 이벤트와 MVP 안내 |
| Android persistent notification | Done | 권한 요청, 상시 알림, foreground/background action handler |
| Android build integration | Done | manifest permission/receiver, desugaring, multidex |
| 영어 i18n 구조 | Done | ko/en supported locales와 확장 가능한 ARB 구조 |
| 테스트 | Done | 삭제 기능 확장 후 `flutter test` 135개 통과 |

## Missing Items

기능 요구사항 기준으로 남은 gap은 없다.

| Priority | Remaining Process Item | Why It Remains |
|---:|---|---|
| P2 | 커밋 정리 | 현재 변경사항은 아직 커밋되지 않았다. 사용자 승인 후 기능 단위 커밋이 필요하다 |

## Partial Or Accepted Deviations

| Item | Status | Decision |
|---|---|---|
| Local storage implementation | Accepted deviation | 설계는 SQLite 계열 adapter 우선이지만 현재는 JSON key-value adapter다. MVP 데이터량과 월별 조회에는 충분하며 서버/클라우드 없이 로컬 저장 NFR을 충족한다 |
| 홈 빠른 보정 chip | Partial | mockup의 홈 tag chip은 완전한 quick action이 아니지만 S-04 수정 화면에서 태그/메모 보정이 가능하다 |
| 알림 설정 화면 | Deferred | 설계에는 설정/알림 권한 화면이 있으나 FR-04의 persistent notification action 자체는 구현됐다. 별도 설정 화면은 release polish로 분리 가능하다 |
| 전체 문자열 번역 | Accepted deviation | FR-19 범위는 영어 i18n 구조 준비다. 전체 화면의 완전 번역은 MVP 이후 확장 작업으로 둔다 |

## FR-19 i18n Check

| Requirement | Result | Evidence |
|---|---|---|
| Flutter l10n 구조 | Match | `l10n.yaml`, `lib/l10n/` |
| 한국어 기본 UI 유지 | Match | `locale: const Locale('ko')`, `app_ko.arb` |
| 영어 locale 구조 준비 | Match | `app_en.arb`, `Locale('en')` |
| MaterialApp localization 연결 | Match | `localizationsDelegates`, `supportedLocales` |
| 앱 타이틀 l10n 연결 | Match | `onGenerateTitle`, `AppLocalizations.appTitle` |
| 주요 공통 문자열 일부 연결 | Match | 홈 앱 이름, 로컬 기록, 이번 달, 요약/연차 label |
| widget test 영향 보정 | Match | `test/widget_test.dart`가 locale/l10n 구조 검증 |
| 새 기능 화면 추가 없음 | Match | l10n wiring과 테스트만 변경 |

## P0 Deletion Follow-up Check

| Requirement | Result | Evidence |
|---|---|---|
| 저장소 삭제 계약 | Match | `KeyValueStorage.delete({table, key})` |
| 메모리 저장소 삭제 | Match | `MemoryKeyValueStorage.delete`, test in-memory adapter delete |
| 영속 저장소 삭제 | Match | `PersistentKeyValueStorage.delete`, persistent delete tests |
| 오늘 기록 삭제 repository | Match | `WorkRecordRepository.deleteToday`, `LocalStorageWorkRecordRepository.deleteToday` |
| 오늘 기록 삭제 UI | Match | `EditTodayWorkRecordScreen`, `오늘 기록 삭제`, 확인 다이얼로그 |
| 오늘 기록 삭제 후 홈 갱신 | Match | 삭제 성공 시 `Navigator.pop(true)`로 홈 reload 경로 사용 |
| 이전 근무 기록 삭제 repository | Match | `WorkRecordRepository.deleteByDate`, `LocalStorageWorkRecordRepository.deleteByDate` |
| 이전 근무 기록 삭제 UI | Match | `MonthlySummaryScreen`, 기록 행 delete icon, 확인 다이얼로그 |
| 이전 근무 기록 삭제 후 월간 요약 갱신 | Match | 삭제 성공 후 `_loadSummary()` 재호출 |
| 연차 사용 삭제 repository | Match | `LeaveRepository.deleteUsage`, `LocalStorageLeaveRepository.deleteUsage` |
| 연차 사용 삭제 UI | Match | `LeaveManagementScreen`, 사용 내역 행 delete icon, 확인 다이얼로그 |
| 연차 사용 삭제 후 요약 갱신 | Match | 삭제 성공 후 `_loadSummary()` 재호출 |
| 삭제 취소 안전장치 | Match | widget test에서 취소 시 삭제 호출 없음 |

## FR-04 Notification Flow Check

| Requirement | Result | Evidence |
|---|---|---|
| 앱 진입 없이 출근 액션 기록 | Match | `handleWorkLedgerNotificationAction` -> `repository.clockIn()` |
| 앱 진입 없이 퇴근 액션 기록 | Match | `handleWorkLedgerNotificationAction` -> `repository.clockOut()` |
| 알림 action id 파싱 | Match | `parseWorkLedgerNotificationAction` |
| 알림 body tap은 홈 이동 | Match | `openHome()` callback, `navigatorKey.popUntil` |
| foreground action 처리 | Match | `_handleForegroundResponse` |
| background action 처리 | Match | `@pragma('vm:entry-point') workLedgerNotificationBackgroundHandler` |
| Android 13+ 알림 권한 | Match | `POST_NOTIFICATIONS`, `requestNotificationsPermission()` |
| 권한 거부 시 홈 기록 유지 | Match | 알림 표시만 건너뛰고 repository/app wiring은 유지 |
| action receiver 등록 | Match | `ActionBroadcastReceiver` |
| persistent notification 표시 | Match | `ongoing: true`, `autoCancel: false`, id `1001` |
| Quick Settings Tile 없음 | Match | 관련 구현 없음 |
| 홈 위젯 없음 | Match | 관련 구현 없음 |

## Pricing Fake-Door Check

| Requirement | Result | Evidence |
|---|---|---|
| `PricingIntentEvent` model | Match | `lib/core/models/pricing_intent_event.dart` |
| 리포트 버튼 클릭 이벤트 저장 | Match | `MonthlySummaryScreen._openPricingFakeDoor` |
| 가격표 화면 표시 | Match | `PricingFakeDoorScreen` |
| pricing screen viewed 저장 | Match | `_recordScreenViewed()` |
| Report Pass 클릭 이벤트 저장 | Match | `reportPassTapped`, `PricingPlan.reportPass` |
| Pro 클릭 이벤트 저장 | Match | `proPlanTapped`, `PricingPlan.pro` |
| fake-door 결과 안내 | Match | `관심을 기록했습니다. MVP 테스트 중인 기능입니다.` |
| 실제 결제 없음 | Match | 결제 SDK/결제 완료/영수증/구독 관리 없음 |
| 실제 PDF/CSV 생성 없음 | Match | export/generation 기능 없음 |

## 10-Second Clock Flow Check

| Requirement | Result |
|---|---|
| 앱 실행 시 오늘 기록 조회 | Match |
| 출근 전 `출근하기` 표시 | Match |
| 근무 중 `퇴근하기` 표시 | Match |
| 퇴근 후 완료 상태와 보조 액션 표시 | Match |
| CTA 탭 후 현재 시각으로 저장 | Match |
| 저장 후 홈 상태 갱신 | Match |
| 앱 종료 후에도 데이터 유지 | Match |
| 알림 액션으로 앱 진입 없이 기록 | Match |

## Scope Guard Check

다음 범위 밖 기능은 현재 코드에 들어오지 않았다.

- 서버
- 로그인
- 클라우드 sync
- GPS
- 회사 근태 시스템 연동
- 법정 연차 자동 계산
- 실제 결제
- 실제 PDF/CSV 생성
- Quick Settings Tile
- 홈 위젯
- 회사명, 위치, 민감 개인정보 필수 입력

검색 중 `회사명·위치 없이 시작합니다` 문구가 확인되었지만, 이는 회사명/위치 입력을 요구하지 않는다는 안내 문구이며 필수 입력 기능이 아니다.

## Runtime And Test Evidence

| Evidence | Result |
|---|---|
| `bkit_get_status` | phase `check`, progress `[Plan]✅ → [Design]✅ → [Do]✅ → [Check]🔄 → [Act]⏳` |
| `bkit_pdca_analyze` | analysis path `docs/03-analysis/workledger-mvp.analysis.md`, iterationCount `13` |
| `bkit_pre_write_check` | 문서 갱신 허용, plan/design 확인됨 |
| `flutter gen-l10n` | 직전 FR-19 구현 검증에서 완료 |
| `dart format lib test` | 삭제 기능 구현 파일과 관련 테스트 포맷 완료 |
| `flutter analyze` | 삭제 기능 구현 후 통과, `No issues found` |
| `flutter test` | 삭제 기능 확장 후 135개 통과 |
| `git --no-pager diff --check` | 삭제 기능 구현 후 통과 |

이번 변경은 P0 삭제 기능인 오늘 근무 기록 삭제와 연차 사용 내역 삭제에 더해 월간 요약의 이전 근무 기록 삭제를 추가했다. 구현 후 `dart format lib test`, `flutter analyze`, `flutter test`, `git --no-pager diff --check`를 재실행했다.

## Recommendation

기능 구현 기준으로는 Check/Report 진행이 가능하다. 다만 사용자 승인 없이 phase 완료 또는 커밋은 하지 않는다.

권장 순서:

1. 필요하면 emulator에서 오늘 기록 삭제, 이전 근무 기록 삭제, 연차 사용 삭제를 한 번 더 smoke test한다.
2. release readiness 문서에 삭제 기능 추가 검증 여부를 반영한다.
3. 사용자 승인 후 현재 feature 변경사항을 기능 단위로 커밋한다.
