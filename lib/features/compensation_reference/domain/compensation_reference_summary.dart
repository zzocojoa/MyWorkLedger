import '../../../core/models/compensation_reference_setting.dart';
import '../../../core/models/work_record.dart';
import '../../../core/models/work_rule.dart';

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
    required this.excessStartTimeMinutes,
    required this.actualDuration,
    required this.fixedIncludedDuration,
    required this.excessReferenceDuration,
  });

  final String label;
  final int excessStartTimeMinutes;
  final Duration actualDuration;
  final Duration fixedIncludedDuration;
  final Duration excessReferenceDuration;
}

CompensationReferenceSummary calculateCompensationReferenceSummary({
  required CompensationReferenceSetting? setting,
  required List<WorkRecord> records,
  required WorkRule? workRule,
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
  if (workRule == null) {
    return CompensationReferenceSummary(
      status: CompensationReferenceSummaryStatus.hidden,
      rows: <CompensationReferenceComparisonRow>[],
      reason: 'workRuleMissing',
    );
  }
  final CompensationReferenceComparisonRow row =
      _createAfterRegularEndComparisonRow(
        records: records,
        workRule: workRule,
        fixedIncludedMinutes: setting.fixedIncludedAfterRegularEndMinutes,
      );
  return CompensationReferenceSummary(
    status: CompensationReferenceSummaryStatus.available,
    rows: <CompensationReferenceComparisonRow>[row],
    reason: null,
  );
}

CompensationReferenceComparisonRow _createAfterRegularEndComparisonRow({
  required List<WorkRecord> records,
  required WorkRule workRule,
  required int fixedIncludedMinutes,
}) {
  final Duration fixedIncludedLimit = Duration(minutes: fixedIncludedMinutes);
  Duration actualDuration = Duration.zero;
  Duration fixedIncludedDuration = Duration.zero;
  Duration excessReferenceDuration = Duration.zero;
  for (final WorkRecord record in records) {
    final Duration recordDuration = _calculateAfterRegularEndDuration(
      record: record,
      workRule: workRule,
    );
    final Duration recordIncludedDuration = recordDuration > fixedIncludedLimit
        ? fixedIncludedLimit
        : recordDuration;
    actualDuration += recordDuration;
    fixedIncludedDuration += recordIncludedDuration;
    excessReferenceDuration += recordDuration - recordIncludedDuration;
  }
  return CompensationReferenceComparisonRow(
    label: '정시 이후 근무',
    excessStartTimeMinutes:
        workRule.regularEndTimeMinutes + fixedIncludedMinutes,
    actualDuration: actualDuration,
    fixedIncludedDuration: fixedIncludedDuration,
    excessReferenceDuration: excessReferenceDuration,
  );
}

Duration _calculateAfterRegularEndDuration({
  required WorkRecord record,
  required WorkRule workRule,
}) {
  final DateTime? clockInAt = record.clockInAt;
  final DateTime? clockOutAt = record.clockOutAt;
  if (clockInAt == null || clockOutAt == null) {
    return Duration.zero;
  }
  if (record.tags.contains(WorkRecordTag.delayedCheckout)) {
    return Duration.zero;
  }
  if (!workRule.workWeekdays.contains(record.workDate.weekday)) {
    return Duration.zero;
  }
  final DateTime regularEndAt = DateTime(
    record.workDate.year,
    record.workDate.month,
    record.workDate.day,
    workRule.regularEndTimeMinutes ~/ 60,
    workRule.regularEndTimeMinutes.remainder(60),
  );
  if (!clockOutAt.isAfter(regularEndAt)) {
    return Duration.zero;
  }
  return clockOutAt.difference(regularEndAt);
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
    if (row.excessStartTimeMinutes < 0) {
      throw ArgumentError.value(
        row.excessStartTimeMinutes,
        'excessStartTimeMinutes',
        'must be non-negative',
      );
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
