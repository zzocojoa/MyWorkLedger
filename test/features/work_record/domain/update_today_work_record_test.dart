import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/work_record/domain/update_today_work_record.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';

void main() {
  group('updateTodayWorkRecord', () {
    test('updates today record through repository', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository();

      final WorkRecord record = await updateTodayWorkRecord(
        repository: repository,
        input: UpdateTodayWorkRecordInput(
          clockInAt: DateTime.parse('2026-06-12T09:03:00'),
          clockOutAt: DateTime.parse('2026-06-12T18:42:00'),
          tags: <WorkRecordTag>[WorkRecordTag.overtime],
          memo: '배포 대응',
        ),
      );

      expect(record.clockInAt, DateTime.parse('2026-06-12T09:03:00'));
      expect(record.clockOutAt, DateTime.parse('2026-06-12T18:42:00'));
      expect(record.tags, <WorkRecordTag>[WorkRecordTag.overtime]);
      expect(record.memo, '배포 대응');
      expect(repository.updateTodayCallCount, 1);
    });

    test('throws before repository call when clock-out is before clock-in', () {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository();

      expect(
        () => updateTodayWorkRecord(
          repository: repository,
          input: UpdateTodayWorkRecordInput(
            clockInAt: DateTime.parse('2026-06-12T18:42:00'),
            clockOutAt: DateTime.parse('2026-06-12T09:03:00'),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
        ),
        throwsA(isA<UpdateTodayWorkRecordException>()),
      );
      expect(repository.updateTodayCallCount, 0);
    });
  });
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  int updateTodayCallCount = 0;

  @override
  Future<WorkRecord?> findToday() async {
    return null;
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    return null;
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    throw const WorkRecordRepositoryException('unexpected findByMonth call');
  }

  @override
  Future<WorkRecord> clockIn() async {
    throw const WorkRecordRepositoryException('unexpected clockIn call');
  }

  @override
  Future<WorkRecord> clockOut() async {
    throw const WorkRecordRepositoryException('unexpected clockOut call');
  }

  @override
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    updateTodayCallCount += 1;
    return WorkRecord(
      id: 'work-1',
      workDate: DateTime(2026, 6, 12),
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: tags,
      memo: memo,
      createdAt: DateTime.parse('2026-06-12T09:00:00'),
      updatedAt: DateTime.parse('2026-06-12T20:00:00'),
    );
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException('unexpected upsertByDate call');
  }

  @override
  Future<void> deleteToday() async {
    throw const WorkRecordRepositoryException('unexpected deleteToday call');
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    throw const WorkRecordRepositoryException('unexpected deleteByDate call');
  }
}
