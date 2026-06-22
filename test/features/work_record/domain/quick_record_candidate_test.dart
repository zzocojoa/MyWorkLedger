import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/work_record/domain/quick_record_candidate.dart';
import 'package:workledger/features/work_record/domain/quick_record_settings.dart';

void main() {
  group('buildQuickRecordCandidates', () {
    test('returns no candidates for current-time-only mode', () {
      final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
        mode: QuickRecordMode.currentTimeOnly,
        actionType: QuickRecordActionType.clockIn,
        currentTime: DateTime(2026, 6, 12, 9, 37),
        workRule: _workRule(),
        compensationReferenceSetting: null,
      );

      expect(candidates, isEmpty);
    });

    test('builds current regular and manual clock-in candidates', () {
      final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
        mode: QuickRecordMode.chooseBeforeSave,
        actionType: QuickRecordActionType.clockIn,
        currentTime: DateTime(2026, 6, 12, 9, 37),
        workRule: _workRule(),
        compensationReferenceSetting: null,
      );

      expect(
        candidates.map((QuickRecordCandidate value) => value.label),
        <String>['현재 시각 09:37', '정시 출근 09:00', '직접 입력'],
      );
      expect(candidates[0].recordedAt, DateTime(2026, 6, 12, 9, 37));
      expect(candidates[1].recordedAt, DateTime(2026, 6, 12, 9));
      expect(candidates[2].recordedAt, isNull);
    });

    test('builds regular clock-out candidate from regular end time', () {
      final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
        mode: QuickRecordMode.chooseBeforeSave,
        actionType: QuickRecordActionType.clockOut,
        currentTime: DateTime(2026, 6, 12, 18, 45),
        workRule: _workRule(),
        compensationReferenceSetting: null,
      );

      expect(candidates[1].label, '정시 퇴근 18:00');
      expect(candidates[1].recordedAt, DateTime(2026, 6, 12, 18));
    });

    test('builds clock-out candidate from fixed included reference time', () {
      final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
        mode: QuickRecordMode.chooseBeforeSave,
        actionType: QuickRecordActionType.clockOut,
        currentTime: DateTime(2026, 6, 12, 18, 45),
        workRule: _workRule(),
        compensationReferenceSetting: _fixedIncludedSetting(),
      );

      expect(candidates[1].label, '정시 퇴근 20:00');
      expect(candidates[1].recordedAt, DateTime(2026, 6, 12, 20));
    });

    test('keeps regular clock-in candidate with fixed included setting', () {
      final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
        mode: QuickRecordMode.chooseBeforeSave,
        actionType: QuickRecordActionType.clockIn,
        currentTime: DateTime(2026, 6, 12, 9, 37),
        workRule: _workRule(),
        compensationReferenceSetting: _fixedIncludedSetting(),
      );

      expect(candidates[1].label, '정시 출근 09:00');
      expect(candidates[1].recordedAt, DateTime(2026, 6, 12, 9));
    });

    test('keeps regular clock-out candidate without fixed included mode', () {
      final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
        mode: QuickRecordMode.chooseBeforeSave,
        actionType: QuickRecordActionType.clockOut,
        currentTime: DateTime(2026, 6, 12, 18, 45),
        workRule: _workRule(),
        compensationReferenceSetting: _noneSetting(),
      );

      expect(candidates[1].label, '정시 퇴근 18:00');
      expect(candidates[1].recordedAt, DateTime(2026, 6, 12, 18));
    });

    test('uses selector-open date for regular candidates near midnight', () {
      final List<QuickRecordCandidate> candidates = buildQuickRecordCandidates(
        mode: QuickRecordMode.chooseBeforeSave,
        actionType: QuickRecordActionType.clockIn,
        currentTime: DateTime(2026, 6, 12, 23, 59, 58),
        workRule: _workRule(),
        compensationReferenceSetting: null,
      );

      expect(candidates[1].label, '정시 출근 09:00');
      expect(candidates[1].recordedAt, DateTime(2026, 6, 12, 9));
    });
  });

  group('parseQuickRecordManualTime', () {
    test('parses normalized HH:mm input on the work date', () {
      final DateTime value = parseQuickRecordManualTime(
        value: '930',
        workDate: DateTime(2026, 6, 12, 18),
      );

      expect(value, DateTime(2026, 6, 12, 9, 30));
    });

    test('uses selector-open work date for manual input near midnight', () {
      final DateTime value = parseQuickRecordManualTime(
        value: '08:15',
        workDate: DateTime(2026, 6, 12, 23, 59, 58),
      );

      expect(value, DateTime(2026, 6, 12, 8, 15));
    });

    test('throws for out-of-range input', () {
      expect(
        () => parseQuickRecordManualTime(
          value: '24:00',
          workDate: DateTime(2026, 6, 12),
        ),
        throwsA(isA<QuickRecordManualInputException>()),
      );
    });
  });
}

CompensationReferenceSetting _fixedIncludedSetting() {
  return CompensationReferenceSetting(
    id: 'compensation-reference-1',
    mode: CompensationReferenceMode.fixedIncluded,
    fixedIncludedAfterRegularEndMinutes: 120,
    effectiveFromMonth: DateTime(2000),
    memo: null,
    createdAt: DateTime(2026, 6, 12, 8),
    updatedAt: DateTime(2026, 6, 12, 8),
  );
}

CompensationReferenceSetting _noneSetting() {
  return CompensationReferenceSetting(
    id: 'compensation-reference-1',
    mode: CompensationReferenceMode.none,
    fixedIncludedAfterRegularEndMinutes: 120,
    effectiveFromMonth: DateTime(2000),
    memo: null,
    createdAt: DateTime(2026, 6, 12, 8),
    updatedAt: DateTime(2026, 6, 12, 8),
  );
}

WorkRule _workRule() {
  return WorkRule(
    id: 'work-rule-1',
    regularStartTimeMinutes: 540,
    regularEndTimeMinutes: 1080,
    overtimeStartTimeMinutes: 1080,
    nightWorkStartTimeMinutes: 1320,
    breakMinutes: 60,
    workWeekdays: <int>[1, 2, 3, 4, 5],
    createdAt: DateTime(2026, 6, 12, 8),
    updatedAt: DateTime(2026, 6, 12, 8),
  );
}
