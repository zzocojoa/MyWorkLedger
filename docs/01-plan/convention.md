# WorkLedger Convention

## Scope

이 문서는 `workledger-mvp`의 Phase 2 Flutter/Dart 개발 규칙이다. 기준 문서는 `docs/01-plan/features/workledger-mvp.plan.md`, 데이터 기준은 `docs/01-plan/schema.md`, 용어 기준은 `docs/01-plan/glossary.md`다.

MVP는 Android 우선 Flutter 앱이며 서버, 로그인, 클라우드 동기화, AI, GPS 자동 추적, 법정 연차 자동 계산, 실제 PDF/CSV 생성, 실제 결제를 포함하지 않는다.

## Language And Framework

| Area | Rule |
|---|---|
| Framework | Flutter Android 우선 |
| Language | Dart |
| Analyzer | `flutter_lints` 기반, `analysis_options.yaml` 규칙 준수 |
| UI language | 한국어 기본 |
| i18n | 영어 확장을 고려한 문자열 구조 준비 |
| Comments | 코드 주석은 한국어만 사용 |
| State | MVP에서는 단순 로컬 상태 관리 우선 |
| Storage | 로컬 저장소만 사용 |

## Directory Structure

기본 구조는 feature-first 방식으로 유지한다.

```text
lib/
├── main.dart
├── app/
│   ├── workledger_app.dart
│   └── app_routes.dart
├── core/
│   ├── errors/
│   ├── models/
│   ├── notifications/
│   ├── storage/
│   ├── time/
│   └── utils/
├── features/
│   ├── work_record/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── leave/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── monthly_summary/
│   │   ├── domain/
│   │   └── presentation/
│   ├── pricing/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── settings/
│       ├── domain/
│       └── presentation/
└── l10n/
```

## Folder Responsibilities

| Folder | Responsibility |
|---|---|
| `lib/app` | 앱 루트, 라우팅, 테마 연결 |
| `lib/core/models` | 여러 feature가 공유하는 순수 모델 |
| `lib/core/storage` | 로컬 저장 연결, table/key 이름, serialization 공통 처리 |
| `lib/core/notifications` | Android 상시 알림, 출근/퇴근 액션 연결 |
| `lib/core/errors` | 앱 공통 에러 타입 |
| `lib/core/time` | 날짜 정규화, 월 범위 계산, `Duration` 변환 |
| `lib/features/*/domain` | feature 전용 순수 계산, 상태 타입, 유효성 검사 |
| `lib/features/*/data` | feature 전용 저장소 adapter 또는 repository |
| `lib/features/*/presentation` | 화면, 위젯, 화면 상태 연결 |
| `lib/l10n` | 한국어 기본 문자열과 영어 확장 구조 |

## Naming Rules

| Element | Convention | Example |
|---|---|---|
| Dart files | snake_case | `work_record.dart` |
| Test files | source name + `_test.dart` | `work_record_test.dart` |
| Classes | PascalCase | `WorkRecord` |
| Enums | PascalCase | `WorkRecordTag` |
| Enum values | lowerCamelCase | `delayedCheckout` |
| Functions | lowerCamelCase | `calculateWorkedDuration` |
| Variables | lowerCamelCase | `workDate` |
| Constants | lowerCamelCase for scoped constants, UPPER_SNAKE only for platform constants | `minutesPerWorkDay`, `ANDROID_NOTIFICATION_ID` |
| Widgets | PascalCase with feature meaning | `TodayWorkRecordScreen` |
| Repositories | PascalCase + `Repository` | `WorkRecordRepository` |
| Storage adapters | PascalCase + `Storage` | `WorkRecordStorage` |
| Error types | PascalCase + `Exception` | `InvalidWorkRecordException` |
| Storage tables | snake_case plural | `work_records` |
| Storage columns | snake_case | `clock_in_at` |
| Storage keys | snake_case with feature prefix | `settings_notification_enabled` |

## Feature Naming

| Feature | Folder | Main Screen |
|---|---|---|
| 홈/오늘 기록 | `work_record` | `TodayWorkRecordScreen` |
| 기록 수정 | `work_record` | `EditWorkRecordScreen` |
| 연차 관리 | `leave` | `LeaveManagementScreen` |
| 월간 요약 | `monthly_summary` | `MonthlySummaryScreen` |
| 가격표/fake-door | `pricing` | `PricingScreen` |
| 설정/알림 권한 | `settings` | `SettingsScreen` |

