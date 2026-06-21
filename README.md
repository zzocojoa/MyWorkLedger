# WorkLedger

내근무장부 Android MVP입니다.

## Current MVP Capabilities

- Record clock-in and clock-out locally without an account.
- Use the persistent Android notification to clock in and clock out quickly.
- Choose how quick work records are saved: current time immediately, or select the time before saving.
- Pick current time, regular work-rule time, or direct `HH:mm` input in choose-before-save mode.
- Track leave manually and review monthly work summaries.

## Project Documents

- [MVP plan](docs/archive/2026-06/workledger-mvp/workledger-mvp.plan.md)
- [Quick record mode plan](docs/01-plan/features/work-record-quick-record-mode.plan.md)
- [Quick record mode design](docs/02-design/features/work-record-quick-record-mode.design.md)
- [Quick record mode report](docs/04-report/work-record-quick-record-mode.report.md)
- [Changelog](CHANGELOG.md)
- [TODOs](TODOS.md)

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

## Design And Brand Assets

Logo, launcher icon, splash, and Play Store asset rules are documented in:

```text
docs/02-design/logo-asset-spec.md
docs/02-design/logo-concepts.md
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
