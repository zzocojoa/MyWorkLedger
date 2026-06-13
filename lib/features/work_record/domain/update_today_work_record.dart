import '../../../core/models/work_record.dart';
import 'work_record_repository.dart';

final class UpdateTodayWorkRecordException implements Exception {
  const UpdateTodayWorkRecordException(this.message);

  final String message;

  @override
  String toString() {
    return 'UpdateTodayWorkRecordException: $message';
  }
}

final class UpdateTodayWorkRecordInput {
  UpdateTodayWorkRecordInput({
    required this.clockInAt,
    required this.clockOutAt,
    required List<WorkRecordTag> tags,
    required this.memo,
  }) : tags = List<WorkRecordTag>.unmodifiable(tags);

  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final List<WorkRecordTag> tags;
  final String? memo;
}

Future<WorkRecord> updateTodayWorkRecord({
  required WorkRecordRepository repository,
  required UpdateTodayWorkRecordInput input,
}) {
  validateTodayWorkRecordUpdate(input: input);
  return repository.updateToday(
    clockInAt: input.clockInAt,
    clockOutAt: input.clockOutAt,
    tags: input.tags,
    memo: input.memo,
  );
}

void validateTodayWorkRecordUpdate({
  required UpdateTodayWorkRecordInput input,
}) {
  final DateTime? clockInAt = input.clockInAt;
  final DateTime? clockOutAt = input.clockOutAt;
  if (clockInAt != null &&
      clockOutAt != null &&
      clockOutAt.isBefore(clockInAt)) {
    throw UpdateTodayWorkRecordException(
      'field=clockOutAt value=${clockOutAt.toIso8601String()} clockInAt=${clockInAt.toIso8601String()} rule=clock-out must be greater than or equal to clock-in',
    );
  }
  if (input.tags.toSet().length != input.tags.length) {
    throw UpdateTodayWorkRecordException(
      'field=tags value=${input.tags.map((WorkRecordTag tag) => tag.name).join(",")} rule=unique tags',
    );
  }
  final String? memo = input.memo;
  if (memo != null && memo.length > 500) {
    throw UpdateTodayWorkRecordException(
      'field=memo length=${memo.length} rule=500 characters or fewer',
    );
  }
}
