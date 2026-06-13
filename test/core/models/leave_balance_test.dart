import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/leave_balance.dart';

void main() {
  group('LeaveBalance', () {
    test('serializes and parses a balance', () {
      final LeaveBalance balance = LeaveBalance(
        id: 'balance-2026',
        year: 2026,
        totalLeaveMinutes: 7200,
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
        updatedAt: DateTime.parse('2026-06-12T09:00:00'),
      );

      final Map<String, Object?> map = balance.toMap();
      final LeaveBalance parsed = LeaveBalance.fromMap(map);

      expect(map['total_leave_minutes'], 7200);
      expect(parsed, balance);
    });

    test('copyWith requires explicit values and returns a changed balance', () {
      final LeaveBalance balance = LeaveBalance(
        id: 'balance-2026',
        year: 2026,
        totalLeaveMinutes: 7200,
        createdAt: DateTime.parse('2026-01-01T00:00:00'),
        updatedAt: DateTime.parse('2026-06-12T09:00:00'),
      );

      final LeaveBalance changed = balance.copyWith(
        id: balance.id,
        year: balance.year,
        totalLeaveMinutes: 7680,
        createdAt: balance.createdAt,
        updatedAt: DateTime.parse('2026-06-13T09:00:00'),
      );

      expect(changed.totalLeaveMinutes, 7680);
      expect(balance.totalLeaveMinutes, 7200);
    });

    test('throws on missing required map field', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'balance-2026',
        'total_leave_minutes': 7200,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-06-12T09:00:00.000',
      };

      expect(
        () => LeaveBalance.fromMap(map),
        throwsA(isA<LeaveBalanceParseException>()),
      );
    });

    test('throws on wrong map field type', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'balance-2026',
        'year': '2026',
        'total_leave_minutes': 7200,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-06-12T09:00:00.000',
      };

      expect(
        () => LeaveBalance.fromMap(map),
        throwsA(isA<LeaveBalanceParseException>()),
      );
    });

    test('throws on invalid ISO date', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'balance-2026',
        'year': 2026,
        'total_leave_minutes': 7200,
        'created_at': 'not-a-date',
        'updated_at': '2026-06-12T09:00:00.000',
      };

      expect(
        () => LeaveBalance.fromMap(map),
        throwsA(isA<LeaveBalanceParseException>()),
      );
    });

    test('throws when total leave minutes are not 30-minute aligned', () {
      expect(
        () => LeaveBalance(
          id: 'balance-2026',
          year: 2026,
          totalLeaveMinutes: 7210,
          createdAt: DateTime.parse('2026-01-01T00:00:00'),
          updatedAt: DateTime.parse('2026-06-12T09:00:00'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
