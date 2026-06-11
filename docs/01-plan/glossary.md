# WorkLedger Glossary

## Scope

이 문서는 `workledger-mvp`의 Phase 1 용어 기준이다. MVP는 계정 없이 로컬에만 저장되는 개인 근무 기록 앱이며, 법률 자문, 증거 효력 보장, 자동 법정 연차 계산, 실제 결제, 실제 PDF/CSV 생성을 포함하지 않는다.

## Domain Terms

| Term | Korean | Definition | MVP Rule |
|---|---|---|---|
| WorkLedger | 내근무장부 | 개인 근무 기록과 연차 사용을 로컬에 남기는 Flutter Android 앱 | 앱 영문명은 `WorkLedger`, 한국어 표시명은 `내근무장부` |
| WorkRecord | 근무 기록 | 하루 단위의 출근, 퇴근, 태그, 메모 기록 | MVP에서는 날짜별 1개 기록을 기본으로 한다 |
| Work Date | 근무일 | 기록이 속하는 날짜 | 로컬 시간대의 날짜를 기준으로 저장한다 |
| Clock In | 출근 기록 | 사용자가 근무 시작 시각을 남기는 행동 또는 시각 | 앱 홈 또는 상시 알림 액션으로 기록한다 |
| Clock Out | 퇴근 기록 | 사용자가 근무 종료 시각을 남기는 행동 또는 시각 | 출근 시각보다 빠르면 저장하지 않는다 |
| Work Tag | 근무 태그 | 기록 맥락을 빠르게 표시하는 분류 | `야근`, `퇴근 지연`, `휴일근무`만 MVP에 포함한다 |
| Overtime Tag | 야근 태그 | 야근이 있었다고 사용자가 표시한 태그 | 임금 산정이나 법적 판단을 의미하지 않는다 |
| Delayed Checkout Tag | 퇴근 지연 태그 | 퇴근이 늦어진 맥락을 사용자가 표시한 태그 | 지연 사유는 메모로 보완한다 |
| Holiday Work Tag | 휴일근무 태그 | 휴일에 근무했다고 사용자가 표시한 태그 | 휴일 여부 자동 판정은 MVP 밖이다 |
| Memo | 메모 | 기록에 붙이는 짧은 텍스트 | 민감정보 입력을 필수로 요구하지 않는다 |
| Monthly Summary | 월간 요약 | 월 단위 근무시간, 초과근무 참고 시간, 연차 사용/잔여 요약 | 개인 참고용이며 임금 정확성을 보장하지 않는다 |
| Overtime Summary | 초과근무 참고 시간 | 월간 요약에서 보여주는 참고용 초과근무 시간 | 법정 수당 계산이나 법률 판단으로 표현하지 않는다 |
| LeaveBalance | 연차 잔액 기준 | 특정 연도의 총 연차 입력값 | 사용자가 수동 입력한 값만 저장한다 |
| LeaveUsage | 연차 사용 기록 | 사용자가 특정 날짜에 사용한 연차량과 메모 | 반차를 표현할 수 있도록 분 단위로 저장한다 |
| Remaining Leave | 잔여연차 | 총 연차에서 사용 연차 합계를 뺀 계산값 | 저장하지 않고 화면/요약에서 계산한다 |
| PricingIntentEvent | 가격 의향 이벤트 | 리포트/요금제 화면에서 사용자가 누른 버튼 기록 | 실제 결제 없이 로컬 이벤트로만 저장한다 |
| Report Pass | 리포트 패스 | fake-door 가격표의 단건 리포트 구매 선택지 | 실제 구매나 리포트 생성은 하지 않는다 |
| Pro | 프로 | fake-door 가격표의 구독형 선택지 | 실제 구독이나 결제는 하지 않는다 |
| Local Storage | 로컬 저장 | 앱 내부 저장소에만 데이터를 보관하는 방식 | 서버 전송, 로그인, 클라우드 동기화는 하지 않는다 |
| Persistent Notification | 상시 알림 | 알림창에 유지되어 출근/퇴근 액션을 제공하는 알림 | 권한 거부 시 앱 내부 1탭 기록은 계속 동작해야 한다 |

## Naming Decisions

| Concept | Dart Name | Storage Table | Notes |
|---|---|---|---|
| 근무 기록 | `WorkRecord` | `work_records` | 날짜별 1개 기록 |
| 근무 태그 | `WorkRecordTag` | `work_record_tags` 또는 serialized list | MVP 구현에서 단순 저장 방식을 선택한다 |
| 연차 잔액 기준 | `LeaveBalance` | `leave_balances` | 연도별 1개 기준 |
| 연차 사용 기록 | `LeaveUsage` | `leave_usages` | 여러 건 저장 가능 |
| 가격 의향 이벤트 | `PricingIntentEvent` | `pricing_intent_events` | 클릭 이벤트 로그 |
| 가격 이벤트 유형 | `PricingIntentEventType` | `event_type` | 문자열 enum으로 저장 |
| 선택 요금제 | `PricingPlan` | `selected_plan` | nullable 문자열 enum으로 저장 |

## Excluded Terms

| Term | Reason |
|---|---|
| Legal Evidence | 증거 효력 보장을 암시하므로 MVP에서 사용하지 않는다 |
| Legal Advice | 법률 자문으로 오해될 수 있어 MVP에서 사용하지 않는다 |
| Statutory Leave Calculator | 자동 법정 연차 계산은 회사 정책 차이로 MVP에서 제외한다 |
| Payroll Calculator | 임금 정확성 보장을 기대하게 하므로 MVP에서 제외한다 |
| Cloud Account | 로그인/동기화 범위를 만들기 때문에 MVP에서 제외한다 |
