# Google Play Release Readiness

## Scope

이 문서는 `내근무장부` / `WorkLedger`의 Google Play 제출 전 로컬 검증과 Play Console 수동 확인 상태를 기록한다.

## Release Candidate

| Item | Value |
|---|---|
| Date | 2026-06-22 |
| Branch | `main` |
| Package | `com.workledger.workledger` |
| Version | `1.0.2+3` |
| Version name | `1.0.2` |
| Version code | `3` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |
| APK | `build/app/outputs/flutter-apk/app-release.apk` |

## Local Verification

| Check | Status | Evidence |
|---|---|---|
| Main sync | PASS | `git rev-list --left-right --count main...origin/main` -> `0 0` |
| Diff whitespace | PASS | `git --no-pager diff --check` exit 0 |
| Analyze | PASS | `flutter analyze --no-pub` exit 0, no issues |
| Tests | PASS | `flutter test --reporter=compact` exit 0, 297 tests passed |
| Release AAB | PASS | `flutter build appbundle --release` exit 0 |
| Release APK | PASS | `flutter build apk --release` exit 0 |
| APK signing | PASS | `apksigner verify --verbose --print-certs` exit 0 |
| AAB signing | PASS | `jarsigner -verify` exit 0, `jar verified` |
| Target SDK | PASS | `targetSdkVersion:'36'` |
| Min SDK | PASS | `sdkVersion:'24'` |
| 16KB alignment | PASS | `zipalign -c -P 16 -v 4` exit 0, verification successful |
| Privacy URL | PASS | `curl -I -L https://zzocojoa.github.io/MyWorkLedger/privacy-policy/` -> HTTP 200 |

## Artifact Hashes

| File | SHA-256 |
|---|---|
| `app-release.aab` | `7a5abd00e7af36dfbacb0d77706ad86700517b5e9702792d81118f248bdb95ce` |
| `app-release.apk` | `1607b1b97575913436a6d2fceb11fff43de0645373eed3910a08645aed5bc988` |

## Play Console Checklist

| Item | Status | Note |
|---|---|---|
| App exists or selected | PASS | Android Publisher API accepted package `com.workledger.workledger` edits |
| Privacy policy URL entered | PASS | Store listing edit sent `https://zzocojoa.github.io/MyWorkLedger/privacy-policy/` through Android Publisher API |
| Data safety | NOT RUN | Must be verified in Play Console questionnaire; draft answers are in `docs/04-deploy/play-store/store-listing.md` |
| Ads declaration | NOT RUN | App has no ads SDK in current dependencies, but Play Console declaration is not verified |
| App access | NOT RUN | App does not require login in current build, but Play Console declaration is not verified |
| Content rating | NOT RUN | Play Console questionnaire required |
| Target audience | NOT RUN | Play Console questionnaire required |
| Store listing console entry | PARTIAL | Listing text and image uploads were accepted by Android Publisher API in an uncommitted edit |
| Store listing text draft | PASS | `docs/04-deploy/play-store/store-listing.md` prepared |
| Store screenshots | PASS | Five phone screenshots prepared in `docs/04-deploy/play-store/screenshots/phone-upload/` |
| Feature graphic | PASS | `assets/brand/google-play/workledger-feature-graphic-1024x500.jpg`, 1024x500, no alpha |
| Internal test track upload | PARTIAL | `versionCode=3` AAB upload and internal track update succeeded through API, but edit commit failed |
| Upload warnings | PASS | `versionCode=2` was already used; rebuilt and uploaded `versionCode=3` successfully |
| Version code duplicate check | PASS | `versionCode=3` upload accepted |
| Internal test release notes | PARTIAL | Release notes were included in API internal track update, but edit commit failed |
| Internal test device QA | NOT RUN | Requires Play internal-test installation |
| Production submit | NOT RUN | User approval required before production submission |

## Android Publisher API Result

| Step | Status | Evidence |
|---|---|---|
| Service account authentication | PASS | `reviews.list` returned HTTP 200 with `reviews_count=0` |
| Store listing update | PASS | `edits.listings.update` accepted `ko-KR` listing fields |
| App icon upload | PASS | `edits.images.upload` accepted `icon` |
| Feature graphic upload | PASS | `edits.images.upload` accepted `featureGraphic` |
| Phone screenshots upload | PASS | `edits.images.upload` accepted five `phoneScreenshots` |
| AAB upload | PASS | `edits.bundles.upload` accepted `versionCode=3` |
| Internal track update | PASS | `edits.tracks.update` accepted `versionCode=3` on `internal` |
| Edit validate | FAIL | `edits.validate` returned HTTP 403 `The caller does not have permission` |
| Edit commit | FAIL | `edits.commit` returned HTTP 403 `The caller does not have permission` |

Latest retry on 2026-06-22 used edit `12012481448460999871`. Listing update, `icon`, `featureGraphic`, five `phoneScreenshots`, AAB `versionCode=3`, and internal track update all returned HTTP 200. `edits.validate` still returned HTTP 403 `The caller does not have permission`, so the edit was not committed.

## Permissions API Check

| Step | Status | Evidence |
|---|---|---|
| Users API parameter validation | PASS | `developers/{developer}/users` responded and required `pageSize=-1`, proving the endpoint is reachable |
| Users API permission check | FAIL | `developers/{developer}/users?pageSize=-1` returned HTTP 403 `You do not have permission to access this object` |
| Self-service permission escalation | NOT AVAILABLE | The current service account cannot inspect or update Play Console users and permissions through the API |

Required Play Console permissions must be granted by an existing owner or admin. For this release workflow, grant enough permissions for store presence, internal testing releases, app content, tester management if tester lists are managed through API, and edit validation/commit.

## Play Console Screen Check

| Item | Status | Evidence |
|---|---|---|
| Dashboard opened | PASS | Chrome shows Play Console dashboard for `내근무장부` |
| Package visible | PASS | Dashboard shows `com.workledger.workledger` |
| Draft state | PASS | Dashboard shows app draft state |
| Production | NOT READY | Dashboard shows production inactive |
| Closed testing | NOT READY | Dashboard says closed testing must be run before production access |
| Tester requirement | NOT READY | Dashboard shows 0 testers opted in; 12 testers and at least 14 days are required before production access |

## Submission Decision

Current status: `PARTIAL`.

Local build, signing, SDK, alignment, tests, privacy URL, store listing draft, screenshots, feature graphic, API asset upload, API AAB upload, and API internal track update are ready. Google Play submission is not ready because the service account can edit but cannot validate or commit the Play edit. The current service account also cannot grant itself more Play Console permissions through the Permissions API. Internal test QA cannot start until a Play Console user with sufficient permission commits the edit or grants the service account the required release permission. Production submission still requires explicit user approval and is also blocked by Play Console's closed-testing requirement.

## Rollback

- Before commit: revert this readiness document and release metadata with `git restore -p`.
- After commit: use `git revert <commit>`.
- Before Play production submission: discard the Play Console draft or stop before submitting for review.
