import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/storage/key_value_storage.dart';
import 'package:workledger/features/work_record/data/local_storage_work_record_repository.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('LocalStorageWorkRecordRepository', () {
    test('returns null when today has no record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      final WorkRecord? record = await repository.findToday();

      expect(record, isNull);
    });

    test('clockIn creates a new record for today', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      final WorkRecord record = await repository.clockIn();
      final WorkRecord? savedRecord = await repository.findToday();

      expect(record.id, 'work-1');
      expect(record.workDate, DateTime(2026, 6, 12));
      expect(record.clockInAt, DateTime.parse('2026-06-12T09:03:00'));
      expect(record.clockOutAt, isNull);
      expect(savedRecord, record);
    });

    test('clockIn uses one clock value across midnight boundary', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: _sequenceClock(
          values: <DateTime>[
            DateTime.parse('2026-06-12T23:59:59'),
            DateTime.parse('2026-06-13T00:00:00'),
          ],
        ),
        idGenerator: () => 'work-1',
      );

      final WorkRecord record = await repository.clockIn();

      expect(record.workDate, DateTime(2026, 6, 12));
      expect(record.clockInAt, DateTime.parse('2026-06-12T23:59:59'));
      expect(record.createdAt, DateTime.parse('2026-06-12T23:59:59'));
      expect(record.updatedAt, DateTime.parse('2026-06-12T23:59:59'));
    });

    test('clockInAt creates a today record with selected time', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:37:00'),
        idGenerator: () => 'work-1',
      );

      final WorkRecord record = await repository.clockInAt(
        clockInAt: DateTime.parse('2026-06-12T09:00:00'),
      );

      expect(record.workDate, DateTime(2026, 6, 12));
      expect(record.clockInAt, DateTime.parse('2026-06-12T09:00:00'));
      expect(record.createdAt, DateTime.parse('2026-06-12T09:37:00'));
      expect(record.updatedAt, DateTime.parse('2026-06-12T09:37:00'));
    });

    test('clockInAt saves selected date when saved after midnight', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-13T00:00:03'),
        idGenerator: () => 'work-1',
      );

      final WorkRecord record = await repository.clockInAt(
        clockInAt: DateTime.parse('2026-06-12T09:00:00'),
      );
      final WorkRecord? savedRecord = await repository.findByDate(
        workDate: DateTime(2026, 6, 12),
      );

      expect(record.workDate, DateTime(2026, 6, 12));
      expect(record.clockInAt, DateTime.parse('2026-06-12T09:00:00'));
      expect(record.createdAt, DateTime.parse('2026-06-13T00:00:03'));
      expect(record.updatedAt, DateTime.parse('2026-06-13T00:00:03'));
      expect(savedRecord, record);
    });

    test('clockIn updates an existing empty today record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final DateTime createdAt = DateTime.parse('2026-06-12T08:00:00');
      final WorkRecord emptyRecord = WorkRecord(
        id: 'work-1',
        workDate: DateTime(2026, 6, 12),
        clockInAt: null,
        clockOutAt: null,
        tags: <WorkRecordTag>[WorkRecordTag.overtime],
        memo: '출근 전 메모',
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      await storage.write(
        table: LocalStorageWorkRecordRepository.workRecordsTable,
        key: '2026-06-12',
        value: emptyRecord.toMap(),
      );
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'unused-id',
      );

      final WorkRecord record = await repository.clockIn();

      expect(record.id, 'work-1');
      expect(record.clockInAt, DateTime.parse('2026-06-12T09:03:00'));
      expect(record.tags, <WorkRecordTag>[WorkRecordTag.overtime]);
      expect(record.memo, '출근 전 메모');
      expect(record.createdAt, createdAt);
      expect(record.updatedAt, DateTime.parse('2026-06-12T09:03:00'));
    });

    test('clockIn throws when already clocked in', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      await repository.clockIn();

      expect(repository.clockIn, throwsA(isA<WorkRecordRepositoryException>()));
    });

    test('clockOut throws when today has no record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T18:42:00'),
        idGenerator: () => 'work-1',
      );

      expect(
        repository.clockOut,
        throwsA(isA<WorkRecordRepositoryException>()),
      );
    });

    test('clockOut throws when today has no clock-in time', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final WorkRecord record = WorkRecord(
        id: 'work-1',
        workDate: DateTime(2026, 6, 12),
        clockInAt: null,
        clockOutAt: null,
        tags: <WorkRecordTag>[],
        memo: null,
        createdAt: DateTime.parse('2026-06-12T08:00:00'),
        updatedAt: DateTime.parse('2026-06-12T08:00:00'),
      );
      await storage.write(
        table: LocalStorageWorkRecordRepository.workRecordsTable,
        key: '2026-06-12',
        value: record.toMap(),
      );
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T18:42:00'),
        idGenerator: () => 'unused-id',
      );

      expect(
        repository.clockOut,
        throwsA(isA<WorkRecordRepositoryException>()),
      );
    });

    test(
      'clockOut throws when clock-out time is before clock-in time',
      () async {
        final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
        final WorkRecord record = WorkRecord(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime.parse('2026-06-12T10:00:00'),
          clockOutAt: null,
          tags: <WorkRecordTag>[],
          memo: null,
          createdAt: DateTime.parse('2026-06-12T10:00:00'),
          updatedAt: DateTime.parse('2026-06-12T10:00:00'),
        );
        await storage.write(
          table: LocalStorageWorkRecordRepository.workRecordsTable,
          key: '2026-06-12',
          value: record.toMap(),
        );
        final LocalStorageWorkRecordRepository repository = _createRepository(
          storage: storage,
          clock: () => DateTime.parse('2026-06-12T09:00:00'),
          idGenerator: () => 'unused-id',
        );

        expect(
          repository.clockOut,
          throwsA(isA<WorkRecordRepositoryException>()),
        );
      },
    );

    test('clockOut saves clock-out time on existing record', () async {
      DateTime now = DateTime.parse('2026-06-12T09:03:00');
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => now,
        idGenerator: () => 'work-1',
      );

      await repository.clockIn();
      now = DateTime.parse('2026-06-12T18:42:00');
      final WorkRecord record = await repository.clockOut();
      final WorkRecord? savedRecord = await repository.findToday();

      expect(record.clockOutAt, DateTime.parse('2026-06-12T18:42:00'));
      expect(record.updatedAt, DateTime.parse('2026-06-12T18:42:00'));
      expect(savedRecord, record);
    });

    test('clockOut uses one clock value across midnight boundary', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      await _writeRecord(
        storage: storage,
        key: '2026-06-12',
        record: _createRecord(
          id: 'work-1',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime.parse('2026-06-12T09:00:00'),
          clockOutAt: null,
          tags: <WorkRecordTag>[],
        ),
      );
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: _sequenceClock(
          values: <DateTime>[
            DateTime.parse('2026-06-12T23:59:59'),
            DateTime.parse('2026-06-13T00:00:00'),
          ],
        ),
        idGenerator: () => 'unused-id',
      );

      final WorkRecord record = await repository.clockOut();

      expect(record.workDate, DateTime(2026, 6, 12));
      expect(record.clockOutAt, DateTime.parse('2026-06-12T23:59:59'));
      expect(record.updatedAt, DateTime.parse('2026-06-12T23:59:59'));
    });

    test(
      'clockOutAt saves selected clock-out time on existing record',
      () async {
        DateTime now = DateTime.parse('2026-06-12T09:03:00');
        final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
        final LocalStorageWorkRecordRepository repository = _createRepository(
          storage: storage,
          clock: () => now,
          idGenerator: () => 'work-1',
        );

        await repository.clockIn();
        now = DateTime.parse('2026-06-12T18:45:00');
        final WorkRecord record = await repository.clockOutAt(
          clockOutAt: DateTime.parse('2026-06-12T18:00:00'),
        );

        expect(record.clockOutAt, DateTime.parse('2026-06-12T18:00:00'));
        expect(record.updatedAt, DateTime.parse('2026-06-12T18:45:00'));
      },
    );

    test('clockOutAt saves selected date when saved after midnight', () async {
      DateTime now = DateTime.parse('2026-06-12T09:03:00');
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => now,
        idGenerator: () => 'work-1',
      );
      await repository.clockIn();
      now = DateTime.parse('2026-06-13T00:00:03');

      final WorkRecord record = await repository.clockOutAt(
        clockOutAt: DateTime.parse('2026-06-12T18:00:00'),
      );
      final WorkRecord? savedRecord = await repository.findByDate(
        workDate: DateTime(2026, 6, 12),
      );

      expect(record.workDate, DateTime(2026, 6, 12));
      expect(record.clockOutAt, DateTime.parse('2026-06-12T18:00:00'));
      expect(record.updatedAt, DateTime.parse('2026-06-13T00:00:03'));
      expect(savedRecord, record);
    });

    test('clockOut throws when already clocked out', () async {
      DateTime now = DateTime.parse('2026-06-12T09:03:00');
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => now,
        idGenerator: () => 'work-1',
      );

      await repository.clockIn();
      now = DateTime.parse('2026-06-12T18:42:00');
      await repository.clockOut();

      expect(
        repository.clockOut,
        throwsA(isA<WorkRecordRepositoryException>()),
      );
    });

    test('updateToday updates times tags and memo', () async {
      DateTime now = DateTime.parse('2026-06-12T09:03:00');
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => now,
        idGenerator: () => 'work-1',
      );
      await repository.clockIn();

      now = DateTime.parse('2026-06-12T20:00:00');
      final WorkRecord record = await repository.updateToday(
        clockInAt: DateTime.parse('2026-06-12T09:30:00'),
        clockOutAt: DateTime.parse('2026-06-12T18:40:00'),
        tags: <WorkRecordTag>[
          WorkRecordTag.overtime,
          WorkRecordTag.delayedCheckout,
        ],
        memo: '배포 대응 후 퇴근',
      );
      final WorkRecord? savedRecord = await repository.findToday();

      expect(record.clockInAt, DateTime.parse('2026-06-12T09:30:00'));
      expect(record.clockOutAt, DateTime.parse('2026-06-12T18:40:00'));
      expect(record.tags, <WorkRecordTag>[
        WorkRecordTag.overtime,
        WorkRecordTag.delayedCheckout,
      ]);
      expect(record.memo, '배포 대응 후 퇴근');
      expect(record.updatedAt, DateTime.parse('2026-06-12T20:00:00'));
      expect(savedRecord, record);
    });

    test('updateToday throws when today has no record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      expect(
        () => repository.updateToday(
          clockInAt: DateTime.parse('2026-06-12T09:03:00'),
          clockOutAt: null,
          tags: <WorkRecordTag>[],
          memo: null,
        ),
        throwsA(isA<WorkRecordRepositoryException>()),
      );
    });

    test('findByDate returns selected previous date record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final WorkRecord previousRecord = _createRecord(
        id: 'previous-record',
        workDate: DateTime(2026, 6, 1),
        clockInAt: DateTime.parse('2026-06-01T09:00:00'),
        clockOutAt: DateTime.parse('2026-06-01T18:00:00'),
        tags: <WorkRecordTag>[],
      );
      await _writeRecord(
        storage: storage,
        key: '2026-06-01',
        record: previousRecord,
      );
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      final WorkRecord? record = await repository.findByDate(
        workDate: DateTime(2026, 6, 1, 23, 30),
      );

      expect(record, previousRecord);
    });

    test('upsertByDate creates selected previous date record', () async {
      final DateTime now = DateTime.parse('2026-06-12T20:00:00');
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => now,
        idGenerator: () => 'work-previous',
      );

      final WorkRecord record = await repository.upsertByDate(
        workDate: DateTime(2026, 6, 1, 23, 30),
        clockInAt: DateTime.parse('2026-06-01T09:00:00'),
        clockOutAt: DateTime.parse('2026-06-01T18:00:00'),
        tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
        memo: '누락 기록 보정',
      );
      final WorkRecord? savedRecord = await repository.findByDate(
        workDate: DateTime(2026, 6, 1),
      );

      expect(record.id, 'work-previous');
      expect(record.workDate, DateTime(2026, 6, 1));
      expect(record.clockInAt, DateTime.parse('2026-06-01T09:00:00'));
      expect(record.clockOutAt, DateTime.parse('2026-06-01T18:00:00'));
      expect(record.tags, <WorkRecordTag>[WorkRecordTag.delayedCheckout]);
      expect(record.memo, '누락 기록 보정');
      expect(record.createdAt, now);
      expect(record.updatedAt, now);
      expect(savedRecord, record);
    });

    test('upsertByDate updates existing selected date record', () async {
      DateTime now = DateTime.parse('2026-06-12T20:00:00');
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final WorkRecord previousRecord = _createRecord(
        id: 'previous-record',
        workDate: DateTime(2026, 6, 1),
        clockInAt: DateTime.parse('2026-06-01T09:00:00'),
        clockOutAt: DateTime.parse('2026-06-01T18:00:00'),
        tags: <WorkRecordTag>[],
      );
      await _writeRecord(
        storage: storage,
        key: '2026-06-01',
        record: previousRecord,
      );
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => now,
        idGenerator: () => 'unused-id',
      );

      now = DateTime.parse('2026-06-12T21:00:00');
      final WorkRecord record = await repository.upsertByDate(
        workDate: DateTime(2026, 6, 1),
        clockInAt: DateTime.parse('2026-06-01T09:30:00'),
        clockOutAt: DateTime.parse('2026-06-01T18:40:00'),
        tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
        memo: '이전 기록 수정',
      );

      expect(record.id, 'previous-record');
      expect(record.createdAt, previousRecord.createdAt);
      expect(record.updatedAt, DateTime.parse('2026-06-12T21:00:00'));
      expect(record.clockInAt, DateTime.parse('2026-06-01T09:30:00'));
      expect(record.clockOutAt, DateTime.parse('2026-06-01T18:40:00'));
      expect(record.memo, '이전 기록 수정');
    });

    test('upsertByDate throws when time date differs from workDate', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T20:00:00'),
        idGenerator: () => 'work-previous',
      );

      await expectLater(
        repository.upsertByDate(
          workDate: DateTime(2026, 6, 1),
          clockInAt: DateTime.parse('2026-06-02T09:00:00'),
          clockOutAt: DateTime.parse('2026-06-01T18:00:00'),
          tags: <WorkRecordTag>[],
          memo: null,
        ),
        throwsA(
          isA<WorkRecordRepositoryException>().having(
            (WorkRecordRepositoryException error) => error.message,
            'message',
            allOf(
              contains('action=upsertByDate'),
              contains('workDate=2026-06-01'),
              contains('clock-in date must match workDate'),
            ),
          ),
        ),
      );
    });

    test('deleteToday removes today record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );
      await repository.clockIn();

      await repository.deleteToday();

      expect(await repository.findToday(), isNull);
      expect(
        await storage.read(
          table: LocalStorageWorkRecordRepository.workRecordsTable,
          key: '2026-06-12',
        ),
        isNull,
      );
    });

    test('deleteToday throws when today has no record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      await expectLater(
        repository.deleteToday(),
        throwsA(
          isA<WorkRecordRepositoryException>().having(
            (WorkRecordRepositoryException error) => error.message,
            'message',
            allOf(
              contains('action=deleteToday'),
              contains('table=work_records'),
              contains('workDate=2026-06-12'),
            ),
          ),
        ),
      );
    });

    test('deleteByDate removes selected previous record only', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );
      final WorkRecord previousRecord = _createRecord(
        id: 'previous-record',
        workDate: DateTime(2026, 6, 1),
        clockInAt: DateTime.parse('2026-06-01T09:00:00'),
        clockOutAt: DateTime.parse('2026-06-01T18:00:00'),
        tags: <WorkRecordTag>[],
      );
      final WorkRecord todayRecord = _createRecord(
        id: 'today-record',
        workDate: DateTime(2026, 6, 12),
        clockInAt: DateTime.parse('2026-06-12T09:00:00'),
        clockOutAt: DateTime.parse('2026-06-12T18:00:00'),
        tags: <WorkRecordTag>[],
      );
      await _writeRecord(
        storage: storage,
        key: '2026-06-01',
        record: previousRecord,
      );
      await _writeRecord(
        storage: storage,
        key: '2026-06-12',
        record: todayRecord,
      );

      await repository.deleteByDate(workDate: DateTime(2026, 6, 1, 23, 30));

      expect(
        await storage.read(
          table: LocalStorageWorkRecordRepository.workRecordsTable,
          key: '2026-06-01',
        ),
        isNull,
      );
      expect(
        await storage.read(
          table: LocalStorageWorkRecordRepository.workRecordsTable,
          key: '2026-06-12',
        ),
        isNotNull,
      );
    });

    test('deleteByDate throws when selected date has no record', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      await expectLater(
        repository.deleteByDate(workDate: DateTime(2026, 6, 1, 23, 30)),
        throwsA(
          isA<WorkRecordRepositoryException>().having(
            (WorkRecordRepositoryException error) => error.message,
            'message',
            allOf(
              contains('action=deleteByDate'),
              contains('table=work_records'),
              contains('workDate=2026-06-01'),
            ),
          ),
        ),
      );
    });

    test(
      'findByMonth returns selected month records sorted by work date',
      () async {
        final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
        final WorkRecord previousMonthRecord = _createRecord(
          id: 'previous-month',
          workDate: DateTime(2026, 5, 31),
          clockInAt: DateTime.parse('2026-05-31T09:00:00'),
          clockOutAt: DateTime.parse('2026-05-31T18:00:00'),
          tags: <WorkRecordTag>[],
        );
        final WorkRecord secondJuneRecord = _createRecord(
          id: 'june-2',
          workDate: DateTime(2026, 6, 12),
          clockInAt: DateTime.parse('2026-06-12T09:03:00'),
          clockOutAt: DateTime.parse('2026-06-12T18:42:00'),
          tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
        );
        final WorkRecord firstJuneRecord = _createRecord(
          id: 'june-1',
          workDate: DateTime(2026, 6, 3),
          clockInAt: DateTime.parse('2026-06-03T09:10:00'),
          clockOutAt: DateTime.parse('2026-06-03T18:20:00'),
          tags: <WorkRecordTag>[],
        );
        await _writeRecord(
          storage: storage,
          key: '2026-05-31',
          record: previousMonthRecord,
        );
        await _writeRecord(
          storage: storage,
          key: 'stored-under-different-key',
          record: secondJuneRecord,
        );
        await _writeRecord(
          storage: storage,
          key: '2026-06-03',
          record: firstJuneRecord,
        );
        final LocalStorageWorkRecordRepository repository = _createRepository(
          storage: storage,
          clock: () => DateTime.parse('2026-06-12T09:03:00'),
          idGenerator: () => 'unused-id',
        );

        final List<WorkRecord> records = await repository.findByMonth(
          year: 2026,
          month: 6,
        );

        expect(records, <WorkRecord>[firstJuneRecord, secondJuneRecord]);
      },
    );

    test('findByMonth includes incomplete records', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final WorkRecord incompleteRecord = _createRecord(
        id: 'incomplete',
        workDate: DateTime(2026, 6, 12),
        clockInAt: DateTime.parse('2026-06-12T09:03:00'),
        clockOutAt: null,
        tags: <WorkRecordTag>[WorkRecordTag.overtime],
      );
      await _writeRecord(
        storage: storage,
        key: '2026-06-12',
        record: incompleteRecord,
      );
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'unused-id',
      );

      final List<WorkRecord> records = await repository.findByMonth(
        year: 2026,
        month: 6,
      );

      expect(records, <WorkRecord>[incompleteRecord]);
    });

    test(
      'findByMonth throws explicit error when stored record cannot parse',
      () async {
        final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
        await storage.write(
          table: LocalStorageWorkRecordRepository.workRecordsTable,
          key: '2026-06-12',
          value: <String, Object?>{'id': 'broken', 'work_date': '2026-06-12'},
        );
        final LocalStorageWorkRecordRepository repository = _createRepository(
          storage: storage,
          clock: () => DateTime.parse('2026-06-12T09:03:00'),
          idGenerator: () => 'unused-id',
        );

        await expectLater(
          repository.findByMonth(year: 2026, month: 6),
          throwsA(
            isA<WorkRecordRepositoryException>().having(
              (WorkRecordRepositoryException error) => error.message,
              'message',
              allOf(
                contains('action=parse'),
                contains('table=work_records'),
                contains('key=2026-06-12'),
                contains('cause='),
              ),
            ),
          ),
        );
      },
    );

    test('in-memory storage does not expose mutable table maps', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final Map<String, Object?> map = <String, Object?>{
        'id': 'work-1',
        'work_date': '2026-06-12',
        'tags': <Object?>['overtime'],
      };

      await storage.write(
        table: LocalStorageWorkRecordRepository.workRecordsTable,
        key: '2026-06-12',
        value: map,
      );
      final Map<String, Map<String, Object?>> firstRead = await storage.readAll(
        table: LocalStorageWorkRecordRepository.workRecordsTable,
      );
      firstRead['2026-06-12']!['id'] = 'changed';
      (firstRead['2026-06-12']!['tags']! as List<Object?>).add('holidayWork');
      final Map<String, Map<String, Object?>> secondRead = await storage
          .readAll(table: LocalStorageWorkRecordRepository.workRecordsTable);

      expect(secondRead['2026-06-12']!['id'], 'work-1');
      expect(secondRead['2026-06-12']!['tags'], <Object?>['overtime']);
    });

    test('storage write failure is not ignored', () async {
      final FailingWriteKeyValueStorage storage = FailingWriteKeyValueStorage();
      final LocalStorageWorkRecordRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:03:00'),
        idGenerator: () => 'work-1',
      );

      expect(repository.clockIn, throwsA(isA<StateError>()));
    });

    test('in-memory storage does not expose mutable stored maps', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final Map<String, Object?> map = <String, Object?>{
        'id': 'work-1',
        'work_date': '2026-06-12',
      };

      await storage.write(
        table: LocalStorageWorkRecordRepository.workRecordsTable,
        key: '2026-06-12',
        value: map,
      );
      map['id'] = 'changed';
      final Map<String, Object?>? storedMap = await storage.read(
        table: LocalStorageWorkRecordRepository.workRecordsTable,
        key: '2026-06-12',
      );
      storedMap!['id'] = 'changed-again';
      final Map<String, Object?>? rereadMap = await storage.read(
        table: LocalStorageWorkRecordRepository.workRecordsTable,
        key: '2026-06-12',
      );

      expect(rereadMap!['id'], 'work-1');
    });
  });
}

