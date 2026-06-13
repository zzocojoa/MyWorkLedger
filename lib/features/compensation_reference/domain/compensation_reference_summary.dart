import '../../../core/models/compensation_reference_setting.dart';
import '../../work_time/domain/work_time_candidate.dart';

enum CompensationReferenceSummaryStatus { hidden, notConfigured, available }

final class CompensationReferenceSummary {
  CompensationReferenceSummary({
    required this.status,
    required List<CompensationReferenceComparisonRow> rows,
    required this.reason,
  }) : rows = List<CompensationReferenceComparisonRow>.unmodifiable(rows) {
    _validateSummary(this);
  }

  final CompensationReferenceSummaryStatus status;
  final List<CompensationReferenceComparisonRow> rows;
  final String? reason;

  bool get isVisible {
    return status != CompensationReferenceSummaryStatus.hidden;
  }
}

final class CompensationReferenceComparisonRow {
  const CompensationReferenceComparisonRow({
    required this.label,
    required this.actualDuration,
    required this.fixedIncludedDuration,
    required this.excessReferenceDuration,
  });

  final String label;
  final Duration actualDuration;
  final Duration fixedIncludedDuration;
  final Duration excessReferenceDuration;
}

CompensationReferenceSummary calculateCompensationReferenceSummary({
  required CompensationReferenceSetting? setting,
  required WorkTimeCandidateSummary workTimeCandidateSummary,
}) {
  if (setting == null || setting.mode == CompensationReferenceMode.none) {
    return CompensationReferenceSummary(
      status: CompensationReferenceSummaryStatus.hidden,
      rows: <CompensationReferenceComparisonRow>[],
      reason: 'settingMissing',
    );
  }
  if (setting.mode == CompensationReferenceMode.unknown) {
    return CompensationReferenceSummary(
      status: CompensationReferenceSummaryStatus.notConfigured,
      rows: <CompensationReferenceComparisonRow>[],
      reason: 'settingUnknown',
    );
  }
  if (!workTimeCandidateSummary.isAvailable) {
    return CompensationReferenceSummary(
      status: CompensationReferenceSummaryStatus.hidden,
      rows: <CompensationReferenceComparisonRow>[],
      reason: 'workRuleMissing',
    );
  }
  return CompensationReferenceSummary(
    status: CompensationReferenceSummaryStatus.available,
    rows: <CompensationReferenceComparisonRow>[
      _createComparisonRow(
        label: '연장 근무',
        actualDuration: workTimeCandidateSummary.overtimeDuration,
        fixedIncludedMinutes: setting.fixedIncludedOvertimeMinutes,
      ),
      _createComparisonRow(
        label: '야간 근무',
        actualDuration: workTimeCandidateSummary.nightWorkDuration,
        fixedIncludedMinutes: setting.fixedIncludedNightMinutes,
      ),
      _createComparisonRow(
        label: '휴무일 근무',
        actualDuration: workTimeCandidateSummary.nonWorkdayDuration,
        fixedIncludedMinutes: setting.fixedIncludedHolidayMinutes,
      ),
    ],
    reason: null,
  );
}

CompensationReferenceComparisonRow _createComparisonRow({
  required String label,
  required Duration actualDuration,
  required int fixedIncludedMinutes,
}) {
  final Duration fixedIncludedDuration = Duration(
    minutes: fixedIncludedMinutes,
  );
  final Duration excessReferenceDuration =
      actualDuration > fixedIncludedDuration
      ? actualDuration - fixedIncludedDuration
      : Duration.zero;
  return CompensationReferenceComparisonRow(
    label: label,
    actualDuration: actualDuration,
    fixedIncludedDuration: fixedIncludedDuration,
    excessReferenceDuration: excessReferenceDuration,
  );
}

void _validateSummary(CompensationReferenceSummary summary) {
  if (summary.status == CompensationReferenceSummaryStatus.available &&
      summary.rows.isEmpty) {
    throw ArgumentError.value(summary.rows, 'rows', 'must not be empty');
  }
  for (final CompensationReferenceComparisonRow row in summary.rows) {
    if (row.label.isEmpty) {
      throw ArgumentError.value(row.label, 'label', 'must not be empty');
    }
    if (row.actualDuration.isNegative) {
      throw ArgumentError.value(
        row.actualDuration,
        'actualDuration',
        'must be non-negative',
      );
    }
    if (row.fixedIncludedDuration.isNegative) {
      throw ArgumentError.value(
        row.fixedIncludedDuration,
        'fixedIncludedDuration',
        'must be non-negative',
      );
    }
    if (row.excessReferenceDuration.isNegative) {
      throw ArgumentError.value(
        row.excessReferenceDuration,
        'excessReferenceDuration',
        'must be non-negative',
      );
    }
  }
}
