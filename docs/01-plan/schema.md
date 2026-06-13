# WorkLedger Schema

## Scope

이 문서는 `workledger-mvp`의 Phase 1 데이터 모델 기준이다. 모든 핵심 데이터는 계정 없이 로컬 저장소에만 저장한다. 서버, 로그인, 클라우드 동기화, GPS 자동 추적, 자동 법정 연차 계산, 실제 결제, 실제 PDF/CSV 생성은 포함하지 않는다.

## Storage Principles

- 저장소는 Flutter 앱 내부 로컬 저장소를 기준으로 한다.
- 날짜와 시각은 앱 코드에서 `DateTime`으로 다루고 저장 시 ISO-8601 문자열 또는 epoch milliseconds 중 하나로 일관되게 직렬화한다.
- 근무시간 계산은 저장값이 아니라 `clockInAt`, `clockOutAt`에서 파생한다.
- 잔여연차는 저장하지 않고 `LeaveBalance.totalLeaveMinutes - sum(LeaveUsage.usedLeaveMinutes)`로 계산한다.
- 연차량은 부동소수점 오차를 피하기 위해 분 단위 정수로 저장한다. 표시 시 1일을 480분으로 환산한다.
- 가격 의향 이벤트는 실제 결제 이벤트가 아니라 fake-door 클릭 로그다.
- 고정 포함 시간 비교 설정은 근무 기록과 분리한다. 설정 변경은 기존 `WorkRecord`를 수정하지 않고 월간 요약 계산 시점에만 반영한다.

## Entity Summary

| Entity | Purpose | Cardinality |
|---|---|---|
| `WorkRecord` | 날짜별 출근/퇴근/기록 사유/메모 기록 | 근무일 1개당 최대 1개 |
| `LeaveBalance` | 연도별 총 연차 수동 입력값 | 연도 1개당 최대 1개 |
| `LeaveUsage` | 날짜별 연차 사용 기록 | 연도별 0개 이상 |
| `PricingIntentEvent` | 가격표/fake-door 클릭 로그 | 제한 없음 |
| `CompensationReferenceSetting` | 고정 포함 시간 비교용 후속 설정 | 적용 시작 월 1개당 최대 1개 |

## Enum Definitions

### WorkRecordTag

| Value | Korean Label | Meaning |
|---|---|---|
| `overtime` | 야근 | 기존 저장 데이터 호환 값. 월간 근무 태그 계산 근거로 사용하지 않는다 |
| `delayedCheckout` | 퇴근 기록 지연 | 퇴근 버튼을 늦게 누른 기록 사유 |
| `holidayWork` | 휴일근무 | 기존 저장 데이터 호환 값. 휴무일 근무는 근무 기준 요일로 계산한다 |

### PricingIntentEventType

| Value | Meaning |
|---|---|
| `reportButtonTapped` | 월간 리포트 만들기 버튼 클릭 |
| `pricingScreenViewed` | 가격표 화면 도달 |
| `reportPassTapped` | Report Pass 선택 클릭 |
| `proPlanTapped` | Pro 선택 클릭 |
| `fakeDoorResultViewed` | 실제 결제/리포트 미제공 안내 화면 도달 |

### PricingPlan

| Value | Meaning |
|---|---|
| `reportPass` | 단건 월간 리포트 fake-door 선택지 |
| `pro` | 구독형 Pro fake-door 선택지 |

### CompensationReferenceMode

| Value | Korean Label | Meaning |
|---|---|---|
| `none` | 고정 포함 시간 없음 | 실제 기록만 표시하고 고정 포함 시간 비교는 숨김 |
| `fixedIncluded` | 고정 포함 시간 있음 | 실제 기록과 사용자가 입력한 고정 포함 시간을 비교 |
| `unknown` | 잘 모르겠음 | 실제 기록만 표시하고 설정 안내 문구를 표시 |

## WorkRecord

하루의 근무 기록이다. MVP에서는 같은 `workDate`에 하나의 `WorkRecord`만 둔다.

| Field | Type | Required | Unique | Default | Description |
|---|---|---:|---:|---|---|
| `id` | String | Yes | Yes | generated | 로컬 고유 ID |
| `workDate` | Date | Yes | Yes | none | 로컬 시간대 기준 근무일 |
| `clockInAt` | DateTime? | No | No | null | 출근 기록 시각 |
| `clockOutAt` | DateTime? | No | No | null | 퇴근 기록 시각 |
| `tags` | List<WorkRecordTag> | Yes | No | empty | 기록 사유 호환 필드. 월간 근무 태그는 근무 기준과 출퇴근 시각으로 계산한다 |
| `memo` | String? | No | No | null | 사용자가 입력한 짧은 메모 |
| `createdAt` | DateTime | Yes | No | now | 생성 시각 |
| `updatedAt` | DateTime | Yes | No | now | 마지막 수정 시각 |

### WorkRecord Validation

