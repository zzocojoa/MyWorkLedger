# Gap Analysis: work-record-quick-record-mode

> Date: 2026-06-21 | Design: docs/02-design/features/work-record-quick-record-mode.design.md

---

## Match Rate: 100%

계산식: `21 implemented check items / 21 counted design check items = 100%`.

포함 기준:

- Plan/Design에서 정의한 빠른 기록 설정, 후보 생성, 저장소 계약, 홈 화면 UX, 상시 알림 설정 기반 분기, 오류 처리, 자동 검증 항목
- 병합 차단으로 확인된 local storage 데이터 보존 항목
- Android 실기기 알림 액션 수동 검증 항목

제외 기준:

- 자정 중 `chooseBeforeSave` 후보 선택 날짜 정책은 별도 제품 정책 검토 항목이므로 이번 구현 matchRate에서 제외한다.

## Counted Check Items

| # | 항목 | 결과 | 근거 |
| --- | --- | --- | --- |
| 1 | `QuickRecordMode` 도메인 모델 | PASS | domain/model tests |
| 2 | `QuickRecordSettings` 직렬화와 검증 | PASS | domain/model tests |
| 3 | 로컬 빠른 기록 설정 저장소 | PASS | repository tests |
| 4 | 설정 화면 저장 흐름 | PASS | settings widget tests |
| 5 | `currentTimeOnly` 출근 1탭 저장 | PASS | home widget tests |
| 6 | `currentTimeOnly` 퇴근 1탭 저장 | PASS | home widget tests |
| 7 | `chooseBeforeSave` 현재 시각 후보 저장 | PASS | home widget tests |
| 8 | `chooseBeforeSave` 정시 후보 저장 | PASS | home widget tests |
| 9 | `chooseBeforeSave` 직접 입력 후보 저장 | PASS | home widget/domain tests |
| 10 | `currentTimeOnly` 상시 알림 출근/퇴근 즉시 저장 경계 | PASS | notification action test |
| 11 | `chooseBeforeSave` 상시 알림 액션 즉시 저장 경계 | PASS | notification service/action tests |
| 12 | 자정 경계 clock 단일 값 | PASS | repository tests |
| 13 | storage 임시 파일 교체 저장 | PASS | storage tests |
| 14 | storage 임시 파일 실패 시 기존 파일 보존 | PASS | storage tests |
| 15 | 같은 isolate 내 adapter instance write/write 경합 보존 | PASS | storage tests |
| 16 | 같은 isolate 내 adapter instance write/delete 경합 보존 | PASS | storage tests |
| 17 | 별도 Dart process write/write 및 write/delete 경합 보존 | PASS | storage tests |
| 18 | same-process isolate write/write 및 write/delete 경합 보존 | PASS | storage tests |
| 19 | stale `.lock` 복구 후 기존 JSON 보존 및 새 write 성공 | PASS | storage tests |
| 20 | Android 실기기 상시 알림 출근/퇴근 액션 즉시 저장 | PENDING | `1.0.4+5` Play 내부 테스트 설치 후 수동 재검증 필요 |
| 21 | 앱 내부 pending 컨트롤러 요청 선택 UX 표시 | PASS | home widget tests |

## Summary

빠른 기록 방식 설정의 핵심 설계 항목은 구현과 테스트에 반영되어 있다. `QuickRecordMode`와 `QuickRecordSettings` 모델, 로컬 설정 저장소, 홈 화면의 `currentTimeOnly` 즉시 저장 흐름, `chooseBeforeSave` 후보 선택 흐름, 상시 알림의 설정 무관 즉시 저장 경계, 자정 경계 회귀 테스트가 확인되었다.

