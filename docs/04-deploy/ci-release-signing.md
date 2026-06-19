# CI release signing

WorkLedger는 GitHub Actions로 pull request와 `main` push 검증을 실행한다.

Workflow 파일은 `.github/workflows/flutter-ci.yml`이다.

## Checks

- `flutter analyze --no-pub`
- `flutter test --reporter=compact`
- `flutter build apk --release`
- `flutter build appbundle --release`
- SHA-256 hash printout for the release APK and AAB

## CI signing

PR CI와 `main` push CI는 runner 안에서 일회용 release signing key를 생성해
Android release build 경로를 검증한다. 이 키는 Google Play 업로드 키가 아니며,
빌드가 끝나면 runner와 함께 폐기된다.

현재 CI release build에는 GitHub repository secret이 필요하지 않다.

Workflow는 `android/app/workledger-ci-release-keystore.jks`를 생성하고
`android/key.properties`에 아래 값을 기록한다.

- `WORKLEDGER_RELEASE_STORE_FILE=workledger-ci-release-keystore.jks`
- `WORKLEDGER_RELEASE_STORE_PASSWORD`
- `WORKLEDGER_RELEASE_KEY_ALIAS`
- `WORKLEDGER_RELEASE_KEY_PASSWORD`

`android/key.properties`, `.jks`, `.keystore`, APK, AAB 파일은 커밋하지 않는다.

## Production signing

Google Play에 업로드할 release build는 실제 upload keystore로 서명한다.

현재 저장소의 Android Gradle 설정은 로컬 `android/key.properties`가 있으면 해당
파일을 읽어 release signing을 수행한다. 배포 담당자는 로컬 환경에 아래 파일을
준비한 뒤 release AAB를 생성한다.

- `android/app/workledger-upload-keystore.jks`
- `android/key.properties`

향후 GitHub Actions에서 Google Play 배포까지 자동화할 경우에는 별도 deploy
workflow를 만들고, production upload keystore는 GitHub repository secret 또는
environment secret으로 분리해 관리한다. PR 검증용 CI workflow에는 production
upload key를 연결하지 않는다.

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
