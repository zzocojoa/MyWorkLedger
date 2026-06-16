# WorkLedger

내근무장부 Android MVP입니다.

## Development

Flutter SDK is expected at:

```bash
$HOME/.local/share/flutter-stable/bin/flutter
```

Useful commands:

```bash
$HOME/.local/share/flutter-stable/bin/flutter analyze
$HOME/.local/share/flutter-stable/bin/flutter test
```

## Android Release Signing

Release builds require upload key values in `android/key.properties` or matching
environment variables. Do not commit the keystore or `key.properties`.

```properties
WORKLEDGER_RELEASE_STORE_FILE=/absolute/path/to/workledger-upload-keystore.jks
WORKLEDGER_RELEASE_STORE_PASSWORD=...
WORKLEDGER_RELEASE_KEY_ALIAS=workledger-upload
WORKLEDGER_RELEASE_KEY_PASSWORD=...
```

On this machine, the upload keystore backup is stored outside the repository at:

```text
$HOME/Library/Application Support/WorkLedger/secrets/
```

The same signing values are also saved in macOS Keychain using these item names:

```text
WorkLedger Android release store file
WorkLedger Android release store password
WorkLedger Android release key alias
WorkLedger Android release key password
```

Build the Play Store artifact with:

```bash
$HOME/.local/share/flutter-stable/bin/flutter build appbundle --release
```
