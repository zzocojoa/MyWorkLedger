import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/storage/persistent_key_value_storage.dart';
import 'package:workledger/features/work_record/data/local_storage_work_record_repository.dart';

void main() {
  group('PersistentKeyValueStorage', () {
    test('reads null when storage file does not exist', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage storage = _createStorage(
        directory: directory,
      );

      final Map<String, Object?>? value = await storage.read(
        table: 'work_records',
        key: '2026-06-12',
      );

      expect(value, isNull);
      await directory.delete(recursive: true);
    });

    test('persists values across adapter instances', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage firstStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Object?> value = _createWorkRecordMap();

      await firstStorage.write(
        table: 'work_records',
        key: '2026-06-12',
        value: value,
      );

      final PersistentKeyValueStorage secondStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Object?>? savedValue = await secondStorage.read(
        table: 'work_records',
        key: '2026-06-12',
      );

      expect(savedValue, value);
      await directory.delete(recursive: true);
    });

    test('does not expose mutable input maps or read maps', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage storage = _createStorage(
        directory: directory,
      );
      final Map<String, Object?> value = <String, Object?>{
        'id': 'work-1',
        'work_date': '2026-06-12',
        'tags': <Object?>['overtime'],
      };

      await storage.write(
        table: 'work_records',
        key: '2026-06-12',
        value: value,
      );
      value['id'] = 'changed';
      (value['tags']! as List<Object?>).add('holidayWork');

      final Map<String, Object?>? firstRead = await storage.read(
        table: 'work_records',
        key: '2026-06-12',
      );
      firstRead!['id'] = 'changed-again';
      (firstRead['tags']! as List<Object?>).add('delayedCheckout');

      final Map<String, Object?>? secondRead = await storage.read(
        table: 'work_records',
        key: '2026-06-12',
      );

      expect(secondRead!['id'], 'work-1');
      expect(secondRead['tags'], <Object?>['overtime']);
      await directory.delete(recursive: true);
    });

    test('does not expose mutable table maps from readAll', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage storage = _createStorage(
        directory: directory,
      );
      final Map<String, Object?> value = _createWorkRecordMap();

      await storage.write(
        table: 'work_records',
        key: '2026-06-12',
        value: value,
      );

      final Map<String, Map<String, Object?>> firstRead = await storage.readAll(
        table: 'work_records',
      );
      firstRead['2026-06-12']!['id'] = 'changed';
      (firstRead['2026-06-12']!['tags']! as List<Object?>).add('holidayWork');

      final Map<String, Map<String, Object?>> secondRead = await storage
          .readAll(table: 'work_records');

      expect(secondRead['2026-06-12']!['id'], 'work-1');
      expect(secondRead['2026-06-12']!['tags'], <Object?>['overtime']);
      await directory.delete(recursive: true);
    });

    test('supports WorkRecord repository after storage recreation', () async {
      final Directory directory = await _createTempDirectory();
      final DateTime now = DateTime.parse('2026-06-12T09:03:00');
      final LocalStorageWorkRecordRepository firstRepository =
          _createRepository(
            storage: _createStorage(directory: directory),
            clock: () => now,
          );

      final WorkRecord createdRecord = await firstRepository.clockIn();

      final LocalStorageWorkRecordRepository secondRepository =
          _createRepository(
            storage: _createStorage(directory: directory),
            clock: () => now,
          );
      final WorkRecord? savedRecord = await secondRepository.findToday();

      expect(savedRecord, createdRecord);
      await directory.delete(recursive: true);
    });

    test('throws explicit error with context when JSON is invalid', () async {
      final Directory directory = await _createTempDirectory();
      final File file = PersistentKeyValueStorage.fileInDirectory(
        directory: directory,
      );
      await file.parent.create(recursive: true);
      await file.writeAsString('{');
      final PersistentKeyValueStorage storage = PersistentKeyValueStorage(
        file: file,
      );

      await expectLater(
        storage.read(table: 'work_records', key: '2026-06-12'),
        throwsA(
          isA<PersistentKeyValueStorageException>().having(
            (PersistentKeyValueStorageException error) => error.message,
            'message',
            allOf(
              contains('action=read'),
              contains('table=work_records'),
              contains('key=2026-06-12'),
              contains('rule=valid JSON'),
            ),
          ),
        ),
      );
      await directory.delete(recursive: true);
    });

    test('throws explicit error when value is not JSON-compatible', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage storage = _createStorage(
        directory: directory,
      );

      await expectLater(
        storage.write(
          table: 'work_records',
          key: '2026-06-12',
          value: <String, Object?>{'created_at': DateTime(2026, 6, 12)},
        ),
        throwsA(
          isA<PersistentKeyValueStorageException>().having(
            (PersistentKeyValueStorageException error) => error.message,
            'message',
            allOf(
              contains('action=write'),
              contains('table=work_records'),
              contains('key=2026-06-12'),
              contains('field=created_at'),
            ),
          ),
        ),
      );
      await directory.delete(recursive: true);
    });
  });
}

Future<Directory> _createTempDirectory() {
  return Directory.systemTemp.createTemp('workledger-storage-test-');
}

PersistentKeyValueStorage _createStorage({required Directory directory}) {
  return PersistentKeyValueStorage(
    file: PersistentKeyValueStorage.fileInDirectory(directory: directory),
  );
}

LocalStorageWorkRecordRepository _createRepository({
  required PersistentKeyValueStorage storage,
  required DateTime Function() clock,
}) {
  return LocalStorageWorkRecordRepository(
    storage: storage,
    clock: clock,
    idGenerator: () => 'work-1',
  );
}

Map<String, Object?> _createWorkRecordMap() {
  return <String, Object?>{
    'id': 'work-1',
    'work_date': '2026-06-12',
    'clock_in_at': '2026-06-12T09:03:00.000',
    'clock_out_at': null,
    'tags': <Object?>['overtime'],
    'memo': null,
    'created_at': '2026-06-12T09:03:00.000',
    'updated_at': '2026-06-12T09:03:00.000',
  };
}
