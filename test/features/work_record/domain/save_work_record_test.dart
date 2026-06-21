import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/work_record/domain/save_work_record.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';

void main() {
  group('saveWorkRecord', () {
    test('upserts selected work date through repository', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository();

      final WorkRecord record = await saveWorkRecord(
        repository: repository,
        input: SaveWorkRecordInput(
          workDate: DateTime(2026, 6, 1),
          clockInAt: DateTime.parse('2026-06-01T09:03:00'),
          clockOutAt: DateTime.parse('2026-06-01T18:42:00'),
          tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
          memo: '누락 기록',
        ),
      );

      expect(record.workDate, DateTime(2026, 6, 1));
      expect(record.clockInAt, DateTime.parse('2026-06-01T09:03:00'));
      expect(record.clockOutAt, DateTime.parse('2026-06-01T18:42:00'));
      expect(record.tags, <WorkRecordTag>[WorkRecordTag.delayedCheckout]);
      expect(record.memo, '누락 기록');
      expect(repository.upsertByDateCallCount, 1);
    });

    test('throws before repository call when clock-out is before clock-in', () {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository();

      expect(
        () => saveWorkRecord(
          repository: repository,
          input: SaveWorkRecordInput(
            workDate: DateTime(2026, 6, 1),
            clockInAt: DateTime.parse('2026-06-01T18:42:00'),
            clockOutAt: DateTime.parse('2026-06-01T09:03:00'),
            tags: <WorkRecordTag>[],
            memo: null,
          ),
        ),
        throwsA(isA<SaveWorkRecordException>()),
      );
      expect(repository.upsertByDateCallCount, 0);
    });

    test('throws before repository call when time is not on work date', () {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository();

      expect(
        () => saveWorkRecord(
          repository: repository,
          input: SaveWorkRecordInput(
            workDate: DateTime(2026, 6, 1),
            clockInAt: DateTime.parse('2026-06-02T09:03:00'),
            clockOutAt: null,
            tags: <WorkRecordTag>[],
            memo: null,
          ),
        ),
        throwsA(isA<SaveWorkRecordException>()),
      );
      expect(repository.upsertByDateCallCount, 0);
    });
  });
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  int upsertByDateCallCount = 0;

  @override
  Future<WorkRecord?> findToday() async {
    throw const WorkRecordRepositoryException('unexpected findToday call');
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    throw const WorkRecordRepositoryException('unexpected findByDate call');
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
  Future<WorkRecord> clockInAt({required DateTime clockInAt}) async {
    throw const WorkRecordRepositoryException('unexpected clockInAt call');
  }

  @override
  Future<WorkRecord> clockOutAt({required DateTime clockOutAt}) async {
    throw const WorkRecordRepositoryException('unexpected clockOutAt call');
  }

  @override
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException('unexpected updateToday call');
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    upsertByDateCallCount += 1;
    return WorkRecord(
      id: 'work-1',
      workDate: workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: tags,
      memo: memo,
      createdAt: DateTime.parse('2026-06-01T09:00:00'),
      updatedAt: DateTime.parse('2026-06-01T20:00:00'),
    );
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
