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
| Latest CI | PASS | GitHub Actions `Flutter CI` run `27912558815` completed successfully for HEAD `ec8746d4bb4473a80a48373916f7ff329dbb5cb0` |
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

## Git Working Tree Notes

Current Git status on 2026-06-22 still includes four untracked files under `assets/brand 2/`.
They are byte-identical duplicates of the tracked files under `assets/brand/` and are not release inputs.
They should not be committed as part of the Play release unless a separate asset-directory decision is made.

| Untracked file | Tracked duplicate | SHA-256 |
|---|---|---|
| `assets/brand 2/google-play/workledger-play-icon-512.png` | `assets/brand/google-play/workledger-play-icon-512.png` | `badc55aab69799acfd94212a670f4fa5c6f0265eed1ea57763579906de227fc4` |
| `assets/brand 2/source/workledger-logo-master.svg` | `assets/brand/source/workledger-logo-master.svg` | `e94d53cb3e004e81ba16c97149eff69cb477b1305e60d47ba9847af29999e97a` |
| `assets/brand 2/source/workledger-logo-preview-1024.png` | `assets/brand/source/workledger-logo-preview-1024.png` | `51389b3c419cbc30219102e98a09d61672330a433f2f38c1209b0195b3735022` |
| `assets/brand 2/source/workledger-logo-transparent-1024.png` | `assets/brand/source/workledger-logo-transparent-1024.png` | `885c23c155a8bbd8a7a109fe4fffcb24dc0f87dae139d0f01b92873dadc8b87c` |

## Play Console Checklist

| Item | Status | Note |
|---|---|---|
| App exists or selected | PASS | Android Publisher API accepted package `com.workledger.workledger` edits |
| Privacy policy URL entered | PASS | Store listing edit sent `https://zzocojoa.github.io/MyWorkLedger/privacy-policy/` through Android Publisher API |
| Data safety | DRAFT_NOT_SUBMITTED | Play Console publishing overview lists `데이터 보안 설문지 작성` as an unsubmitted app-content change |
| Ads declaration | DRAFT_NOT_SUBMITTED | Play Console publishing overview lists `광고 선언 업데이트` as an unsubmitted app-content change |
| App access | DRAFT_NOT_SUBMITTED | Play Console publishing overview lists login details as submitted content not yet published: `특수한 액세스 권한 없이 모든 기능 사용 가능` |
| Content rating | DRAFT_NOT_SUBMITTED | Play Console publishing overview lists `콘텐츠 등급` with `새 설문지 제출` as an unsubmitted app-content change |
| Target audience | DRAFT_NOT_SUBMITTED | Play Console publishing overview lists target audience as `만 18세 이상` but the change is not submitted for review |
| Store listing console entry | PASS | Listing text and image uploads were committed through Android Publisher API |
| Store listing text draft | PASS | `docs/04-deploy/play-store/store-listing.md` prepared |
| Store screenshots | PASS | Five phone screenshots prepared in `docs/04-deploy/play-store/screenshots/phone-upload/` |
| App category | DRAFT_NOT_SUBMITTED | Play Console publishing overview lists app category as `생산성 앱` but the change is not submitted for review |
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
| Closed/open legacy testing tracks | NOT READY | `edits.tracks.list` returned no releases on `beta` or `alpha` |
| App icon | PASS | `edits.images.list` returned 1 `icon` image |
| Feature graphic | PASS | `edits.images.list` returned 1 `featureGraphic` image |
| Phone screenshots | PASS | `edits.images.list` returned 5 `phoneScreenshots` images |

Read-only track-list verification on 2026-06-22 used edit `10388814169983200170`. The edit was not committed. `edits.tracks.list` returned `production`, `beta`, and `alpha` with zero releases, and `internal` with one completed `1.0.2` release for `versionCode=3`.

Second read-only track-list verification on 2026-06-22 used edit `08159576147300272370`. The edit was not committed. `edits.tracks.list` again returned `production`, `beta`, and `alpha` with zero releases, and `internal` with one completed `1.0.2` release for `versionCode=3`.

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

Current read-only Chrome verification on 2026-06-22 confirmed the dashboard is still on the same production-access blocker state: the app is in draft, closed-testing setup shows 0 of 5 tasks completed, current opted-in tester count is 0, and the production application button is disabled.