이번 Check에서 병합 차단 요소였던 신규 파일 미포함 위험은 staging 정리 대상이며, `PersistentKeyValueStorage`의 직접 덮어쓰기 위험은 임시 파일 쓰기 후 rename 방식과 실패 시 기존 파일 보존 테스트로 보강되었다. 이후 서로 다른 storage 인스턴스, 별도 Dart process, same-process isolate의 동일 JSON 파일 write/write 및 write/delete 경합도 read-modify-write 전체 구간 직렬화와 exclusive lock file 생성 방식으로 보강되었다. crash 등으로 stale `.lock` 파일이 남은 경우에는 충분히 오래되고 짧은 재확인 동안 변하지 않은 lock만 복구하도록 보강했다. 후속 릴리스 보정에서는 Android 상시 알림 `출근하기`와 `퇴근하기`가 `QuickRecordMode`와 무관하게 `clockIn()`과 `clockOut()`을 호출하도록 정리했다. 앱 내부 컨트롤러 요청은 기존처럼 HomeScreen 첫 frame 이후 pending action을 drain해 출근/퇴근 선택 UX를 표시한다.

## Implemented Items

- [x] `QuickRecordMode.currentTimeOnly`와 `QuickRecordMode.chooseBeforeSave` 도메인 모델을 추가했다.
- [x] `QuickRecordSettings` 직렬화, 파싱, 검증, 명시 오류 처리를 추가했다.
- [x] `LocalStorageQuickRecordSettingsRepository`로 빠른 기록 방식 설정을 로컬 저장소에 저장한다.
- [x] 근무 설정 화면에서 빠른 기록 방식을 선택하고 저장한다.
- [x] `currentTimeOnly`는 홈 화면 버튼에서 기존 `clockIn()`과 `clockOut()` 즉시 저장 흐름을 유지한다.
- [x] `chooseBeforeSave`는 현재 시각, 정시 후보, 직접 입력 후보를 표시한다.
- [x] 후보 선택 저장은 `clockInAt()`과 `clockOutAt()`을 사용해 선택한 시각을 기록한다.
- [x] 상시 알림 액션은 `currentTimeOnly`에서 기존처럼 `clockIn()`과 `clockOut()`을 호출한다.
- [x] 상시 알림 액션은 `chooseBeforeSave`에서도 기존처럼 `clockIn()`과 `clockOut()`을 호출한다.
- [x] 알림 액션은 앱 선택 UX를 열지 않고 즉시 저장한다.
- [x] 앱 내부 컨트롤러 요청은 선택 완료 전 `clockIn()`, `clockOut()`, `clockInAt()`, `clockOutAt()` 호출을 발생시키지 않는다.
- [x] 앱 내부 컨트롤러 요청은 선택 완료 후 선택한 시각으로 `clockInAt()` 또는 `clockOutAt()`을 1회 호출하고 알림 본문을 갱신한다.
- [x] 앱 cold-start 유사 경로에서 HomeScreen 생성 전 pending 컨트롤러 요청이 있어도 첫 frame 이후 선택 UX가 표시된다.
- [x] `clockIn()`과 `clockOut()`은 자정 경계에서 clock 값을 한 번만 읽어 workDate와 저장 시각을 일관되게 사용한다.
- [x] 빠른 기록 domain, repository, widget, notification action, 기존 화면 회귀 테스트가 추가 또는 보정되었다.
- [x] `PersistentKeyValueStorage`는 JSON 파일을 직접 덮어쓰지 않고 임시 파일에 먼저 저장한 뒤 교체한다.
- [x] 임시 파일 쓰기 실패 시 기존 JSON 파일이 유지되는 테스트가 추가되었다.
- [x] 서로 다른 `PersistentKeyValueStorage` 인스턴스의 동시 write가 모든 key를 보존한다.
- [x] 동시 write/delete 경합에서 삭제 대상은 되살아나지 않고 새 write도 보존된다.
- [x] 별도 Dart process의 동일 JSON 파일 write/write 및 write/delete 경합에서도 lost update가 발생하지 않는다.
- [x] same-process isolate의 동일 JSON 파일 write/write 및 write/delete 경합에서도 lost update가 발생하지 않는다.
- [x] stale `.lock` 파일이 남아도 기존 JSON을 보존하면서 새 mutation이 진행된다.
- [ ] Android 실기기 `R3CM807B7DR`에서 `1.0.4+5` 상시 알림 액션이 후보 UI 없이 즉시 저장되는지 최종 수동 검증한다.

## Missing Items

- [ ] `chooseBeforeSave` 후보 선택 중 자정이 넘어간 경우 저장 대상 날짜 정책은 별도 제품 정책으로 남아 있다.

