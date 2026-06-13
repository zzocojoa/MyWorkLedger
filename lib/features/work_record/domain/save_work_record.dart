import '../../../core/models/work_record.dart';
import 'work_record_repository.dart';

final class SaveWorkRecordException implements Exception {
  const SaveWorkRecordException(this.message);

  final String message;

  @override
  String toString() {
    return 'SaveWorkRecordException: $message';
  }
}

final class SaveWorkRecordInput {
  SaveWorkRecordInput({
    required this.workDate,
    required this.clockInAt,
    required this.clockOutAt,
    required List<WorkRecordTag> tags,
    required this.memo,
  }) : tags = List<WorkRecordTag>.unmodifiable(tags);

  final DateTime workDate;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final List<WorkRecordTag> tags;
  final String? memo;
}

Future<WorkRecord> saveWorkRecord({
  required WorkRecordRepository repository,
  required SaveWorkRecordInput input,
}) {
  validateWorkRecordSave(input: input);
  return repository.upsertByDate(
    workDate: input.workDate,
    clockInAt: input.clockInAt,
    clockOutAt: input.clockOutAt,
    tags: input.tags,
    memo: input.memo,
  );
}

void validateWorkRecordSave({required SaveWorkRecordInput input}) {
  final DateTime workDate = _dateOnly(input.workDate);
  final DateTime? clockInAt = input.clockInAt;
  final DateTime? clockOutAt = input.clockOutAt;
  if (!_isDateOnly(input.workDate)) {
    throw SaveWorkRecordException(
      'field=workDate value=${input.workDate.toIso8601String()} rule=date only',
    );
  }
  if (clockInAt != null && !_isSameDate(left: workDate, right: clockInAt)) {
    throw SaveWorkRecordException(
      'field=clockInAt value=${clockInAt.toIso8601String()} workDate=${_formatDateOnly(workDate)} rule=same date as workDate',
    );
  }
  if (clockOutAt != null && !_isSameDate(left: workDate, right: clockOutAt)) {
    throw SaveWorkRecordException(
      'field=clockOutAt value=${clockOutAt.toIso8601String()} workDate=${_formatDateOnly(workDate)} rule=same date as workDate',
    );
  }
  if (clockInAt != null &&
      clockOutAt != null &&
      clockOutAt.isBefore(clockInAt)) {
    throw SaveWorkRecordException(
      'field=clockOutAt value=${clockOutAt.toIso8601String()} clockInAt=${clockInAt.toIso8601String()} rule=clock-out must be greater than or equal to clock-in',
    );
  }
  if (input.tags.toSet().length != input.tags.length) {
    throw SaveWorkRecordException(
      'field=tags value=${input.tags.map((WorkRecordTag tag) => tag.name).join(",")} rule=unique tags',
    );
  }
  final String? memo = input.memo;
  if (memo != null && memo.length > 500) {
    throw SaveWorkRecordException(
      'field=memo length=${memo.length} rule=500 characters or fewer',
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isDateOnly(DateTime value) {
  return value == _dateOnly(value);
}

bool _isSameDate({required DateTime left, required DateTime right}) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _formatDateOnly(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
