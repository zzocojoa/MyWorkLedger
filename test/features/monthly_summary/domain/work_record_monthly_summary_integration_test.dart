import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/monthly_summary/domain/calculate_monthly_summary.dart';
import 'package:workledger/features/monthly_summary/domain/monthly_summary.dart';
import 'package:workledger/features/work_record/data/local_storage_work_record_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('work record monthly summary integration', () {
    test('loads monthly records and calculates summary', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository =
          LocalStorageWorkRecordRepository(
            storage: storage,
            clock: () => DateTime.parse('2026-06-12T09:03:00'),
            idGenerator: () => 'unused-id',
          );
      await _writeRecord(
        storage: storage,
        key: '2026-06-01',
        record: _createRecord(
          id: 'june-1',
          workDate: DateTime(2026, 6, 1),
          clockInAt: DateTime.parse('2026-06-01T09:00:00'),
          clockOutAt: DateTime.parse('2026-06-01T20:30:00'),
          tags: <WorkRecordTag>[WorkRecordTag.overtime],
        ),
      );
      await _writeRecord(
        storage: storage,
        key: '2026-06-02',
        record: _createRecord(
          id: 'june-incomplete',
          workDate: DateTime(2026, 6, 2),
          clockInAt: DateTime.parse('2026-06-02T09:10:00'),
          clockOutAt: null,
          tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
        ),
      );
      await _writeRecord(
        storage: storage,
        key: '2026-05-31',
        record: _createRecord(
          id: 'may-1',
          workDate: DateTime(2026, 5, 31),
          clockInAt: DateTime.parse('2026-05-31T09:00:00'),
          clockOutAt: DateTime.parse('2026-05-31T18:00:00'),
          tags: <WorkRecordTag>[WorkRecordTag.holidayWork],
        ),
      );

      final List<WorkRecord> records = await repository.findByMonth(
        year: 2026,
        month: 6,
      );
      final MonthlySummary summary = calculateMonthlySummary(
        targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        records: records,
      );

      expect(records.map((WorkRecord record) => record.id), <String>[
        'june-1',
        'june-incomplete',
      ]);
      expect(summary.completedWorkDayCount, 1);
      expect(summary.incompleteEntries.length, 1);
      expect(
        summary.totalWorkedDuration,
        const Duration(hours: 11, minutes: 30),
      );
      expect(
        summary.overtimeReferenceDuration,
        const Duration(hours: 11, minutes: 30),
      );
    });
  });
}

Future<void> _writeRecord({
  required InMemoryKeyValueStorage storage,
  required String key,
  required WorkRecord record,
}) async {
  await storage.write(
    table: LocalStorageWorkRecordRepository.workRecordsTable,
    key: key,
    value: record.toMap(),
  );
}

WorkRecord _createRecord({
  required String id,
  required DateTime workDate,
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
  required List<WorkRecordTag> tags,
}) {
  return WorkRecord(
    id: id,
    workDate: workDate,
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: tags,
    memo: null,
    createdAt: DateTime(workDate.year, workDate.month, workDate.day, 8),
    updatedAt: DateTime(workDate.year, workDate.month, workDate.day, 21),
  );
}
