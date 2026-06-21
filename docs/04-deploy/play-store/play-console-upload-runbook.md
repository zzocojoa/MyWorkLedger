# Play Console Upload Runbook

## Purpose

이 문서는 `내근무장부` / `WorkLedger`를 Google Play Console 내부 테스트 트랙에 올릴 때 따라갈 순서를 기록한다.

## Before You Start

| Item | Value |
|---|---|
| Package name | `com.workledger.workledger` |
| Version | `1.0.2+3` |
| AAB | `build/app/outputs/bundle/release/app-release.aab` |
| Privacy policy URL | `https://zzocojoa.github.io/MyWorkLedger/privacy-policy/` |
| Store listing draft | `docs/04-deploy/play-store/store-listing.md` |

## Files To Upload

| Console Field | File |
|---|---|
| App icon | `assets/brand/google-play/workledger-play-icon-512.png` |
| Feature graphic | `assets/brand/google-play/workledger-feature-graphic-1024x500.jpg` |
| Phone screenshots | `docs/04-deploy/play-store/screenshots/phone-upload/*.jpg` |
| App bundle | `build/app/outputs/bundle/release/app-release.aab` |

## Console Steps

1. Open Google Play Console.
2. Select or create the app for `내근무장부` / `WorkLedger`.
3. Confirm the package name is `com.workledger.workledger`.
4. Go to **Policy and programs > App content**.
5. Enter the privacy policy URL.
6. Complete Data safety with local-only storage, no account, no server sync, no ads SDK, and no payment SDK.
7. Complete Ads, App access, Content rating, and Target audience.
8. Go to **Store presence > Main store listing**.
9. Paste the short description, full description, and release notes from `store-listing.md`.
10. Upload the app icon, feature graphic, and phone screenshots.
11. Review the store preview for cropping or unreadable text.
12. Go to **Testing > Internal testing**.
13. Create or edit an internal testing release.
14. Upload `app-release.aab`.
15. Check for versionCode, SDK, permission, signing, and policy warnings.
16. Add release notes from `store-listing.md`.
17. Start internal testing.
18. Install the internal test build on a real Android device.
19. Smoke test 출근/퇴근, 저장 전 시각 선택, 상시 알림 액션, 자정 정책 핵심 흐름.
20. Do not submit production review until the user explicitly approves production submission.

## Current API Attempt

The Android Publisher API edit reached these states on 2026-06-22:

| Step | Result |
|---|---|
| Store listing text and image upload | PASS |
| AAB upload | PASS, `versionCode=3` |
| Internal testing track update | PASS |
| Edit validate | PASS |
| Edit commit | PASS |

Earlier API retry used edit `12012481448460999871`. Use image type `icon` for the Play app icon; `appIcon` is rejected by the Android Publisher API.

Successful API retry used edit `14274543098808648932`. Before uploading phone screenshots, call `edits.images.deleteall` for `phoneScreenshots`; otherwise validation can fail with more than 8 screenshots for `ko-KR`. The successful retry committed the internal track release for `versionCode=3`.

Post-commit verification used read-only edit `18396962594213530106`. `edits.tracks.get` for `internal` returned release `1.0.2`, status `completed`, and `versionCodes=["3"]`.

Permissions API self-check:

| Step | Result |
|---|---|
| `developers/{developer}/users?pageSize=-1` | FAIL, HTTP 403 `You do not have permission to access this object` |
| Current service account can grant itself permissions | NO |

To continue in Play Console, verify the internal testing release in the console, install the internal test build on a real device, and run smoke QA. Production review submission is still separate and must not be done without explicit user approval.

## PASS Criteria

- App content sections show no required action.
- Store listing preview is complete and visually acceptable.
- Internal testing release accepts `versionCode=3`.
- Play upload warnings are absent or resolved.
- Internal test install works on a real device.
- Smoke QA passes without data loss, crash, or notification action failure.

## If Something Fails

| Failure | Action |
|---|---|
| versionCode duplicate | Increase `pubspec.yaml` build number and rebuild AAB |
| Data safety warning | Recheck app dependencies and privacy policy wording |
| Asset rejected | Regenerate the rejected image with the required dimensions or format |
| Signing rejected | Confirm Play App Signing/upload key setup |
| Internal test install fails | Capture the Play Console error and device install error before changing code |
