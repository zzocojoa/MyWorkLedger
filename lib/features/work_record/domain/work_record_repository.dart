import '../../../core/models/work_record.dart';

abstract interface class WorkRecordRepository {
  Future<WorkRecord?> findToday();

  Future<WorkRecord?> findByDate({required DateTime workDate});

  Future<List<WorkRecord>> findByMonth({required int year, required int month});

  Future<WorkRecord> clockIn();

  Future<WorkRecord> clockOut();

  Future<WorkRecord> clockInAt({required DateTime clockInAt});

  Future<WorkRecord> clockOutAt({required DateTime clockOutAt});

  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  });

  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  });

  Future<void> deleteToday();

  Future<void> deleteByDate({required DateTime workDate});
}

final class WorkRecordRepositoryException implements Exception {
  const WorkRecordRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return 'WorkRecordRepositoryException: $message';
  }
}
