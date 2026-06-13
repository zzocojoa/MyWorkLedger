import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/compensation_reference_setting.dart';
import 'package:workledger/features/compensation_reference/domain/compensation_reference_summary.dart';
import 'package:workledger/features/work_time/domain/work_time_candidate.dart';

void main() {
  group('calculateCompensationReferenceSummary', () {
    test('hides summary when setting is none', () {
      final CompensationReferenceSummary summary =
          calculateCompensationReferenceSummary(
            setting: null,
            workTimeCandidateSummary: _candidateSummary(),
          );

      expect(summary.status, CompensationReferenceSummaryStatus.hidden);
      expect(summary.isVisible, isFalse);
    });

    test('shows not configured when mode is unknown', () {
      final CompensationReferenceSummary summary =
          calculateCompensationReferenceSummary(
            setting: _setting(mode: CompensationReferenceMode.unknown),
            workTimeCandidateSummary: _candidateSummary(),
          );

      expect(summary.status, CompensationReferenceSummaryStatus.notConfigured);
      expect(summary.isVisible, isTrue);
      expect(summary.rows, isEmpty);
    });

    test('calculates excess reference from actual and fixed durations', () {
      final CompensationReferenceSummary summary =
          calculateCompensationReferenceSummary(
            setting: _setting(mode: CompensationReferenceMode.fixedIncluded),
            workTimeCandidateSummary: _candidateSummary(),
          );

      expect(summary.status, CompensationReferenceSummaryStatus.available);
      expect(summary.rows[0].label, '연장 근무');
      expect(summary.rows[0].actualDuration, const Duration(hours: 3));
      expect(summary.rows[0].fixedIncludedDuration, const Duration(hours: 1));
      expect(summary.rows[0].excessReferenceDuration, const Duration(hours: 2));
      expect(summary.rows[1].excessReferenceDuration, Duration.zero);
    });
  });
}

CompensationReferenceSetting _setting({
  required CompensationReferenceMode mode,
}) {
  return CompensationReferenceSetting(
    id: 'setting-1',
    mode: mode,
    fixedIncludedOvertimeMinutes: 60,
    fixedIncludedNightMinutes: 30,
    fixedIncludedHolidayMinutes: 0,
    effectiveFromMonth: DateTime(2026, 6),
    memo: null,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1),
  );
}

WorkTimeCandidateSummary _candidateSummary() {
  return const WorkTimeCandidateSummary(
    status: WorkTimeCandidateStatus.available,
    nonWorkdayDuration: Duration.zero,
    earlyWorkDuration: Duration.zero,
    overtimeDuration: Duration(hours: 3),
    nightWorkDuration: Duration(minutes: 15),
    reason: null,
  );
}
