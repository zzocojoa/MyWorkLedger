# workledger-mvp - Design Document

> Version: 1.0.0 | Date: 2026-06-12 | Status: Draft  
> Level: Starter | Plan: `docs/01-plan/features/workledger-mvp.plan.md`

## 1. Overview

WorkLedger는 한국어 표시명 `내근무장부`를 사용하는 Flutter Android 우선 MVP다. 사용자는 계정 없이 앱을 시작하고, 앱 홈 또는 Android 상시 알림 액션으로 출근/퇴근을 빠르게 기록한다. 모든 핵심 데이터는 로컬 저장소에만 저장한다.

MVP의 핵심 검증은 다음 세 가지다.

| Goal | Design Implication |
|---|---|
| 10초 이내 출퇴근 기록 | 홈 화면의 출근/퇴근 버튼과 상시 알림 액션을 최상위 흐름으로 둔다 |
| 잔여연차 수동 관리 | 총 연차와 연차 사용량만 저장하고 잔여연차는 계산값으로 표시한다 |
| 가격표/fake-door 의향 측정 | 실제 결제 없이 클릭 이벤트만 로컬에 남긴다 |

## 2. Non-Goals

다음 항목은 설계와 구현에서 제외한다.

- 서버
- 로그인
- 클라우드 동기화
- AI
- GPS 자동 추적
- 회사 근태 시스템 연동
- 법률 자문
- 증거 효력 보장
- 법정 연차 자동 계산
- 실제 PDF/CSV 생성
- 실제 결제
- Quick Settings Tile
- 홈 위젯

## 3. Architecture Overview

```text
Flutter UI
  -> Screen State / Controllers
  -> Feature Use Cases and Pure Calculations
  -> Repositories
  -> Local Storage Adapter
  -> Android App Local Storage

Android Persistent Notification
  -> Notification Action Handler
  -> WorkRecord Repository
  -> Local Storage Adapter
```

## 4. Flutter Folder Structure

`docs/01-plan/convention.md`의 feature-first 구조를 따른다.

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

## 5. Model Implementation Plan

모델은 immutable 값 객체로 구현한다. 모든 모델은 `copyWith`, `toMap`, `fromMap`을 제공한다.

| Model | Location | Key Fields | Implementation Notes |
|---|---|---|---|
| `WorkRecord` | `lib/core/models/work_record.dart` | `id`, `workDate`, `clockInAt`, `clockOutAt`, `tags`, `memo`, `createdAt`, `updatedAt` | `workDate`별 1개 기록, 태그 중복 금지 |
| `LeaveBalance` | `lib/core/models/leave_balance.dart` | `id`, `year`, `totalLeaveMinutes`, `createdAt`, `updatedAt` | 법정 연차 자동 계산 없음 |
| `LeaveUsage` | `lib/core/models/leave_usage.dart` | `id`, `usedOn`, `usedLeaveMinutes`, `memo`, `createdAt`, `updatedAt` | 연차량은 분 단위 정수 |
| `PricingIntentEvent` | `lib/core/models/pricing_intent_event.dart` | `id`, `eventType`, `selectedPlan`, `sourceScreen`, `occurredAt`, `createdAt` | 실제 결제 상태 아님 |

## 6. Local Storage Design

MVP 구현 시 로컬 저장소 하나를 선택한다. 초기 구현은 구조적 쿼리와 월간 조회가 필요하므로 SQLite 계열 adapter를 우선한다.

| Table | Columns | Index |
|---|---|---|
| `work_records` | `id`, `work_date`, `clock_in_at`, `clock_out_at`, `tags`, `memo`, `created_at`, `updated_at` | unique `work_date` |
| `leave_balances` | `id`, `year`, `total_leave_minutes`, `created_at`, `updated_at` | unique `year` |
| `leave_usages` | `id`, `used_on`, `used_leave_minutes`, `memo`, `created_at`, `updated_at` | `used_on` |
| `pricing_intent_events` | `id`, `event_type`, `selected_plan`, `source_screen`, `occurred_at`, `created_at` | `occurred_at` |

Serialization rules:

- 날짜는 `YYYY-MM-DD` 문자열로 저장한다.
- 시각은 ISO-8601 문자열로 저장한다.
- 기간과 연차량은 분 단위 정수로 저장한다.
- 태그 목록은 MVP에서 문자열 목록으로 직렬화한다.
- 잔여연차, 월간 합계, 근무시간 합계는 저장하지 않고 계산한다.

## 7. 10-Second Clock Flow

### App Home Flow

```text
앱 실행
  -> 오늘 WorkRecord 조회
  -> 출근 전이면 [출근하기] primary CTA 표시
  -> 출근 후 퇴근 전이면 [퇴근하기] primary CTA 표시
  -> 퇴근 후이면 오늘 기록 완료 상태와 보조 액션 표시
  -> primary CTA 탭
  -> 현재 시각으로 WorkRecord upsert
  -> 홈 상태 갱신
```

Rules:

- 오늘 날짜의 `WorkRecord`가 없으면 버튼 탭 시 새로 생성한다.
- 출근 기록은 `clockInAt`을 현재 시각으로 저장한다.
- 퇴근 기록은 `clockOutAt`을 현재 시각으로 저장한다.
- `clockOutAt < clockInAt`이면 저장하지 않고 검증 에러를 표시한다.
- 메모는 기록 수정 화면에서 보정한다.
- 하루 전체를 `야근`이나 `휴일근무`로 분류하는 태그는 근무 태그 계산 근거로 사용하지 않는다.
- 홈 화면은 `docs/02-design/mockup.md`의 출근 전, 근무 중, 퇴근 후 3개 상태를 따른다.

### Optional Work Rule Setup

근무 기준 설정은 근무 태그 계산에 필요하지만 첫 실행 필수 등록으로 두지 않는다. 앱의 핵심 가치는 10초 출퇴근 기록이므로, 사용자는 설정 없이도 바로 출근/퇴근 기록을 시작할 수 있어야 한다.

```text
첫 퇴근 완료 또는 월간 요약 진입
  -> 근무 기준 미설정 확인
  -> 정시 출근/정시 퇴근/휴게시간/평일 근무 요일 설정 제안
  -> 나중에 선택 시 총 근무시간만 유지
  -> 저장 시 이후 기록부터 근무 태그 표시
```

Work rule fields:

| Field | Purpose |
|---|---|
| 정시 출근 | 사용자가 기대하는 평일 기본 출근 시각 |
| 정시 퇴근 | 사용자가 기대하는 평일 기본 퇴근 시각 |
| 휴게시간 | 총 근무시간에서 제외할 사용자 기준 시간 |
| 평일 근무 요일 | 휴무일 근무 판단 기준 요일 |

Rules:

- 기본 추천값을 제공할 수 있지만 저장은 사용자가 명시적으로 선택해야 한다.
- 설정이 없으면 근무 태그를 계산하지 않는다.
- 이 설정은 회사 근태 규칙이나 확정 기준의 정확성을 보장하지 않는다.

### Non-Workday, Early, Overtime And Night Work Tag Rules

근무 태그는 수동 태그가 아니라 근무 기준과 실제 출퇴근 시각으로 계산되는 구간이다.

| Work Tag | Rule |
|---|---|
| 휴무일 근무 | 사용자가 평일 근무 요일로 선택하지 않은 날짜의 휴게시간 제외 근무 구간 |
| 정시 전 근무 | 근무 기준의 정시 출근 이전 실제 근무 구간 |
| 연장 근무 | 근무 기준의 정시 퇴근 이후 실제 근무 구간 |
| 야간 근무 | 실제 근무 구간 중 22:00-06:00과 겹치는 구간 |
| 기록 지연 | 실제 추가 근무가 아니라 퇴근 버튼을 늦게 누른 사유 |

Rules:

- 휴무일 근무, 정시 전 근무, 연장 근무, 야간 근무는 겹칠 수 있으므로 하나의 값으로 합치지 않는다.
- 휴무일 근무는 날짜 성격의 태그이고, 정시 전/연장/야간 근무는 시간대 성격의 태그이므로 별도 항목으로 표시한다.
- 휴무일 기록도 정시 출근 이전 구간, 정시 퇴근 이후 구간, 야간 구간이 있으면 각각 태그로 함께 표시한다.
- 근무 기준이 설정된 경우 총 근무 표시 시간은 근무 요일 여부와 관계없이 휴게시간을 제외한다.
- 사용자가 `기록 지연`을 선택하면 해당 퇴근 시각은 신뢰하기 어려우므로 정시 퇴근 이후 연장 근무와 야간 근무에서 제외한다.
- 사용자가 `기록 지연`을 선택한 휴무 요일 기록은 퇴근 시각을 신뢰하기 어려우므로 휴무일 근무에서도 제외한다.
- `기록 지연`을 선택해도 출근 시각은 그대로 신뢰할 수 있으므로 정시 전 근무는 계산할 수 있다.
- 월간 요약에서는 `근무 태그`, `휴무일 근무`, `정시 전 근무`, `연장 근무`, `야간 근무`처럼 짧은 화면 문구를 사용한다.
- 월간 요약에서는 긴 참고/주의 문구를 반복 표시하지 않는다.
- 월간 요약에서는 0분 근무 태그 항목을 숨긴다.
- 근무 기준이 없거나 모든 근무 태그가 0분이면 근무 태그 결과 카드를 표시하지 않는다.
- MVP 현재 구현의 `WorkRecordTag`는 기존 저장 데이터 호환과 기록 사유 표시를 위해 유지하고, 월간 요약의 근무 태그 계산 근거로는 사용하지 않는다.

### Post-MVP Follow-up: Fixed Included Work Time Reference

고정 포함 시간 비교는 `workledger-mvp` 완료 범위가 아니라 후속 개선 후보로 둔다. 목적은 계약 형태를 판단하는 것이 아니라 사용자가 앞으로 참고할 비교 방식을 직접 고르는 것이다.

Data boundary:

| Item | Design |
|---|---|
| 저장 모델 | `CompensationReferenceSetting` |
| 설정 모드 | `none`, `fixedIncluded`, `unknown` |
| 포함 시간 | `fixedIncludedOvertimeMinutes`, `fixedIncludedNightMinutes`, `fixedIncludedHolidayMinutes` |
| 적용 범위 | 적용 시작 월 입력 없이 전체 데이터 기준 |
| 기록 연결 | `WorkRecord`에는 고정 포함 시간 여부를 저장하지 않음 |

Calculation policy:

```text
월간 요약 로드
  -> 선택 월 WorkRecord 목록 조회
  -> 활성 WorkRule 조회
  -> 현재 CompensationReferenceSetting 1건 조회
  -> 기존 WorkRecord + WorkRule 기반 근무 태그 시간 계산
  -> 월간 요약에는 고정 포함 시간 비교 컨테이너를 표시하지 않음
```

Rules:

- 사용자가 근무 기록을 먼저 남긴 뒤 나중에 `고정 포함 시간 있음`을 켜도 기존 `WorkRecord`는 수정하지 않는다.
- 설정 변경은 기존 기록을 수정하지 않고 전체 데이터 기준 설정으로 저장한다. 기록 마이그레이션은 하지 않는다.
- 고정 포함 시간 입력값은 0 이상이어야 하며 30분 단위를 권장한다.
- 적용 시작 월은 사용자에게 입력받지 않는다.
- `unknown` 상태는 저장할 수 있지만 별도 안내 컨테이너를 월간 요약에 표시하지 않는다.
- 확정값, 분쟁 판단, 청구 안내, 전문 자문, 회사 근태 정확성 보장은 하지 않는다.

## 8. Persistent Notification Action Design

상시 알림은 사용자가 켠 경우에만 유지한다. Android 알림 권한이 거부되어도 앱 홈의 1탭 기록은 계속 동작해야 한다.

| Action | Behavior |
|---|---|
| `clock_in` | 오늘 `WorkRecord.clockInAt`을 현재 시각으로 저장 |
| `clock_out` | 오늘 `WorkRecord.clockOutAt`을 현재 시각으로 저장 |
| Notification tap | 앱 홈/오늘 기록 화면으로 이동 |

Implementation boundary:

- `lib/core/notifications`는 Android 알림 설정과 action payload만 담당한다.
- 저장은 `WorkRecordRepository`를 통해 수행한다.
- 알림 권한 문제는 `NotificationPermissionException`으로 처리한다.
- 상시 알림은 Quick Settings Tile 또는 홈 위젯을 대체하지 않는다.

## 9. Leave Flow

### Manual Balance

