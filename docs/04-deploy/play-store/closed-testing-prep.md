# Closed Testing Preparation

## Purpose

이 문서는 `내근무장부` / `WorkLedger`의 Google Play 프로덕션 접근을 위한 비공개 테스트 준비 입력값을 정리한다. 실제 테스터 이메일 주소는 개인정보이므로 저장소에 커밋하지 않는다.

## Current Verified State

| Item | State |
|---|---|
| Package | `com.workledger.workledger` |
| Release candidate | `1.0.2+3` |
| Internal track | Uploaded and smoke-tested |
| Production track | No releases |
| Closed/open legacy tracks | No releases on `beta` or `alpha` |
| Production access checklist | 0 of 5 tasks complete |
| Production application | Disabled |

## Decisions Needed Before Console Changes

| Decision | Required value | Current status |
|---|---|---|
| Countries and regions | Countries where testers can install the closed test | Not selected |
| Tester source | Email list or Google Group | Not selected |
| Tester count | At least 12 testers who can opt in | Not ready |
| Feedback channel | Email address or URL shown to testers | Not selected |
| Closed-test release artifact | Existing `1.0.2+3` bundle if Play Console allows reuse | Not confirmed |
| Review submission | Explicit approval to send closed-test release to Google | Not approved |

## Tester Collection Checklist

Use a local-only sheet or document outside the repository for tester emails.

| Check | Requirement |
|---|---|
| Google account | Each tester email must be a Google account that can use Google Play |
| Opt-in readiness | Each tester must be able to open the opt-in link and join the test |
| Region match | Each tester must be in a selected closed-test country or region |
| Device access | Each tester should have an Android device compatible with the app |
| 14-day availability | Each tester should remain opted in for 14 continuous days |
| Feedback path | Each tester should know where to report install or app issues |

## Console Execution Checklist

Proceed only after the decisions above are filled.

1. Open Play Console dashboard for `내근무장부`.
2. Open `할 일 보기` under the closed-testing production-access card.
3. Select countries and regions.
4. Select or create the tester source.
5. Add the feedback channel.
6. Create the closed-testing release.
7. Reuse `1.0.2+3` if available; otherwise stop and decide whether to bump version.
8. Add release notes from `store-listing.md`.
9. Preview and confirm the release.
10. Ask for explicit approval before sending the closed-testing release to Google for review.
11. After approval, share the opt-in link with testers.
12. Track opted-in tester count and the 14 continuous days requirement.
13. Apply for production access only after Play Console enables it.

## Stop Conditions

| Condition | Action |
|---|---|
| Fewer than 12 testers available | Do not send as production-ready; continue tester recruitment |
| Play Console rejects bundle reuse | Stop and decide whether to bump `pubspec.yaml` version |
| Policy or app-content warning appears | Capture the warning and resolve before review submission |
| Feedback channel is missing | Do not continue; closed test setup needs a tester feedback path |
| Final review submission button appears | Ask for explicit user approval before clicking |

## Evidence To Record After Setup

| Evidence | Destination |
|---|---|
| Selected countries and regions | `google-play-release-readiness.md` |
| Tester source type, without raw tester emails | `google-play-release-readiness.md` |
| Feedback channel type, without private addresses if sensitive | `google-play-release-readiness.md` |
| Closed-test release version and track | `google-play-release-readiness.md` |
| Review submission result | `google-play-release-readiness.md` |
| Opt-in count and start date | `google-play-release-readiness.md` |