## Dart Style Rules

- 모든 함수는 명시적 반환 타입을 가진다.
- 지역 변수는 가능한 `final`로 선언한다.
- `dynamic`은 사용하지 않는다.
- 컬렉션 타입은 구체적으로 작성한다. 예: `List<WorkRecord>`, `Map<String, Object?>`
- 함수 기본값은 사용하지 않는다. 모든 인자는 호출부에서 명시한다.
- flag 인자로 여러 모드를 바꾸는 함수는 만들지 않는다.
- 입력 객체를 수정하지 않는다. 새 값을 반환한다.
- 계산 로직은 widget 안에 두지 않는다.
- UI 위젯은 상태 표시와 사용자 입력 연결에 집중한다.
- import는 파일 상단에 모은다.

## Model Rules

모델은 불변 값 객체로 작성한다.

필수 구현:

- 모든 필드는 `final`
- 생성자는 모든 필드를 명시적으로 받는다
- `copyWith` 제공
- `toMap` 제공
- `fromMap` 제공
- `==`와 `hashCode`는 필요할 때 명시적으로 구현하거나 테스트 가능한 동등성 전략을 사용한다

금지:

- 모델 내부에서 저장소 접근 금지
- 모델 내부에서 현재 시각 생성 금지
- 모델 내부에서 UI 문자열 생성 금지
- 자동 법정 연차 계산 필드 추가 금지

모델 예시 책임:

| Model | Responsibility |
|---|---|
| `WorkRecord` | 근무일, 출근/퇴근, 태그, 메모, 생성/수정 시각 보관 |
| `LeaveBalance` | 연도별 총 연차 수동 입력값 보관 |
| `LeaveUsage` | 사용일과 사용 연차 분 단위 값 보관 |
| `PricingIntentEvent` | fake-door 클릭 이벤트 보관 |

## DateTime And Duration Rules

| Data | App Type | Storage Rule |
|---|---|---|
| 날짜 | `DateTime` normalized to local date | `YYYY-MM-DD` ISO-8601 date string |
| 시각 | `DateTime` | full ISO-8601 string |
| 기간 | `Duration` in logic | integer minutes in storage when persistence is needed |
| 연차량 | `int` minutes | integer minutes |

세부 규칙:

- 근무일은 로컬 날짜 기준으로 정규화한다.
- 저장 시 날짜만 필요한 값은 `YYYY-MM-DD` 형식을 사용한다.
- 저장 시 시각이 필요한 값은 ISO-8601 문자열을 사용한다.
- 근무시간 계산은 `Duration`으로 수행한다.
- 1일 연차 표시는 480분을 기준으로 한다.
- 잔여연차는 저장하지 않고 계산한다.

## Local Storage Naming

로컬 저장은 MVP에서 서버 없이 동작해야 한다. 구현 시 하나의 로컬 저장 방식을 선택하고 아래 이름을 유지한다.

| Entity | Table/Key | Unique Rule |
|---|---|---|
| `WorkRecord` | `work_records` | `work_date` unique |
| `LeaveBalance` | `leave_balances` | `year` unique |
| `LeaveUsage` | `leave_usages` | `id` unique |
| `PricingIntentEvent` | `pricing_intent_events` | `id` unique |
| 설정 | `settings_*` | key unique |

Column naming:

- snake_case만 사용한다.
- Dart 필드명과 의미가 1:1로 대응되게 한다.
- `DateTime` 필드는 `_at` suffix를 사용한다. 예: `clock_in_at`, `created_at`
- 날짜 필드는 `_date` 또는 명확한 도메인 이름을 사용한다. 예: `work_date`, `used_on`
- 분 단위 숫자는 `_minutes` suffix를 사용한다. 예: `total_leave_minutes`

## State Management Rules

MVP 상태 관리는 단순성을 우선한다.

| Scope | Rule |
|---|---|
| Screen-local state | `StatefulWidget` 또는 작은 controller 사용 |
| Derived values | 순수 함수로 계산 |
| Shared app state | 필요해질 때 `ChangeNotifier` 또는 `ValueNotifier` 사용 |
| Storage state | repository에서 async API로 노출 |
| Notification action | 저장소 호출 후 UI refresh가 가능한 구조로 분리 |

