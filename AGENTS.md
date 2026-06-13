# WorkLedger Project Instructions

## Product Boundary

- App Korean name: `내근무장부`
- App English name: `WorkLedger`
- Primary platform: Flutter Android
- MVP source of truth: `docs/01-plan/features/workledger-mvp.plan.md`
- The app starts without accounts and stores core data locally.
- The MVP must focus on 10-second work logging, persistent notification actions for clock-in/clock-out, manual remaining leave tracking, monthly summary, and pricing/fake-door click measurement.

## Explicitly Out Of Scope

- Do not implement servers, login, cloud sync, AI, GPS auto tracking, company attendance system integration, legal advice, evidence-validity guarantees, automatic statutory leave calculation, payroll accuracy guarantees, real PDF/CSV report generation, real payment, Quick Settings Tile, or home widgets unless the plan is explicitly updated and approved.
- Do not require company name, location, or sensitive personal information.
- Do not add fallback behavior unless explicitly requested. Fix root causes and raise clear errors.

## Code Style

- Comments in code must be Korean only.
- Prefer functional programming over OOP.
- Use OOP classes only for connectors and interfaces to external systems.
- Write pure functions where possible. Do not modify input parameters or global state.
- Follow DRY, KISS, and YAGNI.
- Use strict typing everywhere: function returns, variables, collections, and model fields.
- Check whether logic already exists before adding new code.
- Avoid untyped variables, generic types without concrete parameters, and multi-mode functions.
- Never use default parameter values. Make all parameters explicit.
- Create named type definitions for complex data structures.
- Keep imports at the top of each Dart file.
- Keep functions small and single-purpose. Avoid boolean flag parameters that switch behavior.

## Flutter And Dart Rules

- Use feature-first folders under `lib/features`.
- Keep shared domain models under `lib/core/models` only when reused by multiple features.
- Keep local persistence under `lib/core/storage`.
- Keep notification integration under `lib/core/notifications`.
- Keep app strings under `lib/l10n` or an equivalent Flutter i18n structure.
- Korean is the default UI language. English structure must exist, but full English translation can remain minimal for MVP.
- Prefer immutable data classes with explicit `copyWith`, `toMap`, and `fromMap` behavior when local storage needs serialization.
- Use `DateTime` in app code and persist timestamps as ISO-8601 strings or integer epoch values consistently.
- Use `Duration` for work-time calculations instead of raw integers in business logic.
- Keep calculation logic separate from widgets.

## Data Model Scope

- `WorkRecord`: work date, clock-in time, clock-out time, tags, memo, created time, updated time.
- `LeaveBalance`: year, total leave days, manual adjustment fields if needed, created time, updated time.
- `LeaveUsage`: usage date, used days, memo, created time, updated time.
- `PricingIntentEvent`: event type, selected plan, occurrence time.
- Leave remaining is based only on user-entered total leave and user-entered usage. Do not implement automatic legal leave calculation.

## Error Handling

- Always raise errors explicitly. Never silently ignore failures.
- Use specific error types that describe what failed.
- Avoid catch-all exception handlers that hide root causes.
- Error messages must include actionable context such as storage key, table name, request parameters, response body, and status code when relevant.
- External API/service calls are not part of MVP. If later approved, use retries with warnings and then raise the last error.
- Use structured logging fields instead of interpolating dynamic values into log messages.

## Tooling And Dependencies

- Prefer project-managed files such as `pubspec.yaml`.
- Add dependencies to project config files, not as one-off global installs.
- Install dependencies in project environments, not globally.
- Read installed dependency source when behavior is unclear.
- Use non-interactive commands with flags.
- Prefer `rg` for code search.
- Use `git --no-pager diff` or `git diff | cat` for diffs.

## Git Workflow

- Check whether the project is a Git repository before branch or commit work.
- Do not commit without explicit user approval.
- If Flutter project initialization happens on `main`, recommend an initial setup commit before MVP feature work.
- Actual MVP feature work should happen on `feature/mvp-workledger`.
- Never revert unrelated changes.
- If existing changes are present, inspect them with `git --no-pager diff` and work around them.

## Validation

- After code changes, run the relevant project-defined commands when available.
- For Flutter changes, prefer `flutter analyze` and `flutter test` once Flutter is available.
- For Android-specific work, verify Android project generation and manifest/package settings.

# bkit Project Configuration

## Project Level

This project uses bkit with automatic level detection.
Call `bkit_detect_level` at session start to determine the current level.

### Level-Specific Guidance

**Starter** (beginners, static websites):
- Use simple HTML/CSS/JS or Next.js App Router
- Skip API and database phases
- Pipeline phases: 1 -> 2 -> 3 -> 6 -> 9
- Use `$starter` skill for beginner guidance

**Dynamic** (fullstack with BaaS):
- Use bkend.ai for backend services
- Follow phases: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 9 (phase 8 optional)
- Use `$dynamic` skill for fullstack guidance

**Enterprise** (microservices, K8s):
- All 9 phases required
- Use `$enterprise` skill for MSA guidance

## PDCA Status

ALWAYS check `docs/.pdca-status.json` for current feature status.
Use `bkit_get_status` MCP tool for parsed status with recommendations.

## Key Skills

| Skill | Purpose |
|-------|---------|
| `$pdca` | Unified PDCA workflow (plan, design, do, analyze, iterate, report) |
| `$plan-plus` | Brainstorming-enhanced planning (6 phases, HARD GATE) |
| `$starter` / `$dynamic` / `$enterprise` | Level-specific guidance |
| `$development-pipeline` | 9-phase pipeline overview |
| `$code-review` | Code quality analysis with static analysis patterns |
| `$bkit-templates` | PDCA document template selection |

## Response Format (MANDATORY)

### Starter Level (bkit-learning style)
ALWAYS include at the end of each response:
- **Learning Points**: 3-5 key concepts the user should learn
- **Next Learning Step**: What to study or practice next
- Use simple terms, avoid jargon. Use "Did you know?" callouts.

### Dynamic Level (bkit-pdca-guide style)
ALWAYS include at the end of each response:
- **PDCA Status Badge**: `[Feature: X | Phase: Y | Progress: Z%]`
- **Checklist**: What's done and what remains
- **Next Step**: Specific action with command/tool suggestion

### Enterprise Level (bkit-enterprise style)
ALWAYS include at the end of each response:
- **Tradeoff Analysis**: Pros/Cons of the approach taken
- **Cost Impact**: Development time, infrastructure cost, maintenance burden
- **Deployment Considerations**: Environment-specific notes

## Team Workflow (Single Agent Mode)

When working on complex features:
1. Break the task into PDCA phases (Plan -> Design -> Do -> Check -> Report)
2. For each phase, apply the relevant specialist perspective:
   - Plan: Product Manager + CTO perspective
   - Design: Architect + Security perspective
   - Do: Developer + Frontend/Backend perspective
   - Check: QA + Code Reviewer perspective
   - Report: Documentation perspective
3. Use `bkit_pdca_next` to transition between phases
4. Quality gates: Each phase must be documented before proceeding
