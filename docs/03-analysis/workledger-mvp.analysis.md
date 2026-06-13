# Gap Analysis: workledger-mvp

> Date: 2026-06-13 | Phase: check | Scope: optional work rules and non-workday/early/overtime/night work tags

## Match Rate: 100%

계산 기준은 기존 MVP functional requirements 19개와 이번 설계 변경으로 추가된 근무 기준/근무 태그 설계 항목 15개, 총 34개다. 기존 MVP 19개는 유지됐고, 새 설계 항목 15개도 구현과 테스트로 확인됐다.

```text
implemented = 34
total = 34
matchRate = 34 / 34 = 100%
```

이번 분석은 새 설계 문서와 Flutter 구현을 다시 비교한 결과다. 10초 출퇴근 기록, 달력 보기, 월간 요약, 연차 관리, 가격 fake-door, Android 알림 액션은 유지하면서, 근무 기준 기반 근무 태그 계산을 추가했다.

## Sources Checked

| Source | Purpose |
|---|---|
| `docs/01-plan/features/workledger-mvp.plan.md` | 기존 MVP FR/NFR/scope guard |
| `docs/02-design/features/workledger-mvp.design.md` | Optional Work Rule Setup, Non-Workday/Early/Overtime/Night Work Tag Rules |
| `docs/02-design/mockup.md` | S-06A/S-06B 화면 설계와 월간 요약 변경 방향 |
| `docs/02-design/user-flow.md` | 선택형 근무 기준 설정, 근무 태그 흐름 |
| `docs/02-design/screen-list.md` | 신규 근무 기준 설정 화면 |
| `lib/core/models/work_rule.dart` | 정시 출근/퇴근, 휴게시간, 평일 근무 요일 모델 |
| `lib/features/work_rule/` | 근무 기준 저장소와 설정 화면 |
| `lib/features/work_time/domain/` | 근무 태그 순수 계산 |
| `lib/features/monthly_summary/` | 월간 요약 근무 태그 합산과 화면 표시 |
| `lib/features/work_record/presentation/` | 퇴근 후 설정 제안, 기록 사유 표시 |
| `test/core/models/work_rule_test.dart` | WorkRule 직렬화와 validation |
| `test/features/work_rule/` | 저장소와 설정 화면 검증 |
| `test/features/work_time/domain/calculate_work_time_candidates_test.dart` | 근무 태그 계산 검증 |
| `test/features/monthly_summary/` | 월간 근무 태그 합산과 화면 검증 |

## Existing MVP Status

| Area | Status | Notes |
|---|---|---|
| 10초 출근/퇴근 기록 | Done | 설정 없이 바로 `출근하기`/`퇴근하기` 가능 |
| 오늘 기록 수정 | Done | 출근/퇴근 시각, 기록 사유, 메모, 삭제 |
| 달력 보기 | Done | 날짜별 완료/미완료/기록 없음 확인 |
| 월간 요약 | Done | 휴게시간 제외 총 근무, 근무일, 연차 요약, 근무 태그 표시 |
| 연차 관리 | Done | 수동 총 연차와 사용량 계산 |
| 가격 fake-door | Done | 실제 결제 없이 intent 저장 |
| Android persistent notification | Done | 알림 출근/퇴근 action |
| i18n 구조 | Done | ko 기본, en 구조 |

## New Design Delta Status

| Item | Status | Evidence |
|---|---|---|
| 첫 실행에서 근무 기준 설정을 강제하지 않음 | Done | 홈은 기준 없이 바로 출근/퇴근 가능 |
| 선택형 근무 기준 설정 화면 | Done | `WorkRuleSettingsScreen`, `work_rule_settings_screen_test.dart` |
| 정시 출근/정시 퇴근/휴게시간/평일 요일 저장 | Done | `WorkRule`, `LocalStorageWorkRuleRepository` |
| 첫 퇴근 후 또는 월간 요약에서 설정 제안 | Done | `WorkRecordHomeScreen`, `MonthlySummaryScreen` 설정 prompt |
| 홈 상단 설정 진입점 | Done | `WorkRecordHomeScreen` AppBar 톱니바퀴에서 `WorkRuleSettingsScreen` 진입 |
| 휴게시간 제외 총 근무 표시 | Done | `MonthlySummaryViewData.displayTotalWorkedDuration` |
| 홈 preview 휴게시간 제외 표시 | Done | `WorkRecordHomeScreen`이 `displayTotalWorkedDuration` 사용 |
| 휴무일 근무 계산 | Done | 휴무 요일 기록은 휴게시간 제외 `nonWorkdayDuration`으로 표시 |
| 정시 전 근무 계산 | Done | `calculateWorkTimeCandidates`에서 정시 출근 이전 구간 계산 |
| 연장 근무 계산 | Done | `calculateWorkTimeCandidates`에서 정시 퇴근 이후 구간 계산 |
| 야간 근무 계산 | Done | `calculateWorkTimeCandidates`에서 22:00-06:00 겹침 구간 계산 |
| 퇴근 기록 지연 사유 분리 | Done | 오늘 기록 수정/달력/월간 목록에서 `기록 사유: 퇴근 기록 지연`으로 표시 |
| 퇴근 기록 지연 근무 태그 제외 | Done | `delayedCheckout`이면 휴무일 근무, 정시 퇴근 이후 연장 근무, 야간 근무 제외 |
| 월간 요약 근무 태그 표시 | Done | `MonthlySummaryViewData.workTimeCandidateSummary`, `근무 태그` 카드, 0분 항목 숨김 |
| 정시 기준 외 근무 없음 빈 상태 | Done | 모든 근무 태그가 0분이면 `정시 기준 외 근무 없음` 표시 |