금지:

- 전역 mutable singleton에 앱 상태 저장 금지
- widget에서 직접 SQL/key-value serialization 작성 금지
- 계산 로직을 `build` 메서드에 직접 작성 금지
- 상태 관리 패키지 도입은 MVP 구현 중 실제 복잡도가 생긴 뒤 결정한다

## Error Type Rules

에러는 명시적 타입으로 구분한다.

| Error Type | Use Case |
|---|---|
| `WorkRecordValidationException` | 출퇴근 시각, 태그, 메모 검증 실패 |
| `LeaveValidationException` | 연차 연도, 사용 분 단위, 총 연차 검증 실패 |
| `PricingIntentValidationException` | fake-door 이벤트 타입/요금제 검증 실패 |
| `LocalStorageException` | 로컬 저장 읽기/쓰기 실패 |
| `NotificationPermissionException` | 알림 권한 또는 알림 설정 실패 |

에러 메시지 작성 규칙:

- 무엇이 실패했는지 한 문장으로 드러낸다.
- 디버깅 가능한 필드를 포함한다.
- 저장소 에러는 table/key, operation, original message를 포함한다.
- 검증 에러는 field, value, rule을 포함한다.
- catch-all로 삼키지 않는다.
- fallback은 사용자가 명시 요청한 경우만 둔다.

예시 형식:

```text
Invalid WorkRecord: field=clockOutAt, rule=must_be_after_clock_in, workDate=2026-06-12
Local storage write failed: table=work_records, operation=upsert, id=...
```

## Testing Rules

| Target | Test Type |
|---|---|
| 모델 serialization | unit test |
| 날짜/시간 계산 | unit test |
| 연차 잔여 계산 | unit test |
| 월간 요약 계산 | unit test |
| 화면 이름/기본 렌더링 | widget test |
| 알림 액션 | integration 또는 adapter 단위 test |

테스트 파일은 source 파일과 같은 feature 의미를 유지한다.

```text
test/core/models/work_record_test.dart
test/features/leave/domain/leave_summary_test.dart
test/features/monthly_summary/domain/monthly_summary_test.dart
```

## Commit Message Rules

형식:

```text
<type>: <description>
```

허용 type:

| Type | Use |
|---|---|
| `chore` | 초기 세팅, 도구 설정 |
| `docs` | 문서 변경 |
| `feat` | 사용자 기능 추가 |
| `fix` | 버그 수정 |
| `refactor` | 동작 변경 없는 구조 개선 |
| `test` | 테스트 추가/수정 |

규칙:

- description은 영어 소문자 명령형 문장으로 작성한다.
- 끝에 마침표를 붙이지 않는다.
- 한 커밋은 하나의 목적만 가진다.
- 초기 세팅, 스키마 문서, 컨벤션 문서, 기능 구현은 각각 분리한다.
- 사용자 승인 없이 커밋하지 않는다.

예시:

```text
docs: define WorkLedger MVP schema
docs: define Flutter development conventions
feat: add work record model
test: cover leave balance calculations
```

## Validation Commands

문서 또는 코드 변경 후 가능한 한 아래 명령을 실행한다.

```bash
$HOME/.local/share/flutter-stable/bin/flutter analyze
$HOME/.local/share/flutter-stable/bin/flutter test
```

## Phase 2 Decisions

| Decision | Value |
|---|---|
| 앱 구조 | feature-first |
| 모델 위치 | 공유 모델은 `lib/core/models`, feature 전용 모델은 `lib/features/*/domain` |
| 저장소 위치 | `lib/core/storage` 공통 연결, feature별 repository는 `lib/features/*/data` |
| 알림 위치 | `lib/core/notifications` |
| 기본 상태 관리 | screen-local state + pure functions |
| 날짜 저장 | 날짜는 `YYYY-MM-DD`, 시각은 ISO-8601 |
| 기간 저장 | 분 단위 정수 |
| 연차 계산 | 수동 총량과 사용량 기반 계산만 허용 |
| 결제 | fake-door 이벤트만 기록 |