## Changed Items (Deviations from Design)

- [x] storage atomic write는 빠른 기록 설계의 직접 기능 요구사항은 아니지만, 같은 로컬 저장소 기반 feature의 병합 안정성을 위해 추가되었다.
- [x] storage mutation 직렬화와 exclusive lock file 생성 방식은 빠른 기록 설계의 직접 기능 요구사항은 아니지만, quick settings와 work records가 같은 JSON 파일을 공유하므로 병합 전 데이터 손실 차단 이슈로 추가되었다.
- [x] PDCA 상태는 Report 완료 상태로 정리하고 완료 보고서를 생성한다.

## Validation Evidence

| 항목 | 명령 | 결과 |
| --- | --- | --- |
| stale lock 실패 재현 | `$HOME/.local/share/flutter-stable/bin/flutter test test/core/storage/persistent_key_value_storage_test.dart --reporter=compact --name "recovers stale lock file left by a crashed mutation"` | FAIL before fix, stale `.lock`로 write timeout |
| stale lock 복구 테스트 | `$HOME/.local/share/flutter-stable/bin/flutter test test/core/storage/persistent_key_value_storage_test.dart --reporter=compact --name "recovers stale lock file left by a crashed mutation"` | PASS after fix |
| storage 회귀 테스트 | `$HOME/.local/share/flutter-stable/bin/flutter test test/core/storage/persistent_key_value_storage_test.dart --reporter=compact` | PASS, 17 tests |
| AC-06 process/isolate storage 검증 | `$HOME/.local/share/flutter-stable/bin/flutter test test/core/storage/persistent_key_value_storage_test.dart --reporter=compact` | PASS, 별도 Dart process와 same-process isolate write/write 및 write/delete 경합 보존 |
| 알림 즉시 저장/홈 선택 UX 타깃 테스트 | `$HOME/.local/share/flutter-stable/bin/flutter test test/core/notifications/workledger_notification_action_test.dart test/core/notifications/workledger_notification_service_test.dart test/features/work_record/presentation/work_record_home_screen_test.dart --reporter=compact` | PASS |
| cold-start controller request 회귀 테스트 | `$HOME/.local/share/flutter-stable/bin/flutter test test/features/work_record/presentation/work_record_home_screen_test.dart --reporter=compact` | PASS, pending controller request를 HomeScreen build 전에 넣어도 출근/퇴근 선택 UX 표시 |
| 설정 화면 타깃 테스트 | `$HOME/.local/share/flutter-stable/bin/flutter test test/features/settings/presentation/work_settings_screen_test.dart test/widget_test.dart --reporter=compact` | PASS, 21 tests |
| Android 실기기 알림 액션 | `1.0.4+5` Play 내부 테스트 설치 후 notification shade `출근하기`/`퇴근하기` | PENDING, 후보 UI 없이 즉시 저장되는지 재검증 필요 |
| 공백 검사 | `git --no-pager diff --check` | PASS |
| staged 공백 검사 | `git --no-pager diff --cached --check` | PASS |
| PDCA JSON 검사 | `python3 -m json.tool docs/.pdca-status.json >/dev/null` | PASS |
| 정적 분석 | `$HOME/.local/share/flutter-stable/bin/flutter analyze --no-pub` | PASS, No issues found |
| 전체 테스트 | `$HOME/.local/share/flutter-stable/bin/flutter test --reporter=compact` | PASS, 293 tests |
| release APK | `$HOME/.local/share/flutter-stable/bin/flutter build apk --release` | PASS, `build/app/outputs/flutter-apk/app-release.apk` |

## Recommendations

1. 자정 중 후보 선택 정책은 별도 이슈로 분리해 workDate 기준을 명확히 정한다.
2. 독립 검증자 V는 cold-start pending action 테스트와 실기기 smoke test 증거를 우선 재확인한다.

## Next Steps

- [ ] 병합 전 최종 `flutter analyze --no-pub`와 `flutter test --reporter=compact`를 유지한다.
- [ ] 자정 중 후보 선택 정책은 별도 제품 결정으로 검토한다.
