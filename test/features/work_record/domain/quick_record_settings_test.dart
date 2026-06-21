import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/features/work_record/domain/quick_record_settings.dart';

void main() {
  group('QuickRecordSettings', () {
    test('serializes and parses quick record mode', () {
      final QuickRecordSettings settings = QuickRecordSettings(
        mode: QuickRecordMode.chooseBeforeSave,
        createdAt: DateTime.parse('2026-06-12T08:00:00'),
        updatedAt: DateTime.parse('2026-06-12T09:00:00'),
      );

      final QuickRecordSettings parsed = QuickRecordSettings.fromMap(
        settings.toMap(),
      );

      expect(parsed, settings);
    });

    test('throws for unknown mode values', () {
      expect(
        () => QuickRecordSettings.fromMap(<String, Object?>{
          'mode': 'automaticCorrection',
          'created_at': '2026-06-12T08:00:00',
          'updated_at': '2026-06-12T09:00:00',
        }),
        throwsA(isA<QuickRecordSettingsParseException>()),
      );
    });

    test('throws when updated time is before created time', () {
      expect(
        () => QuickRecordSettings.fromMap(<String, Object?>{
          'mode': 'currentTimeOnly',
          'created_at': '2026-06-12T09:00:00',
          'updated_at': '2026-06-12T08:00:00',
        }),
        throwsA(isA<QuickRecordSettingsParseException>()),
      );
    });
  });
}
