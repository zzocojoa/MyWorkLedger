# Gap Analysis: workledger-mvp

> Date: 2026-06-14 | Phase: archived | Scope: WorkLedger MVP plus PR #13 comparison summary follow-up

## Match Rate: 100%

계산 기준은 MVP functional requirements 19개와 구현 중 추가 설계된 근무 기준, 근무 태그, 달력 보기 안정화 항목 15개를 합친 총 34개다. 현재 MVP 기준 34개 항목은 모두 구현됐고, PR #13은 고정 포함 시간 비교 방식을 월간 요약에 읽기 전용 참고 카드로 연결하는 후속 개선이다.

```text
implemented = 34
total = 34
matchRate = 34 / 34 = 100%
```

이번 check는 PR #13 `feat: show included time comparison summary` 브랜치 상태를 기준으로 한다. PR #13은 `고정 포함 시간 있음`일 때만 월간 요약에 `포함 시간 대비` 카드를 표시하고, `고정 포함 시간 없음`과 `잘 모르겠음`에서는 비교 카드를 숨긴다.

## Sources Checked

| Source | Purpose |
|---|---|
| `docs/archive/2026-06/workledger-mvp/workledger-mvp.plan.md` | MVP FR/NFR/scope guard |
| `docs/archive/2026-06/workledger-mvp/workledger-mvp.design.md` | 화면, 저장소, 알림, 근무 기준 설계 |
| `docs/02-design/mockup.md` | 홈, 달력, 월간 요약, 연차, 가격 UI 상태 |
| `docs/02-design/user-flow.md` | 핵심 사용자 흐름 |
| `docs/02-design/screen-list.md` | 화면 목록 |
| `lib/core/models/` | WorkRecord, LeaveBalance, LeaveUsage, PricingIntentEvent, WorkRule |
| `lib/core/storage/` | key-value 저장소와 영속 저장소 adapter |
| `lib/core/notifications/` | Android persistent notification action 경계 |
| `lib/features/work_record/` | 홈, 오늘 기록 수정, 달력 보기 |
| `lib/features/monthly_summary/` | 월간 요약과 근무 태그 표시 |
| `lib/features/leave/` | 수동 연차 입력과 사용 기록 |
| `lib/features/pricing/` | 가격 fake-door와 intent 저장 |
| `lib/features/work_rule/` | 선택형 근무 기준 설정 |
| `lib/features/work_time/` | 근무 기준 외 근무 태그 계산 |
| `lib/l10n/` | ko 기본, en 구조 |
| `test/` | 모델, 저장소, use case, 화면, 알림, 회귀 테스트 |

## Existing MVP Status

| Area | Status | Notes |
|---|---|---|
| 계정 없이 시작 | Done | 서버나 로그인 없이 앱 시작 |
| 로컬 저장 | Done | `PersistentKeyValueStorage` 기반 로컬 저장 구조 |
| 10초 출근/퇴근 기록 | Done | 홈 primary CTA와 알림 action |
| Android persistent notification | Done | 출근/퇴근 action 2개와 foreground notification |
| 오늘 기록 수정 | Done | 출근/퇴근 시각, 기록 사유, 메모, 오늘 기록 삭제 |
| 달력 보기 | Done | 날짜별 완료, 출근만 기록, 시간 누락, 기록 없음 구분 |
| 달력 작은 화면 안정성 | Done | PR #5에서 overflow 방지와 `닫기` 버튼 제거 |
| 월간 요약 | Done | 총 근무, 근무일, 근무 태그, 연차 요약, 조건부 포함 시간 대비 |
| 근무 기준 설정 | Done | 정시 출근/퇴근, 휴게시간, 평일 근무 요일 |
| 근무 태그 계산 | Done | 휴무일 근무, 정시 전 근무, 연장 근무, 야간 근무 |
| 근무 태그 결과 카드 | Done | 0분 태그는 숨기고 실제 태그가 있을 때만 표시 |
| 연차 관리 | Done | 총 연차는 설정으로 이동, 사용량 추가/삭제는 연차 화면에 유지 |
| 가격 fake-door | Done | 실제 결제 없이 intent 저장 |
| 한국어 기본 UI | Done | 기본 문구는 한국어 |
| 영어 i18n 구조 | Done | `lib/l10n/app_en.arb`와 생성 클래스 |

## Functional Requirement Status

| FR | Requirement | Status |
|---|---|---|
| FR-01 | 계정 없이 앱 시작 | Done |
| FR-02 | 오늘 출근 1탭 기록 | Done |
| FR-03 | 오늘 퇴근 1탭 기록 | Done |
| FR-04 | 상시 알림 출근/퇴근 action | Done |
| FR-05 | 출근/퇴근 시간 수동 수정 | Done |
| FR-06 | 퇴근 기록 지연 사유와 메모 | Done |
| FR-07 | 짧은 메모 | Done |
| FR-08 | 총 연차 수동 입력 | Done |
| FR-09 | 연차 사용 일수 기록 | Done |
| FR-10 | 잔여연차 표시 | Done |
| FR-11 | 월간 근무시간 합계 | Done |
| FR-12 | 월간 근무 태그 분리 표시 | Done |
| FR-13 | 월간 연차 사용/잔여 요약 | Done |
| FR-14 | 월간 리포트 만들기 버튼 | Done |
| FR-15 | 가격표 화면 | Done |
| FR-16 | Report Pass / Pro 클릭 이벤트 | Done |
| FR-17 | fake-door 결과 표시 | Done |
| FR-18 | 한국어 기본 UI | Done |
| FR-19 | 영어 i18n 구조 | Done |

## Design Delta Status