- `workDate`는 로컬 날짜만 포함한다.
- 같은 `workDate`의 `WorkRecord`는 1개만 허용한다.
- `clockInAt`과 `clockOutAt`이 모두 있으면 `clockOutAt >= clockInAt`이어야 한다.
- `tags`는 `WorkRecordTag`에 정의된 값만 허용한다.
- `tags`는 중복 값을 허용하지 않는다.
- `memo`는 비어 있거나 500자 이하 문자열이어야 한다.
- `createdAt <= updatedAt`이어야 한다.

### WorkRecord Derived Values

| Value | Rule | Stored |
|---|---|---|
| `workedDuration` | `clockOutAt - clockInAt` when both exist | No |
| `hasClockIn` | `clockInAt != null` | No |
| `hasClockOut` | `clockOutAt != null` | No |
| `isTaggedOvertime` | `tags` contains `overtime` | No |

## LeaveBalance

특정 연도에 사용자가 직접 입력한 총 연차 기준이다. 법정 연차 자동 계산은 하지 않는다.

| Field | Type | Required | Unique | Default | Description |
|---|---|---:|---:|---|---|
| `id` | String | Yes | Yes | generated | 로컬 고유 ID |
| `year` | int | Yes | Yes | current year | 기준 연도 |
| `totalLeaveMinutes` | int | Yes | No | 0 | 사용자가 직접 입력한 총 연차량 |
| `createdAt` | DateTime | Yes | No | now | 생성 시각 |
| `updatedAt` | DateTime | Yes | No | now | 마지막 수정 시각 |

### LeaveBalance Validation

- `year`는 2000 이상 2100 이하 정수여야 한다.
- 같은 `year`의 `LeaveBalance`는 1개만 허용한다.
- `totalLeaveMinutes`는 0 이상이어야 한다.
- `totalLeaveMinutes`는 30분 단위여야 한다.
- 자동 법정 연차 계산 필드는 추가하지 않는다.

### LeaveBalance Derived Values

| Value | Rule | Stored |
|---|---|---|
| `usedLeaveMinutes` | 같은 연도의 `LeaveUsage.usedLeaveMinutes` 합계 | No |
| `remainingLeaveMinutes` | `totalLeaveMinutes - usedLeaveMinutes` | No |
| `totalLeaveDays` | `totalLeaveMinutes / 480` | No |
| `remainingLeaveDays` | `remainingLeaveMinutes / 480` | No |

## LeaveUsage

사용자가 입력한 연차 사용 기록이다. 반차/시간 단위 표현을 위해 분 단위 정수로 저장한다.

| Field | Type | Required | Unique | Default | Description |
|---|---|---:|---:|---|---|
| `id` | String | Yes | Yes | generated | 로컬 고유 ID |
| `usedOn` | Date | Yes | No | none | 연차 사용 날짜 |
| `usedLeaveMinutes` | int | Yes | No | none | 사용한 연차량 |
| `memo` | String? | No | No | null | 사용자가 입력한 메모 |
| `createdAt` | DateTime | Yes | No | now | 생성 시각 |
| `updatedAt` | DateTime | Yes | No | now | 마지막 수정 시각 |

### LeaveUsage Validation

- `usedOn`은 로컬 날짜만 포함한다.
- `usedLeaveMinutes`는 30분 이상이어야 한다.
- `usedLeaveMinutes`는 30분 단위여야 한다.
- `memo`는 비어 있거나 500자 이하 문자열이어야 한다.
- 사용 연차 합계가 총 연차를 초과하더라도 저장을 막지 않는다. 대신 화면에서 초과 상태를 명확히 보여준다.
- 법정 연차 발생 규칙, 입사일, 회계연도 자동 계산은 포함하지 않는다.

## PricingIntentEvent

가격표/fake-door에서 사용자의 결제 의향을 로컬에 기록하는 이벤트다. 실제 결제나 구독 상태가 아니다.

| Field | Type | Required | Unique | Default | Description |
|---|---|---:|---:|---|---|
| `id` | String | Yes | Yes | generated | 로컬 고유 ID |
| `eventType` | PricingIntentEventType | Yes | No | none | 이벤트 유형 |
| `selectedPlan` | PricingPlan? | No | No | null | 선택한 요금제 |
| `sourceScreen` | String | Yes | No | none | 이벤트가 발생한 화면 이름 |
| `occurredAt` | DateTime | Yes | No | now | 이벤트 발생 시각 |
| `createdAt` | DateTime | Yes | No | now | 저장 시각 |

### PricingIntentEvent Validation

- `eventType`은 `PricingIntentEventType`에 정의된 값만 허용한다.
- `selectedPlan`은 Report Pass 또는 Pro 클릭 이벤트에서만 필수다.
- `sourceScreen`은 비어 있지 않아야 하며 100자 이하 문자열이어야 한다.
- 실제 결제 성공, 구독 활성화, 리포트 생성 완료를 의미하는 이벤트 타입은 MVP에 추가하지 않는다.

## CompensationReferenceSetting

계약 형태를 판단하지 않고 사용자가 직접 입력한 고정 포함 시간을 실제 기록과 비교하는 후속 설정이다. 이 모델은 post-MVP 후보이며 기존 `workledger-mvp` 완료율에는 포함하지 않는다.

