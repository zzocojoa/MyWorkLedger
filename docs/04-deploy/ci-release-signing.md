# CI release signing

WorkLedger는 GitHub Actions로 pull request와 `main` push 검증을 실행한다.

Workflow 파일은 `.github/workflows/flutter-ci.yml`이다.

## Checks

- `flutter analyze --no-pub`
- `flutter test --reporter=compact`
- `flutter build apk --release`
- `flutter build appbundle --release`
- SHA-256 hash printout for the release APK and AAB

## Required GitHub Secrets

CI를 병합 기준으로 쓰기 전에 아래 repository secret을 설정해야 한다.

| Secret | Value |
| --- | --- |
| `WORKLEDGER_RELEASE_KEYSTORE_BASE64` | Base64 text of `android/app/workledger-upload-keystore.jks` |
| `WORKLEDGER_RELEASE_STORE_PASSWORD` | Upload keystore store password |
| `WORKLEDGER_RELEASE_KEY_ALIAS` | Upload key alias |
| `WORKLEDGER_RELEASE_KEY_PASSWORD` | Upload key password |

CI stores the decoded keystore as `android/app/workledger-upload-keystore.jks`
and writes `WORKLEDGER_RELEASE_STORE_FILE=workledger-upload-keystore.jks` into
`android/key.properties`.

macOS에서 keystore base64 값은 아래 명령으로 만든다.

```bash
base64 < android/app/workledger-upload-keystore.jks | tr -d '\n'
```

`android/key.properties`, `.jks`, `.keystore`, APK, AAB 파일은 커밋하지 않는다.

## Keystore backup

아래 파일은 저장소 밖에 암호화된 백업을 1개 이상 보관한다.

- `android/app/workledger-upload-keystore.jks`
- `android/key.properties`

upload keystore를 잃으면 이후 Android 앱 업데이트 배포가 막힐 수 있다.

## Release artifact handling

Release APK와 AAB는 ignored 상태인 `build/` 아래에 생성되고 `flutter clean`으로
삭제된다.

Release candidate는 AAB와 SHA-256 hash를 GitHub Release 또는 별도 보안 release
archive에 보관한다. Git history를 binary artifact 저장소로 쓰지 않는다.
