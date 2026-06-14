import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_rule.dart';

void main() {
  group('WorkRule', () {
    test('serializes and parses a work rule', () {
      final WorkRule rule = WorkRule(
        id: 'active-rule',
        regularStartTimeMinutes: 540,
        regularEndTimeMinutes: 1080,
        overtimeStartTimeMinutes: 1080,
        nightWorkStartTimeMinutes: workRuleDefaultNightWorkStartTimeMinutes,
        breakMinutes: 60,
        workWeekdays: <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ],
        createdAt: DateTime.parse('2026-06-01T09:00:00'),
        updatedAt: DateTime.parse('2026-06-12T09:00:00'),
      );

      final Map<String, Object?> map = rule.toMap();
      final WorkRule parsed = WorkRule.fromMap(map);

      expect(map['regular_start_time_minutes'], 540);
      expect(map['regular_end_time_minutes'], 1080);
      expect(map['overtime_start_time_minutes'], 1080);
      expect(map['night_work_start_time_minutes'], 1320);
      expect(map['break_minutes'], 60);
      expect(parsed, rule);
    });

    test('parses legacy map with default tag start times', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'active-rule',
        'regular_start_time_minutes': 540,
        'regular_end_time_minutes': 1080,
        'break_minutes': 60,
        'work_weekdays': <Object?>[1, 2, 3, 4, 5],
        'created_at': '2026-06-01T09:00:00',
        'updated_at': '2026-06-12T09:00:00',
      };

      final WorkRule parsed = WorkRule.fromMap(map);

      expect(parsed.overtimeStartTimeMinutes, parsed.regularEndTimeMinutes);
      expect(
        parsed.nightWorkStartTimeMinutes,
        workRuleDefaultNightWorkStartTimeMinutes,
      );
    });

    test('copyWith requires explicit values and returns a changed rule', () {
      final WorkRule rule = _createRule();

      final WorkRule changed = rule.copyWith(
        id: rule.id,
        regularStartTimeMinutes: 600,
        regularEndTimeMinutes: rule.regularEndTimeMinutes,
        overtimeStartTimeMinutes: rule.overtimeStartTimeMinutes,
        nightWorkStartTimeMinutes: rule.nightWorkStartTimeMinutes,
        breakMinutes: rule.breakMinutes,
        workWeekdays: rule.workWeekdays,
        createdAt: rule.createdAt,
        updatedAt: DateTime.parse('2026-06-13T09:00:00'),
      );

      expect(changed.regularStartTimeMinutes, 600);
      expect(rule.regularStartTimeMinutes, 540);
    });

    test('throws on missing required map field', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'active-rule',
        'regular_start_time_minutes': 540,
        'regular_end_time_minutes': 1080,
        'break_minutes': 60,
        'created_at': '2026-06-01T09:00:00',
        'updated_at': '2026-06-12T09:00:00',
      };

      expect(
        () => WorkRule.fromMap(map),
        throwsA(isA<WorkRuleParseException>()),
      );
    });

    test('throws on wrong map field type', () {
      final Map<String, Object?> map = <String, Object?>{
        'id': 'active-rule',
        'regular_start_time_minutes': '09:00',
        'regular_end_time_minutes': 1080,
        'break_minutes': 60,
        'work_weekdays': <Object?>[1, 2, 3, 4, 5],
        'created_at': '2026-06-01T09:00:00',
        'updated_at': '2026-06-12T09:00:00',
      };

      expect(
        () => WorkRule.fromMap(map),
        throwsA(isA<WorkRuleParseException>()),
      );
    });

    test('throws when regular end is not after regular start', () {
      expect(
        () => WorkRule(
          id: 'active-rule',
          regularStartTimeMinutes: 1080,
          regularEndTimeMinutes: 540,
          overtimeStartTimeMinutes: 540,
          nightWorkStartTimeMinutes: workRuleDefaultNightWorkStartTimeMinutes,
          breakMinutes: 60,
          workWeekdays: <int>[DateTime.monday],
          createdAt: DateTime.parse('2026-06-01T09:00:00'),
          updatedAt: DateTime.parse('2026-06-12T09:00:00'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when overtime start is before regular end', () {
      expect(
        () => WorkRule(
          id: 'active-rule',
          regularStartTimeMinutes: 540,
          regularEndTimeMinutes: 1080,
          overtimeStartTimeMinutes: 1079,
          nightWorkStartTimeMinutes: workRuleDefaultNightWorkStartTimeMinutes,
          breakMinutes: 60,
          workWeekdays: <int>[DateTime.monday],
          createdAt: DateTime.parse('2026-06-01T09:00:00'),
          updatedAt: DateTime.parse('2026-06-12T09:00:00'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when weekdays contain duplicate values', () {
      expect(
        () => WorkRule(
          id: 'active-rule',
          regularStartTimeMinutes: 540,
          regularEndTimeMinutes: 1080,
          overtimeStartTimeMinutes: 1080,
          nightWorkStartTimeMinutes: workRuleDefaultNightWorkStartTimeMinutes,
          breakMinutes: 60,
          workWeekdays: <int>[DateTime.monday, DateTime.monday],
          createdAt: DateTime.parse('2026-06-01T09:00:00'),
          updatedAt: DateTime.parse('2026-06-12T09:00:00'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

WorkRule _createRule() {
  return WorkRule(
    id: 'active-rule',
    regularStartTimeMinutes: 540,
    regularEndTimeMinutes: 1080,
    overtimeStartTimeMinutes: 1080,
    nightWorkStartTimeMinutes: workRuleDefaultNightWorkStartTimeMinutes,
    breakMinutes: 60,
    workWeekdays: <int>[
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ],
    createdAt: DateTime.parse('2026-06-01T09:00:00'),
    updatedAt: DateTime.parse('2026-06-12T09:00:00'),
  );
}
