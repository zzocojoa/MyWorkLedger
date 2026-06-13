import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/leave_usage.dart';

void main() {
  group('LeaveUsage', () {
    test('serializes and parses a usage', () {
      final LeaveUsage usage = LeaveUsage(
        id: 'usage-1',
        usedOn: DateTime(2026, 6, 10),
        usedLeaveMinutes: 240,
        memo: '오전 반차',
        createdAt: DateTime.parse('2026-06-10T09:00:00'),
        updatedAt: DateTime.parse('2026-06-10T09:00:00'),
      );

      final Map<String, Object?> map = usage.toMap();
      final LeaveUsage parsed = LeaveUsage.fromMap(map);

      expect(map['used_on'], '2026-06-10');
      expect(map['used_leave_minutes'], 240);
      expect(parsed, usage);
    });

    test('copyWith requires explicit values and returns a changed usage', () {
      final LeaveUsage usage = LeaveUsage(
        id: 'usage-1',
        usedOn: DateTime(2026, 6, 10),
        usedLeaveMinutes: 240,
        memo: null,
        createdAt: DateTime.parse('2026-06-10T09:00:00'),
        updatedAt: DateTime.parse('2026-06-10T09:00:00'),
      );

      final LeaveUsage changed = usage.copyWith(
        id: usage.id,
        usedOn: usage.usedOn,
        usedLeaveMinutes: 480,
        memo: '개인 일정',
        createdAt: usage.createdAt,
        updatedAt: DateTime.parse('2026-06-10T10:00:00'),
      );

      expect(changed.usedLeaveMinutes, 480);
      expect(changed.memo, '개인 일정');
      expect(usage.memo, isNull);
    });

    test('throws on missing required map field', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'usage-1',
        'used_leave_minutes': 240,
        'memo': null,
        'created_at': '2026-06-10T09:00:00.000',
        'updated_at': '2026-06-10T09:00:00.000',
      };

      expect(
        () => LeaveUsage.fromMap(map),
        throwsA(isA<LeaveUsageParseException>()),
      );
    });

    test('throws on wrong map field type', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'usage-1',
        'used_on': '2026-06-10',
        'used_leave_minutes': '240',
        'memo': null,
        'created_at': '2026-06-10T09:00:00.000',
        'updated_at': '2026-06-10T09:00:00.000',
      };

      expect(
        () => LeaveUsage.fromMap(map),
        throwsA(isA<LeaveUsageParseException>()),
      );
    });

    test('throws on invalid date-only string', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'usage-1',
        'used_on': '2026-02-30',
        'used_leave_minutes': 240,
        'memo': null,
        'created_at': '2026-06-10T09:00:00.000',
        'updated_at': '2026-06-10T09:00:00.000',
      };

      expect(
        () => LeaveUsage.fromMap(map),
        throwsA(isA<LeaveUsageParseException>()),
      );
    });

    test('throws when used leave minutes are below 30', () {
      expect(
        () => LeaveUsage(
          id: 'usage-1',
          usedOn: DateTime(2026, 6, 10),
          usedLeaveMinutes: 0,
          memo: null,
          createdAt: DateTime.parse('2026-06-10T09:00:00'),
          updatedAt: DateTime.parse('2026-06-10T09:00:00'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
