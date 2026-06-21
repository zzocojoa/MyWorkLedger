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
| Data safety | NOT RUN | Internal-only releases are exempt from Data safety display, but production submission still requires the Play Console form; draft answers are in `docs/04-deploy/play-store/store-listing.md` |
| Ads declaration | NOT RUN | App has no ads SDK in current dependencies, but Play Console declaration is not verified |
| App access | NOT RUN | App does not require login in current build, but Play Console declaration is not verified |
| Content rating | NOT RUN | Play Console questionnaire required |
| Target audience | NOT RUN | Play Console questionnaire required |
| Store listing console entry | PASS | Listing text and image uploads were committed through Android Publisher API |
| Store listing text draft | PASS | `docs/04-deploy/play-store/store-listing.md` prepared |
| Store screenshots | PASS | Five phone screenshots prepared in `docs/04-deploy/play-store/screenshots/phone-upload/` |
| Feature graphic | PASS | `assets/brand/google-play/workledger-feature-graphic-1024x500.jpg`, 1024x500, no alpha |
| Internal test track upload | PASS | `versionCode=3` AAB upload, internal track update, edit validation, and edit commit succeeded through API |
| Upload warnings | PASS | `versionCode=2` was already used; rebuilt and uploaded `versionCode=3` successfully |
| Version code duplicate check | PASS | `versionCode=3` upload accepted |
| Internal test release notes | PASS | Release notes were included in committed API internal track update |
| Internal test device QA | PASS | Play Store internal-test install and smoke QA completed on `SM_G977N` |
| Production submit | NOT RUN | User approval required before production submission |

## Current API Readback

Read-only API verification on 2026-06-22 used edit `04123157826065938820`. The edit was not committed.

| Item | Status | Evidence |
|---|---|---|
| App details | PASS | `edits.details.get` returned default language `ko-KR` and contact email configured |
| Korean listing | PASS | `edits.listings.get` returned title `내근무장부`, short description, and full description |
| Internal track | PASS | `edits.tracks.get` returned release `1.0.2`, status `completed`, `versionCodes=["3"]` |
| Production track | NOT READY | `edits.tracks.get` returned no production releases |
| App icon | PASS | `edits.images.list` returned 1 `icon` image |
| Feature graphic | PASS | `edits.images.list` returned 1 `featureGraphic` image |
| Phone screenshots | PASS | `edits.images.list` returned 5 `phoneScreenshots` images |

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
| Edit validate | PASS | Latest retry returned HTTP 200 |
| Edit commit | PASS | Latest retry returned HTTP 200 |

Earlier retry on 2026-06-22 used edit `12012481448460999871`. Listing update, `icon`, `featureGraphic`, five `phoneScreenshots`, AAB `versionCode=3`, and internal track update all returned HTTP 200, but `edits.validate` returned HTTP 403 `The caller does not have permission`, so that edit was not committed.

Successful retry on 2026-06-22 used edit `14274543098808648932`. It deleted existing `phoneScreenshots`, uploaded the 5 prepared screenshots, uploaded `icon` and `featureGraphic`, uploaded AAB `versionCode=3`, updated the `internal` track, validated the edit, and committed the edit. All listed steps returned HTTP 200. A previous retry with edit `16891572003971870917` failed validation because the app had more than 8 `ko-KR` screenshots before `phoneScreenshots` was cleared.

Post-commit verification used read-only edit `18396962594213530106`. `edits.tracks.get` for `internal` returned HTTP 200 with release `1.0.2`, status `completed`, and `versionCodes=["3"]`.

## Permissions API Check

| Step | Status | Evidence |
|---|---|---|
| Users API parameter validation | PASS | `developers/{developer}/users` responded and required `pageSize=-1`, proving the endpoint is reachable |
| Users API permission check | FAIL | `developers/{developer}/users?pageSize=-1` returned HTTP 403 `You do not have permission to access this object` |
| Self-service permission escalation | NOT AVAILABLE | The current service account cannot inspect or update Play Console users and permissions through the API |

The current service account still cannot manage Play Console users and permissions through the API. App-specific release permissions are now sufficient for this internal testing release because edit validation and commit succeeded.

## Play Console Screen Check

| Item | Status | Evidence |
|---|---|---|
| Dashboard opened | PASS | Chrome shows Play Console dashboard for `내근무장부` |
| Package visible | PASS | Dashboard shows `com.workledger.workledger` |
| Draft state | PASS | Dashboard shows app draft state |
| Production | NOT READY | Dashboard shows production inactive |
| Closed testing | NOT READY | Dashboard says closed testing must be run before production access |
| Tester requirement | NOT READY | Dashboard shows 0 testers opted in; 12 testers and at least 14 days are required before production access |

## Internal Test Device QA

| Item | Status | Evidence |
|---|---|---|
| Device detected | PASS | `adb devices -l` showed `SM_G977N`, serial `R3CM807B7DR` |
| Internal-test install | PASS | Play Store internal-test page installed `com.workledger.workledger` |
| Installed version | PASS | `dumpsys package` showed `versionCode=3`, `versionName=1.0.2`, `targetSdk=36` |
| Release build sanity | PASS | Installed package flags did not include `DEBUGGABLE` |
| App launch | PASS | Home screen opened with `내근무장부` and today's work card |
| Current-time quick record | PASS | Initial smoke QA completed `출근하기` -> `퇴근하기` and produced a completed record |
| Test record cleanup | PASS | The QA-created `01:40 - 01:41` record was deleted through the app's `기록 삭제` flow |
| Choose-before-save setting | PASS | `근무 설정` selected and saved `저장 전 시각 선택` |
| Home quick record candidate UI | PASS | `출근하기` opened `출근 시각 선택` with `현재 시각`, `정시 출근`, and `직접 입력` candidates |
| Home quick record save | PASS | Selecting `현재 시각` saved a working record with `출근 01:45` |
| Persistent notification shown | PASS | Notification screen returned `상시 알림이 표시되었습니다.` and `dumpsys notification` showed notification id `1001` |
| Persistent notification actions | PASS | System notification exposed `출근하기` and `퇴근하기` actions |
| Notification action in choose-before-save mode | PASS | `퇴근하기` notification action opened `퇴근 시각 선택` with `현재 시각`, `정시 퇴근`, and `직접 입력`; selecting current time completed `01:45 - 01:47` |
| Test data cleanup | PASS | The QA-created `01:45 - 01:47` record was deleted through the app; final home state returned to `아직 출근 전` |

Note: the current release intentionally opens the candidate UI from notification actions when quick record mode is `저장 전 시각 선택`. This matches the shipped app copy and `shouldOpenQuickRecordFromNotification` tests. If the older acceptance criterion requires notification actions to save immediately regardless of mode, that criterion is not met by the current release and should be resolved as a product decision before treating that older criterion as binding.

## Submission Decision

Current status: `PARTIAL`.

Local build, signing, SDK, alignment, tests, privacy URL, store listing draft, screenshots, feature graphic, API asset upload, API AAB upload, internal track update, edit validation, edit commit, API readback, Play internal-test install, and internal test device QA are ready. Production submission still requires explicit user approval and is also blocked by Play Console's closed-testing requirement and remaining App content forms.

## Rollback

- Before commit: revert this readiness document and release metadata with `git restore -p`.
- After commit: use `git revert <commit>`.
- Before Play production submission: discard the Play Console draft or stop before submitting for review.