| Field | Type | Required | Unique | Default | Description |
|---|---|---:|---:|---|---|
| `id` | String | Yes | Yes | generated | 로컬 고유 ID |
| `mode` | CompensationReferenceMode | Yes | No | `unknown` | 비교 방식 선택값 |
| `fixedIncludedOvertimeMinutes` | int | Yes | No | 0 | 월 고정 포함 연장 근무 시간 |
| `fixedIncludedNightMinutes` | int | Yes | No | 0 | 월 고정 포함 야간 근무 시간 |
| `fixedIncludedHolidayMinutes` | int | Yes | No | 0 | 월 고정 포함 휴무일 근무 시간 |
| `effectiveFromMonth` | Date | Yes | Yes | none | 적용 시작 월. 저장 시 해당 월의 1일로 정규화 |
| `memo` | String? | No | No | null | 계약서/급여명세서 확인 메모 |
| `createdAt` | DateTime | Yes | No | now | 생성 시각 |
| `updatedAt` | DateTime | Yes | No | now | 마지막 수정 시각 |

### CompensationReferenceSetting Validation

- `mode`는 `none`, `fixedIncluded`, `unknown` 중 하나여야 한다.
- `fixedIncludedOvertimeMinutes`, `fixedIncludedNightMinutes`, `fixedIncludedHolidayMinutes`는 0 이상이어야 한다.
- 고정 포함 시간 값은 30분 단위 입력을 권장한다.
- `effectiveFromMonth`는 월 단위 날짜이며, 저장 시 `YYYY-MM-01` 형태로 정규화한다.
- 같은 `effectiveFromMonth`의 `CompensationReferenceSetting`은 1개만 허용한다.
- `mode != fixedIncluded`이면 고정 포함 시간 비교는 비활성화하고 시간 필드는 계산에 사용하지 않는다.
- `memo`는 비어 있거나 500자 이하 문자열이어야 한다.
- 이 설정은 확정값, 분쟁 판단, 청구 안내, 전문 자문을 의미하지 않는다.

### CompensationReferenceSetting Derived Values

| Value | Rule | Stored |
|---|---|---|
| `applicableSetting` | 월간 요약 대상 월보다 같거나 이전인 최신 `effectiveFromMonth` 설정 | No |
| `actualOvertimeMinutes` | 기존 `WorkRecord + WorkRule` 기반 연장 근무 후보 시간 | No |
| `actualNightMinutes` | 기존 `WorkRecord + WorkRule` 기반 야간 근무 후보 시간 | No |
| `actualHolidayMinutes` | 기존 `WorkRecord + WorkRule` 기반 휴무일 근무 후보 시간 | No |
| `overtimeExcessReferenceMinutes` | `max(actualOvertimeMinutes - fixedIncludedOvertimeMinutes, 0)` | No |
| `nightExcessReferenceMinutes` | `max(actualNightMinutes - fixedIncludedNightMinutes, 0)` | No |
| `holidayExcessReferenceMinutes` | `max(actualHolidayMinutes - fixedIncludedHolidayMinutes, 0)` | No |

## Query Patterns

| Screen/Flow | Query |
|---|---|
| 홈/오늘 기록 | 오늘 `workDate`의 `WorkRecord` 1건 조회 |
| 기록 수정 | 선택한 `WorkRecord.id` 조회 후 수정 |
| 연차 관리 | 현재 연도 `LeaveBalance`와 해당 연도 `LeaveUsage` 목록 조회 |
| 월간 요약 | 월 범위의 `WorkRecord`, `LeaveUsage` 목록 조회 |
| 월간 고정 포함 시간 비교 | 월간 요약 대상 월에 적용 가능한 `CompensationReferenceSetting` 최신 1건 조회 |
| 가격표/fake-door | `PricingIntentEvent` 생성 및 최근 이벤트 목록 조회 |

## Initial Index Plan

| Storage Table | Index | Reason |
|---|---|---|
| `work_records` | unique `work_date` | 오늘 기록 및 월간 요약 조회 |
| `leave_balances` | unique `year` | 연도별 총 연차 기준 조회 |
| `leave_usages` | `used_on` | 월간/연간 연차 사용 조회 |
| `pricing_intent_events` | `occurred_at` | 클릭 이벤트 시계열 확인 |
| `compensation_reference_settings` | unique `effective_from_month` | 월간 요약의 고정 포함 시간 비교 기준 조회 |

## Non-Goals

- 사용자 계정 ID를 모델에 넣지 않는다.
- 회사 ID, 회사명, 위치 좌표를 필수 필드로 넣지 않는다.
- 법률 증거 상태, 소송 상태, 노무 자문 상태를 모델에 넣지 않는다.
- 확정값, 분쟁 판단 결과, 청구 안내 값을 모델에 넣지 않는다.
- 실제 결제 상태, 구독 상태, 영수증 검증 필드를 넣지 않는다.
- 실제 PDF/CSV 생성 결과 파일 경로를 MVP 필수 모델에 넣지 않는다.
