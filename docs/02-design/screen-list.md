# WorkLedger Screen List

## Scope

이 문서는 `workledger-mvp`의 Phase 3 화면 목록이다. 상세 아키텍처와 구현 순서는 `docs/archive/2026-06/workledger-mvp/workledger-mvp.design.md`를 기준으로 한다.

## Screens

| ID | Screen | Route | Purpose | Primary Data |
|---|---|---|---|---|
| S-01 | 홈/오늘 기록 | `/` | 오늘 출근/퇴근 1탭 기록 | `WorkRecord` |
| S-02 | 기록 추가/수정 | `/work-record/edit` | 선택 날짜의 출근/퇴근 시각, 기록 사유, 메모 보정 | `WorkRecord` |
| S-03 | 달력 보기 | `/work-record/calendar` | 이번 달 날짜별 근무 기록 유무 확인과 누락 기록 추가/수정 | `WorkRecord` |
| S-04 | 연차 관리 | `/leave` | 연차 사용 기록 추가/삭제 | `LeaveUsage`, `LeaveBalance` |
| S-05 | 월간 요약 | `/summary` | 월간 근무시간, 선택형 근무 태그, 연차 요약 | `WorkRecord`, `LeaveUsage`, `LeaveBalance` |
| S-06 | 근무 기준 설정 | `/settings/work-rules` | 선택형 정시 출근/퇴근, 휴게시간, 평일 요일 설정 | work rule settings |
| S-07 | 가격표/fake-door | `/pricing` | Report Pass/Pro 클릭 의향 측정 | `PricingIntentEvent` |
| S-08 | 설정 | `/settings` | 근무 기준, 비교 방식, 총 연차, 알림 설정 진입 | settings |
| S-09 | 총 연차 설정 | `/settings/leave-balance` | 올해 총 연차 직접 입력 | `LeaveBalance` |
| S-10 | 알림 설정 | `/settings/notifications` | 상시 알림 권한 요청과 알림 재표시 | notification permission |

## Screen States

| Screen | Empty State | Error State |
|---|---|---|
| 홈/오늘 기록 | 오늘 기록 없음, 출근 버튼 강조 | 저장 실패, 잘못된 퇴근 시각 |
| 기록 수정 | 선택 기록 없음 | 검증 실패, 저장 실패 |
| 달력 보기 | 선택 월 기록 없음 | 월별 조회 실패, 요약 계산 실패 |
| 연차 관리 | 사용 내역 없음 | 30분 단위 위반, 저장 실패 |
| 월간 요약 | 선택 월 기록 없음 | 요약 계산 실패 |
| 근무 기준 설정 | 기준 미설정 | 잘못된 시각 범위, 저장 실패 |
| 가격표/fake-door | 이벤트 없음 | 이벤트 저장 실패 |
| 설정 | 설정 항목 표시 | 하위 설정 저장 실패 |
| 총 연차 설정 | 총 연차 미입력 | 30분 단위 위반, 저장 실패 |
| 알림 설정 | 알림 권한 미확정 | 권한 거부, 설정 실패 |

## Navigation Entrypoints

| From | To | Trigger |
|---|---|---|
| 홈/오늘 기록 | 기록 수정 | 오늘 기록 카드 또는 수정 버튼 |
| 홈/오늘 기록 | 달력 보기 | 퇴근 후 `달력 보기` 보조 버튼 |
| 홈/오늘 기록 | 월간 요약 | 하단 `월간 요약` 버튼 |
| 홈/오늘 기록 | 연차 관리 | 연차 버튼 |
| 홈/오늘 기록 | 설정 | 오른쪽 상단 톱니바퀴 |
| 설정 | 근무 기준 설정 | `근무 기준` 항목 |
| 설정 | 비교 방식 | `비교 방식` 항목 |
| 설정 | 총 연차 설정 | `총 연차` 항목 |
| 설정 | 알림 설정 | `알림` 항목 |
| 달력 보기 | 기록 추가/수정 | 선택 날짜에 기록이 없으면 `기록 추가`, 기존 기록이 있으면 `기록 수정` |
| 월간 요약 | 가격표/fake-door | 월간 리포트 만들기 버튼 |
| 설정 | 홈/오늘 기록 | 뒤로가기 |

## Out Of Scope Screens

- 로그인
- 회원가입
- 클라우드 백업
- 결제 완료
- PDF/CSV 실제 리포트 화면
- GPS 자동 추적 설정
- 회사 근태 시스템 연동