LocalStorageWorkRecordRepository _createRepository({
  required KeyValueStorage storage,
  required DateTime Function() clock,
  required String Function() idGenerator,
}) {
  return LocalStorageWorkRecordRepository(
    storage: storage,
    clock: clock,
    idGenerator: idGenerator,
  );
}

DateTime Function() _sequenceClock({required List<DateTime> values}) {
  int index = 0;
  return () {
    if (index >= values.length) {
      throw StateError('sequence clock exhausted index=$index');
    }
    final DateTime value = values[index];
    index += 1;
    return value;
  };
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
    updatedAt: DateTime(workDate.year, workDate.month, workDate.day, 19),
  );
}

final class FailingWriteKeyValueStorage implements KeyValueStorage {
  @override
  Future<Map<String, Object?>?> read({
    required String table,
    required String key,
  }) async {
    return null;
  }

  @override
  Future<Map<String, Map<String, Object?>>> readAll({
    required String table,
  }) async {
    return <String, Map<String, Object?>>{};
  }

  @override
  Future<void> write({
    required String table,
    required String key,
    required Map<String, Object?> value,
  }) async {
    throw StateError('write failed table=$table key=$key');
  }

  @override
  Future<void> delete({required String table, required String key}) async {
    throw StateError('delete failed table=$table key=$key');
  }
}