```text
설정 > 총 연차
  -> 기준 연도 확인
  -> 총 연차 입력
  -> LeaveBalance 저장
```

### Usage

```text
연차 사용 추가
  -> 사용 날짜 선택
  -> 사용량 입력
  -> LeaveUsage 저장
  -> 잔여연차 재계산
```

Calculation:

```text
usedLeaveMinutes = sum(LeaveUsage.usedLeaveMinutes for year)
remainingLeaveMinutes = LeaveBalance.totalLeaveMinutes - usedLeaveMinutes
```

Rules:

- 1일은 480분으로 표시한다.
- 연차 사용량은 30분 단위로 저장한다.
- 사용량 합계가 총 연차를 초과해도 저장은 막지 않고 초과 상태를 표시한다.
- 법정 연차, 입사일, 회계연도 자동 계산은 하지 않는다.

## 10. Monthly Summary Flow

```text
월간 요약 화면
  -> 선택 월의 WorkRecord 목록 조회
  -> 선택 월의 LeaveUsage 목록 조회
  -> 기준 연도 LeaveBalance 조회
  -> 휴게시간 제외 근무시간/선택형 근무 태그/연차 요약 계산
```

Summary values:

| Value | Rule |
|---|---|
| 월간 근무시간 | `clockInAt`과 `clockOutAt`이 모두 있는 기록의 `Duration` 합계 |
| 월간 근무 태그 | 근무 기준 설정이 있을 때 0분 초과 휴무일 근무, 정시 전 근무, 연장 근무, 야간 근무만 별도 표시 |
| 연차 사용량 | 선택 월 `LeaveUsage.usedLeaveMinutes` 합계 |
| 잔여연차 | 연도 총량에서 연도 사용량 합계 차감 |

근무 기준이 설정되지 않은 경우에는 총 근무시간만 표시하고 근무 태그를 계산하지 않는다. 홈의 이번 달 preview도 월간 요약과 같은 휴게시간 제외 표시용 총 근무시간을 사용한다.

post-MVP에서 `CompensationReferenceSetting`이 추가되더라도 현재 월간 요약 화면에는 고정 포함 시간 비교 컨테이너를 표시하지 않는다. 설정은 기존 `WorkRecord` 원본과 MVP의 근무시간 합계나 근무 태그 계산 규칙을 바꾸지 않는다.

## 11. Pricing Fake-Door Flow

```text
월간 요약
  -> [월간 리포트 만들기] 탭
  -> PricingIntentEvent(reportButtonTapped) 저장
  -> 가격표 화면 이동
  -> PricingIntentEvent(pricingScreenViewed) 저장
  -> [Report Pass] 또는 [Pro] 탭
  -> PricingIntentEvent(reportPassTapped/proPlanTapped) 저장
  -> fake-door 결과 안내
```

Rules:

- 실제 결제 SDK를 붙이지 않는다.
- 실제 PDF/CSV를 만들지 않는다.
- 이벤트는 로컬에만 저장한다.
- 결과 안내는 “MVP 테스트 중인 기능” 취지로 표현하고 법률/증거 효력 표현은 피한다.

## 12. Screen List

상세 화면 목록은 `docs/02-design/screen-list.md`에 둔다.

| Screen | Purpose |
|---|---|
| 홈/오늘 기록 | 오늘 출근/퇴근 1탭 기록 |
| 기록 수정 | 출근/퇴근 시각, 기록 사유, 메모 보정 |
| 달력 보기 | 이번 달 날짜별 근무 기록 유무와 완료/미완료 상태 확인 |
| 연차 관리 | 연차 사용 기록 추가/삭제 |
| 월간 요약 | 월간 근무/선택형 근무 태그/연차 요약 |
| 가격표/fake-door | Report Pass/Pro 클릭 의향 측정 |
| 설정 | 근무 기준, 비교 방식, 총 연차, 알림 설정 |

## 13. User Flow

상세 사용자 흐름은 `docs/02-design/user-flow.md`에 둔다.

```text
앱 실행
  -> 홈/오늘 기록
  -> 출근하기 또는 퇴근하기
  -> 필요 시 기록 수정
  -> 퇴근 후 달력 보기에서 날짜별 기록 확인
  -> 월간 요약
  -> 월간 리포트 만들기
  -> 가격표/fake-door
```

