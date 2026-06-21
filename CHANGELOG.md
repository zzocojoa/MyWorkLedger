# Changelog

All notable changes to WorkLedger are documented in this file.

## [0.1.0.0] - 2026-06-21

### Added
- Users can choose a quick record mode for work records: save the current time immediately or select a time before saving.
- Work record quick save now supports current time, regular work-rule time, and direct `HH:mm` input before saving.
- Persistent notification clock-in and clock-out actions respect the selected quick record mode.
- Quick record settings are stored locally with explicit parsing and validation.

### Changed
- The default current-time flow keeps the existing one-tap clock-in and clock-out behavior.
- Work record home, settings, notification, and local repository tests now cover quick record mode behavior.
- Local key-value storage now serializes write and delete mutations across adapters, isolates, and Dart processes.

### Fixed
- Clock-in and clock-out now use one clock value across the midnight boundary for work date and saved timestamp consistency.
- Notification quick-record launch handling now preserves the choose-before-save flow after app cold start.
- Temporary storage write failures preserve the existing storage file.