## Key Decisions

### 1. Work rule setup remains optional

앱 첫 실행은 막지 않는다. 사용자는 계속 10초 출근/퇴근을 먼저 할 수 있고, 첫 퇴근 후 또는 월간 요약에서 근무 기준 설정을 제안받는다.

### 2. Non-workday, early, overtime and night work tags are not payroll values

휴무일 근무는 사용자가 평일 근무 요일로 선택하지 않은 날짜의 휴게시간 제외 근무 구간으로 계산한다. 정시 전 근무는 정시 출근 이전 실제 근무 구간으로 계산한다. 연장 근무는 정시 퇴근 이후 실제 근무 구간으로 계산한다. 야간 근무는 실제 근무 구간과 22:00-06:00 구간의 겹침으로 계산한다. 휴무일 근무는 날짜 성격의 근무 태그이고 정시 전/연장/야간 근무는 시간대 성격의 근무 태그이므로, 휴무일 기록에서도 네 태그를 각각 분리해 표시한다. 월간 요약 화면은 0분 항목을 숨기고, 완료 기록이 모두 정시 기준 안에 있으면 `정시 기준 외 근무 없음`을 빈 상태로 보여준다.

### 3. Day-level tags no longer drive monthly overtime summary

기존 `WorkRecordTag.overtime`, `holidayWork`는 월간 근무 태그 계산과 표시에서 제외됐다. `delayedCheckout`은 호환을 위해 저장 구조에는 남아 있지만, 사용자 화면에서는 “기록 사유: 퇴근 기록 지연”으로 표시된다. `delayedCheckout` 기록은 퇴근 시각이 신뢰하기 어렵기 때문에 휴무일 근무, 정시 퇴근 이후 연장 근무, 야간 근무 계산에서 제외한다.

### 4. Monthly total uses display-time adjustment only

월간 요약과 홈 preview의 “총 근무”는 근무 기준이 설정된 경우 근무 요일 여부와 관계없이 `휴게시간`을 제외한 표시용 순근무시간으로 계산한다. 원본 출근/퇴근 기록과 월간 기록 목록의 시각은 그대로 보존한다. 근무 기준이 없으면 기존처럼 출근-퇴근 전체 시간을 표시한다.

### 5. Existing MVP scope guard remains intact

서버, 로그인, 클라우드 sync, GPS 자동 추적, 회사 근태 연동, 법정 연차 자동 계산, 급여 계산, 실제 PDF/CSV 생성, 실제 결제는 추가하지 않았다.

## Verification

| Command | Result |
|---|---|
| `$HOME/.local/share/flutter-stable/bin/dart format lib test` | Passed |
| `$HOME/.local/share/flutter-stable/bin/flutter analyze` | Passed, `No issues found` |
| `$HOME/.local/share/flutter-stable/bin/flutter test` | Passed, `173` tests |
| `git --no-pager diff --check` | Passed |
| `rg "태그별 참고|태그:|퇴근 지연|휴일근무|야근" lib test docs/03-analysis docs/02-design -n` | 코드 표시 경로에는 legacy tag summary 없음 |

## Remaining Non-Blocking Notes

- `WorkRecordTag` enum은 기존 저장 데이터 호환 때문에 남아 있다.
- 휴일근무 세부 계산은 아직 급여/법정 수당 계산으로 확장하지 않았다. 현재 범위에서는 휴무일 근무와 정시 전·연장·야간 근무를 개인 참고용으로 분리 표시한다.
- Android 실기기 smoke test와 debug APK build는 ship 검증 단계에서 다시 수행한다.

## Recommendation

Match Rate가 100%이고 자동 검증도 통과했으므로 구현 gap은 닫힌 상태다. 다음 단계는 ship workflow로 넘어가 fresh build, review, commit, push, PR 생성을 진행하는 것이다.

## Next Steps

1. `$ship` workflow pre-flight를 실행한다.
2. debug APK build를 포함해 fresh verification을 수행한다.
3. 커밋을 논리 단위로 생성한다.
4. 원격 브랜치에 push하고 PR을 생성한다.