```text
설정/알림 권한
  -> 상시 알림 켜기
  -> 알림 액션으로 출근/퇴근 기록
  -> 홈 화면에서 결과 확인
```

## 14. Low-Risk ASCII Wireframes

상세 와이어프레임은 `docs/02-design/mockup.md`에 둔다. 구현 시에는 아래 원칙을 따른다.

- 홈은 출근 전, 근무 중, 퇴근 후 3개 상태로 분기한다.
- 화면당 primary CTA는 하나만 둔다.
- 기본 화면은 흰 캔버스와 진한 잉크 CTA를 사용한다.
- 월간 요약, 잔여연차, 가격 fake-door 강조 영역에만 코럴/포레스트/다크 표면을 제한적으로 사용한다.
- 가격 fake-door 화면은 실제 결제 대신 `PricingIntentEvent`만 저장한다.

```text
+--------------------------------+
| 내근무장부              [설정] |
+--------------------------------+
| 오늘 · 6월 12일 금요일         |
| 현재 상태 카드                 |
| [출근하기 또는 퇴근하기]       |
| 보조 액션과 요약 카드          |
+--------------------------------+
| [월간 요약] [연차 관리]        |
+--------------------------------+
```

## 15. Error Types And Validation

| Error Type | Trigger |
|---|---|
| `WorkRecordValidationException` | 퇴근 시각이 출근 시각보다 빠름, 태그 중복, 메모 길이 초과 |
| `LeaveValidationException` | 연차 연도 범위 오류, 30분 단위 위반, 음수 총량 |
| `PricingIntentValidationException` | 이벤트 타입과 선택 요금제 조합 오류 |
| `LocalStorageException` | 로컬 저장 읽기/쓰기 실패 |
| `NotificationPermissionException` | 알림 권한 또는 상시 알림 설정 실패 |

Validation messages must include `field`, `value`, and `rule` when possible.

## 16. Test Plan

| Area | Tests |
|---|---|
| Model serialization | `WorkRecord`, `LeaveBalance`, `LeaveUsage`, `PricingIntentEvent` `toMap/fromMap` |
| Validation | 출퇴근 시각, 태그 중복, 연차량 단위, 가격 이벤트 조합 |
| Date/time utilities | 날짜 정규화, 월 범위 계산, `Duration` 합산 |
| Leave calculations | 사용 연차 합계, 잔여연차, 초과 사용 표시 |
| Monthly summary | 근무시간 합계, 근무 기준 미설정 시 근무 태그 미표시, 근무 기준 설정 시 근무 태그 분리 표시 |
| Notification adapter | 권한 거부, action payload, repository 호출 경계 |
| Widget smoke | 홈, 연차, 월간 요약, 가격표, 설정 화면 기본 렌더링 |

## 17. Implementation Order

1. Core model and validation types
2. Date/time utility functions
3. Local storage adapter and repositories
4. WorkRecord home flow
5. Edit WorkRecord flow
6. Leave balance and usage flow
7. Monthly summary calculations
8. Pricing fake-door event flow
9. Persistent notification action integration
10. Screen-level widget tests and calculation unit tests

## 18. Design Completion Criteria

- 필수 모델 구현 계획이 문서화되어 있다.
- 로컬 저장소 table/key/column 규칙이 문서화되어 있다.
- 핵심 사용자 흐름과 화면 목록이 문서화되어 있다.
- 알림 액션과 권한 거부 대응이 문서화되어 있다.
- MVP 제외 범위가 설계에 반영되어 있다.
- 테스트 계획이 구현 순서와 연결되어 있다.

## 19. Post-MVP Design Notes

`fixed-included-work-time`은 후속 feature 후보로 분리한다. 구현 전에는 별도 plan/design/check를 만들고, 기존 `workledger-mvp` Match Rate 100% 기준에 섞지 않는다.

후속 구현 시 지켜야 할 제한은 다음과 같다.

- 새 설정은 로컬 저장소에만 저장한다.
- 서버, 로그인, 클라우드 동기화, GPS는 추가하지 않는다.
- 실제 PDF/CSV, 실제 결제, 확정값 계산, 전문 자문은 추가하지 않는다.
- 기존 `WorkRecord` 데이터를 변경하지 않고 월간 요약 계산 시점에만 비교한다.
