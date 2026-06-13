import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';

void main() {
  group('WorkRecord', () {
    test('serializes and parses a full record', () {
      final DateTime createdAt = DateTime.parse('2026-06-12T09:03:00');
      final DateTime updatedAt = DateTime.parse('2026-06-12T18:42:00');
      final WorkRecord record = WorkRecord(
        id: 'work-1',
        workDate: DateTime(2026, 6, 12),
        clockInAt: DateTime.parse('2026-06-12T09:03:00'),
        clockOutAt: DateTime.parse('2026-06-12T18:42:00'),
        tags: <WorkRecordTag>[
          WorkRecordTag.overtime,
          WorkRecordTag.delayedCheckout,
        ],
        memo: '배포 대응 후 퇴근',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final Map<String, Object?> map = record.toMap();
      final WorkRecord parsed = WorkRecord.fromMap(map);

      expect(map['work_date'], '2026-06-12');
      expect(map['clock_in_at'], '2026-06-12T09:03:00.000');
      expect(map['clock_out_at'], '2026-06-12T18:42:00.000');
      expect(map['tags'], <String>['overtime', 'delayedCheckout']);
      expect(parsed, record);
    });

    test('copyWith requires explicit values and returns a changed record', () {
      final WorkRecord record = WorkRecord(
        id: 'work-1',
        workDate: DateTime(2026, 6, 12),
        clockInAt: DateTime.parse('2026-06-12T09:03:00'),
        clockOutAt: null,
        tags: <WorkRecordTag>[WorkRecordTag.overtime],
        memo: null,
        createdAt: DateTime.parse('2026-06-12T09:03:00'),
        updatedAt: DateTime.parse('2026-06-12T09:03:00'),
      );

      final WorkRecord changed = record.copyWith(
        id: record.id,
        workDate: record.workDate,
        clockInAt: record.clockInAt,
        clockOutAt: DateTime.parse('2026-06-12T18:42:00'),
        tags: record.tags,
        memo: '퇴근 지연',
        createdAt: record.createdAt,
        updatedAt: DateTime.parse('2026-06-12T18:42:00'),
      );

      expect(changed.clockOutAt, DateTime.parse('2026-06-12T18:42:00'));
      expect(changed.memo, '퇴근 지연');
      expect(record.clockOutAt, isNull);
    });

    test('throws on missing required map field', () {
      final Map<String, Object?> map = <String, Object?>{
        'work_date': '2026-06-12',
        'clock_in_at': null,
        'clock_out_at': null,
        'tags': <String>[],
        'memo': null,
        'created_at': '2026-06-12T09:03:00.000',
        'updated_at': '2026-06-12T09:03:00.000',
      };

      expect(
        () => WorkRecord.fromMap(map),
        throwsA(isA<WorkRecordParseException>()),
      );
    });

    test('throws on wrong map field type', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'work-1',
        'work_date': '2026-06-12',
        'clock_in_at': null,
        'clock_out_at': null,
        'tags': 'overtime',
        'memo': null,
        'created_at': '2026-06-12T09:03:00.000',
        'updated_at': '2026-06-12T09:03:00.000',
      };

      expect(
        () => WorkRecord.fromMap(map),
        throwsA(isA<WorkRecordParseException>()),
      );
    });

    test('throws on invalid date-only string', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'work-1',
        'work_date': '2026-02-30',
        'clock_in_at': null,
        'clock_out_at': null,
        'tags': <String>[],
        'memo': null,
        'created_at': '2026-06-12T09:03:00.000',
        'updated_at': '2026-06-12T09:03:00.000',
      };

      expect(
        () => WorkRecord.fromMap(map),
        throwsA(isA<WorkRecordParseException>()),
      );
    });

    test('throws when clock-out is before clock-in', () {
      expect(
        () => WorkRecord(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime.parse('2026-06-12T18:42:00'),
          clockOutAt: DateTime.parse('2026-06-12T09:03:00'),
          tags: <WorkRecordTag>[],
          memo: null,
          createdAt: DateTime.parse('2026-06-12T09:03:00'),
          updatedAt: DateTime.parse('2026-06-12T09:03:00'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when tags contain duplicates', () {
      expect(
        () => WorkRecord(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: null,
          clockOutAt: null,
          tags: <WorkRecordTag>[WorkRecordTag.overtime, WorkRecordTag.overtime],
          memo: null,
          createdAt: DateTime.parse('2026-06-12T09:03:00'),
          updatedAt: DateTime.parse('2026-06-12T09:03:00'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