| Item | Status | Evidence |
|---|---|---|
| 첫 실행에서 근무 기준 설정을 강제하지 않음 | Done | 홈에서 기준 없이 출근/퇴근 가능 |
| 선택형 근무 기준 설정 화면 | Done | `WorkRuleSettingsScreen` |
| 정시 출근/퇴근/휴게시간/평일 요일 저장 | Done | `WorkRule`, `LocalStorageWorkRuleRepository` |
| 첫 퇴근 후 또는 월간 요약에서 설정 제안 | Done | 홈과 월간 요약 prompt |
| 홈 상단 설정 진입점 | Done | 홈 AppBar 설정 버튼 |
| 휴게시간 제외 총 근무 표시 | Done | 월간 요약과 홈 preview |
| 휴무일 근무 계산 | Done | `calculateWorkTimeCandidates` |
| 정시 전 근무 계산 | Done | `calculateWorkTimeCandidates` |
| 연장 근무 계산 | Done | `calculateWorkTimeCandidates` |
| 야간 근무 계산 | Done | `calculateWorkTimeCandidates` |
| 퇴근 기록 지연 사유 분리 | Done | 기록 사유로 표시 |
| 퇴근 기록 지연 근무 태그 제외 | Done | 지연 기록은 신뢰 어려운 퇴근 구간 제외 |
| 0분 근무 태그 숨김 | Done | 월간 요약 카드 |
| 근무 태그 결과 카드 | Done | 실제 태그가 없으면 월간 요약 결과 카드 숨김 |
| 포함 시간 대비 카드 | Done | `fixedIncluded` 설정일 때만 월간 요약에 실제 기록/포함 시간/초과 참고 표시 |
| 비교 카드 숨김 | Done | `none` 또는 `unknown` 설정에서는 월간 요약 비교 카드 숨김 |
| 달력 보기 overflow 회귀 방지 | Done | compact widget test와 실기기 smoke |

## Scope Guard

다음 범위 밖 기능은 현재 `main`에 포함되지 않았다.

| Out-of-scope Item | Status |
|---|---|
| 서버 | Not included |
| 로그인/계정 | Not included |
| 클라우드 sync | Not included |
| GPS 자동 추적 | Not included |
| 회사 근태 시스템 연동 | Not included |
| 법정 연차 자동 계산 | Not included |
| 급여/법정 수당 확정 계산 | Not included |
| 실제 결제 | Not included |
| 실제 PDF/CSV 생성 | Not included |
| Quick Settings Tile | Not included |
| 홈 위젯 | Not included |

## Verification

검증은 PR #13 브랜치 결과를 기준으로 정리했다.

| Command or Check | Result |
|---|---|
| `$HOME/.local/share/flutter-stable/bin/flutter analyze` | Passed |
| `$HOME/.local/share/flutter-stable/bin/flutter test` | Passed, 213 tests |
| `$HOME/.local/share/flutter-stable/bin/flutter build apk --debug` | Passed |
| `git --no-pager diff --check` | Passed |
| PR #13 local diff review | Passed |
| GitHub checks | Not configured |
| Production URL / canary | Not applicable, Flutter Android app |

## Remaining Non-Blocking Notes

- `.gstack/` land report는 로컬 운영 기록이며, 요청대로 Git 추적 대상에 포함하지 않았다.
- GitHub Actions가 없으므로 merge 후 자동 check는 없다. 현재 안전장치는 로컬 analyze, test, debug build, 실기기 smoke다.
- 현재 artifact는 debug APK 기준이다. 실제 배포가 필요하면 Android release signing과 AAB 빌드를 별도 범위로 잡아야 한다.
- `WorkRecordTag` enum은 기존 저장 데이터 호환과 기록 사유 표시를 위해 남아 있다.
- 근무 태그는 개인 참고용 요약이며 급여나 법정 수당 계산 결과가 아니다.

## Post-MVP Follow-up Candidate

`fixed-included-work-time`은 고정 포함 시간을 따로 기록해야 하는 사용자를 위한 후속 개선이다. PR #13에서는 월간 요약에서 사용자가 저장한 비교 방식의 결과를 읽기 전용으로 확인할 수 있게 했다.

| Candidate | Status | Reason |
|---|---|---|
| 비교 방식 설정 | Done | 사용자가 `없음`, `있음`, `잘 모르겠음` 중 하나를 저장 |
| 전체 데이터 반영 | Done | 적용 시작 월 입력 없이 저장한 비교 방식을 전체 기록 기준으로 사용 |
| 월간 요약 조건부 표시 | Done | `있음`이면 `포함 시간 대비` 표시, `없음`/`잘 모르겠음`이면 숨김 |

설계 원칙은 다음과 같다.

- `WorkRecord`에는 고정 포함 시간 여부를 저장하지 않는다.
- 별도 `CompensationReferenceSetting`을 월간 요약 계산 시점에만 참조한다.
- 설정 변경은 기존 기록을 수정하거나 마이그레이션하지 않고 전체 데이터 기준으로 저장한다.
- 월간 요약은 연장 근무, 야간 근무, 휴무일 근무별 `실제 기록`, `포함 시간`, `초과 참고`만 표시한다.
- 확정값, 분쟁 판단, 청구 안내, 전문 자문은 범위 밖이다.

## Recommendation

Match Rate가 100%이고 PR #13 브랜치 검증도 통과했으므로 구현 gap은 닫힌 상태다. 다음 단계는 PR #13 Files changed 확인 후 merge readiness를 판단하는 것이다.

## Next Steps

1. PR #13 Files changed를 최종 확인한다.
2. GitHub checks가 없으면 로컬 `flutter analyze`, `flutter test`, `flutter build apk --debug` 결과를 merge safety 근거로 사용한다.
3. 이상 없으면 `$land-and-deploy`로 PR #13을 merge한다.