| Item | Status | Evidence |
|---|---|---|
| Dashboard opened | PASS | Chrome shows Play Console dashboard for `내근무장부` |
| Package visible | PASS | Dashboard shows `com.workledger.workledger` |
| Draft state | PASS | Dashboard shows app draft state |
| Production | NOT READY | Dashboard shows production inactive |
| Closed testing | NOT READY | Dashboard says closed testing must be run before production access |
| Tester requirement | NOT READY | Dashboard shows 0 testers opted in; 12 testers and at least 14 days are required before production access |
| Closed testing task list | NOT READY | Dashboard `할 일 보기` showed 0 of 5 production-access closed-testing tasks completed |

## Play Console Publishing Overview Check

Read-only browser verification on 2026-06-22 showed the Play Console publishing overview for `내근무장부`.

| Item | Status | Evidence |
|---|---|---|
| Publishing overview opened | PASS | URL `.../app/4975751448796517471/publishing` displayed `게시 개요` |
| Review submission button | BLOCKED | `검토를 위해 앱 전송` button was disabled |
| Required dashboard steps | BLOCKED | Page stated `검토를 위해 변경사항을 전송하려면 앱 대시보드에서 필수 단계를 완료하세요.` |
| Store listing draft | DRAFT_NOT_SUBMITTED | Change list included `한국어 - ko-KR` default store listing and said all required information was provided |
| Content rating draft | DRAFT_NOT_SUBMITTED | Change list included `콘텐츠 등급` with `새 설문지 제출` |
| Target audience draft | DRAFT_NOT_SUBMITTED | Change list included target audience update with `만 18세 이상` |
| Privacy policy draft | DRAFT_NOT_SUBMITTED | Change list included privacy policy URL `https://zzocojoa.github.io/MyWorkLedger/privacy-policy/` |
| Ads declaration draft | DRAFT_NOT_SUBMITTED | Change list included `광고 선언 업데이트` |
| Data safety draft | DRAFT_NOT_SUBMITTED | Change list included `데이터 보안 설문지 작성` |
| App category draft | DRAFT_NOT_SUBMITTED | Change list included app category `생산성 앱` |
| App access declaration | DRAFT_NOT_SUBMITTED | Submitted-content list included login details: all features available without special access |
| Government app declaration | DRAFT_NOT_SUBMITTED | Submitted-content list included government app declaration update |
| Financial features declaration | DRAFT_NOT_SUBMITTED | Submitted-content list included financial features declaration update |
| Health declaration | DRAFT_NOT_SUBMITTED | Submitted-content list included health-related declaration update |

## Closed Testing Production Access Checklist

Read-only browser verification on 2026-06-22 expanded the dashboard `할 일 보기` checklist under `앱 문제를 파악하고 의견을 얻고 프로덕션 액세스 권한을 확보하세요`.

| Item | Status | Evidence |
|---|---|---|
| Checklist progress | NOT READY | Dashboard stated `완료된 작업 5개 중 0개` |
| Country and region selection | NOT READY | Checklist showed `국가 및 지역 선택` as an available task |
| Tester selection | NOT READY | Checklist showed `테스터 선택` as an available task |
| Closed testing release creation | NOT READY | Checklist showed `새 버전 만들기` as an available task |
| Preview and confirmation | LOCKED | Checklist showed `버전 미리보기 및 확인` as locked until a new release is created |
| Send closed testing release to Google for review | LOCKED | Checklist showed `검토를 위해 Google에 버전 전송` as locked |
| Production access application | BLOCKED | Dashboard still showed `프로덕션 신청` disabled |

This closed-testing checklist is separate from the already uploaded Android Publisher API `internal` track release. It is the Play Console production-access path and remains incomplete.

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
| Notification action in choose-before-save mode | PENDING | `1.0.4+5` changes notification actions to save immediately without opening candidate UI; Play-installed real-device smoke must be rerun |
| Test data cleanup | PASS | The QA-created `01:45 - 01:47` record was deleted through the app; final home state returned to `아직 출근 전` |

Note: `1.0.4+5` restores the older acceptance criterion: notification actions save immediately regardless of quick record mode. The previous `1.0.2+3` real-device evidence that opened candidate UI is no longer sufficient for release readiness.

## Submission Decision

Current status: `PARTIAL`.

Local build, signing, SDK, alignment, tests, privacy URL, store listing draft, screenshots, feature graphic, API asset upload, API AAB upload, internal track update, edit validation, edit commit, and API readback are ready. Play-installed `1.0.4+5` device smoke QA remains pending. Production submission still requires explicit user approval and is also blocked by Play Console's closed-testing requirement and remaining App content forms.

## Rollback

- Before commit: revert this readiness document and release metadata with `git restore -p`.
- After commit: use `git revert <commit>`.
- Before Play production submission: discard the Play Console draft or stop before submitting for review.
