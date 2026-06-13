# WorkLedger MVP PDCA Report

> Date: 2026-06-13 | Feature: workledger-mvp | Phase: report-ready | Match Rate: 100%

## Summary

WorkLedger MVP는 `main` 기준으로 계획된 MVP 기능 요구사항 19개를 모두 충족한다. 구현 중 확장된 근무 기준, 근무 태그, 달력 보기 안정화 항목까지 포함한 check 기준은 34/34 완료다.

| Item | Result |
|---|---|
| Functional Match Rate | 100% |
| Check Items | 34/34 Done |
| Current branch | `main` |
| Local/remote status | `main == origin/main` |
| Latest landed PR | PR #5 `fix: prevent calendar overflow` |
| Latest merge SHA | `f2e5b653e2a00a34de2c95ca14f16cf8bd192d08` |
| bkit level | Starter |
| bkit phase before report docs | check |

## Related Documents

| Document | Purpose |
|---|---|
| `docs/01-plan/features/workledger-mvp.plan.md` | MVP source of truth |
| `docs/01-plan/schema.md` | Core data schema |
| `docs/01-plan/glossary.md` | Product terminology |
| `docs/01-plan/convention.md` | Flutter/Dart conventions |
| `docs/02-design/features/workledger-mvp.design.md` | Architecture and implementation plan |
| `docs/02-design/mockup.md` | Screen states and wireframes |
| `docs/02-design/screen-list.md` | Screen inventory |
| `docs/02-design/user-flow.md` | User flows |
| `docs/03-analysis/workledger-mvp.analysis.md` | Gap analysis |
| `docs/04-report/workledger-mvp.release-readiness.md` | Android readiness evidence |

## Completed Functional Items

| Area | Result |
|---|---|
| Accountless local start | Done |
| Korean default UI | Done |
| English i18n structure | Done |
| 1-tap clock-in and clock-out | Done |
| Android persistent notification actions | Done |
| Today record edit | Done |
| Record reason and memo | Done |
| Calendar view | Done |
| Calendar compact-screen overflow fix | Done |
| Monthly work summary | Done |
| Work rule setup | Done |
| Work tag summary | Done |
| Manual leave balance | Done |
| Leave usage record | Done |
| Pricing fake-door | Done |
| Local pricing intent events | Done |

## Completed Non-Functional Items

| Requirement | Result |
|---|---|
| Android first | Done |
| Flutter based | Done |
| Serverless MVP | Done |
| Local core data | Done |
| No required company/location/sensitive data | Done |
| Scope guard against legal/payroll promises | Done |
| Notification denial does not block in-app recording | Done |
| MVP scope kept below cloud/account/payment complexity | Done |

## Quality Metrics

| Metric | Result |
|---|---|
| `flutter analyze` | Passed |
| `flutter test` | Passed, 175 tests |
| `flutter build apk --debug` | Passed |
| `git --no-pager diff --check` | Passed |
| Real device smoke | Passed on `R3CM807B7DR` |
| GitHub Actions | Not configured |
| Production canary | Not applicable, Flutter Android app |

## Landed PRs

| PR | Result |
|---|---|
| PR #1 | MVP deletion flows merged |
| PR #2 | Work record calendar view merged |
| PR #4 | Work time rule candidates merged |
| PR #5 | Calendar overflow fix merged |

## Product Decisions Preserved

- WorkLedger remains a personal local work ledger, not a payroll calculator.
- Work tags mean “outside the user's regular work rule,” not normal weekday work.
- `정시 기준 외 근무 없음` is the correct empty state when completed records stay inside the configured work rule.
- `달력 보기` is for date-level record inspection. `월간 요약` remains the aggregate report screen.
- Pricing remains fake-door only. No real payment or real PDF/CSV generation is included.

## Scope Guard

The following are still out of scope and not implemented.

| Out-of-scope Item | Status |
|---|---|
| Server | Not included |
| Login/account | Not included |
| Cloud sync | Not included |
| GPS auto tracking | Not included |
| Company attendance integration | Not included |
| Legal advice or evidence guarantee | Not included |
| Automatic statutory leave calculation | Not included |
| Payroll accuracy guarantee | Not included |
| Real PDF/CSV generation | Not included |
| Real payment | Not included |
| Quick Settings Tile | Not included |
| Home widget | Not included |

## Concerns

| Concern | Impact | Follow-up |
|---|---|---|
| `.gstack/` land reports are untracked | Git status remains noisy | Decide whether to keep local-only, add ignore rule, or commit selected reports later |
| GitHub Actions not configured | No automatic PR checks | Add CI workflow before repeated external collaboration |
| Release signing not configured | Debug APK only | Prepare Android signing and AAB build when actual distribution is needed |
| No production URL | Canary deploy does not apply | Use APK build and real-device smoke as Android verification |

## Lessons Learned

- A small Android screen can expose calendar layout bugs that wide emulator screenshots miss.
- Calendar and monthly summary must have different jobs: calendar for daily inspection, monthly summary for aggregates.
- 0-minute work tag rows create false signal. A quiet empty state is clearer.
- Local-only Android apps need a different release check than web apps: analyze, tests, debug build, install, launch, smoke.

## Next Steps

1. Decide whether to move bkit status from `check` to `report`.
2. Decide how to handle untracked `.gstack/` land reports.
3. If preparing real distribution, create a separate Android release signing/AAB plan.
4. Start any new feature from a new branch after `main` is clean.
