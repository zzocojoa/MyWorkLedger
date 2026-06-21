# TODOS

## Work Record

### Add duplicate notification request regression test

**What:** Add a focused regression test for repeated quick-record notification requests.

**Why:** The current notification and home screen tests cover the accepted behavior, but a dedicated duplicate-request test would make this edge case easier to diagnose if it regresses.

**Context:** `docs/04-report/work-record-quick-record-mode.report.md` tracks this as NONBLOCK-03. Cover the case where multiple notification actions are requested before the home screen drains the pending action.

**Effort:** S
**Priority:** P1
**Depends on:** None

### Decide choose-before-save midnight date policy

**What:** Decide which work date should be used when a user opens the choose-before-save flow around midnight.

**Why:** The current implementation preserves the explicit same-date validation policy. A product decision is still needed for users who start a record before midnight and finish after midnight.

**Context:** `docs/03-analysis/work-record-quick-record-mode.analysis.md` and `docs/04-report/work-record-quick-record-mode.report.md` defer this as a separate product policy decision.

**Effort:** M
**Priority:** P2
**Depends on:** None

## Completed
