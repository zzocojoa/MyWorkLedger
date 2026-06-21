import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/storage/persistent_key_value_storage.dart';
import 'package:workledger/features/work_record/data/local_storage_work_record_repository.dart';

typedef _StorageIsolateMutation = ({String operation, String key});

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

    test('deletes a persisted value across adapter instances', () async {
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
      await firstStorage.delete(table: 'work_records', key: '2026-06-12');

      final PersistentKeyValueStorage secondStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Object?>? savedValue = await secondStorage.read(
        table: 'work_records',
        key: '2026-06-12',
      );

      expect(savedValue, isNull);
      await directory.delete(recursive: true);
    });

    test(
      'preserves concurrent writes from separate adapter instances',
      () async {
        final Directory directory = await _createTempDirectory();
        final List<String> keys = List<String>.generate(
          12,
          (int index) => 'record-$index',
        );
        final List<Future<void>> writes = <Future<void>>[];
        for (final String key in keys) {
          final PersistentKeyValueStorage storage = _createStorage(
            directory: directory,
          );
          writes.add(
            storage.write(
              table: 'work_records',
              key: key,
              value: <String, Object?>{'id': key, 'work_date': '2026-06-12'},
            ),
          );
        }

        await Future.wait(writes);

        final PersistentKeyValueStorage savedStorage = _createStorage(
          directory: directory,
        );
        final Map<String, Map<String, Object?>> rows = await savedStorage
            .readAll(table: 'work_records');
        expect(rows.keys, unorderedEquals(keys));
        await directory.delete(recursive: true);
      },
    );

    test('preserves concurrent write and delete mutations', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage seedStorage = _createStorage(
        directory: directory,
      );
      await seedStorage.write(
        table: 'work_records',
        key: 'delete-target',
        value: <String, Object?>{
          'id': 'delete-target',
          'work_date': '2026-06-12',
        },
      );
      await seedStorage.write(
        table: 'work_records',
        key: 'keep-target',
        value: <String, Object?>{
          'id': 'keep-target',
          'work_date': '2026-06-12',
        },
      );
      final PersistentKeyValueStorage deleteStorage = _createStorage(
        directory: directory,
      );
      final PersistentKeyValueStorage writeStorage = _createStorage(
        directory: directory,
      );

      await Future.wait(<Future<void>>[
        deleteStorage.delete(table: 'work_records', key: 'delete-target'),
        writeStorage.write(
          table: 'work_records',
          key: 'write-target',
          value: <String, Object?>{
            'id': 'write-target',
            'work_date': '2026-06-12',
          },
        ),
      ]);

      final PersistentKeyValueStorage savedStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Map<String, Object?>> rows = await savedStorage.readAll(
        table: 'work_records',
      );
      expect(
        rows.keys,
        unorderedEquals(<String>['keep-target', 'write-target']),
      );
      await directory.delete(recursive: true);
    });

    test('preserves concurrent writes from separate Dart processes', () async {
      final Directory directory = await _createTempDirectory();
      final File executable = await _compileStorageProcessWorker(
        directory: directory,
      );
      final List<String> keys = List<String>.generate(
        8,
        (int index) => 'process-record-$index',
      );

      final List<ProcessResult> results = await Future.wait(
        keys.map(
          (String key) => _runStorageProcess(
            executable: executable,
            directory: directory,
            operation: 'write',
            key: key,
          ),
        ),
      );

      for (final ProcessResult result in results) {
        expect(result.exitCode, 0, reason: _processFailureReason(result));
      }
      final PersistentKeyValueStorage savedStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Map<String, Object?>> rows = await savedStorage.readAll(
        table: 'work_records',
      );
      expect(rows.keys, unorderedEquals(keys));
      await directory.delete(recursive: true);
    });

    test('preserves process write and delete mutations', () async {
      final Directory directory = await _createTempDirectory();
      final File executable = await _compileStorageProcessWorker(
        directory: directory,
      );
      final PersistentKeyValueStorage seedStorage = _createStorage(
        directory: directory,
      );
      await seedStorage.write(
        table: 'work_records',
        key: 'process-delete-target',
        value: <String, Object?>{
          'id': 'process-delete-target',
          'work_date': '2026-06-12',
        },
      );
      await seedStorage.write(
        table: 'work_records',
        key: 'process-keep-target',
        value: <String, Object?>{
          'id': 'process-keep-target',
          'work_date': '2026-06-12',
        },
      );

      final List<ProcessResult> results =
          await Future.wait(<Future<ProcessResult>>[
            _runStorageProcess(
              executable: executable,
              directory: directory,
              operation: 'delete',
              key: 'process-delete-target',
            ),
            _runStorageProcess(
              executable: executable,
              directory: directory,
              operation: 'write',
              key: 'process-write-target',
            ),
          ]);

      for (final ProcessResult result in results) {
        expect(result.exitCode, 0, reason: _processFailureReason(result));
      }
      final PersistentKeyValueStorage savedStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Map<String, Object?>> rows = await savedStorage.readAll(
        table: 'work_records',
      );
      expect(
        rows.keys,
        unorderedEquals(<String>[
          'process-keep-target',
          'process-write-target',
        ]),
      );
      await directory.delete(recursive: true);
    });

    test('preserves concurrent writes from same-process isolates', () async {
      final Directory directory = await _createTempDirectory();
      final List<String> keys = List<String>.generate(
        8,
        (int index) => 'isolate-record-$index',
      );

      await _runStorageIsolates(
        directory: directory,
        mutations: keys
            .map((String key) => (operation: 'write', key: key))
            .toList(),
      );

      final PersistentKeyValueStorage savedStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Map<String, Object?>> rows = await savedStorage.readAll(
        table: 'work_records',
      );
      expect(rows.keys, unorderedEquals(keys));
      await directory.delete(recursive: true);
    });

    test('preserves same-process isolate write and delete mutations', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage seedStorage = _createStorage(
        directory: directory,
      );
      await seedStorage.write(
        table: 'work_records',
        key: 'isolate-delete-target',
        value: <String, Object?>{
          'id': 'isolate-delete-target',
          'work_date': '2026-06-12',
        },
      );
      await seedStorage.write(
        table: 'work_records',
        key: 'isolate-keep-target',
        value: <String, Object?>{
          'id': 'isolate-keep-target',
          'work_date': '2026-06-12',
        },
      );

      await _runStorageIsolates(
        directory: directory,
        mutations: <_StorageIsolateMutation>[
          (operation: 'delete', key: 'isolate-delete-target'),
          (operation: 'write', key: 'isolate-write-target'),
        ],
      );

      final PersistentKeyValueStorage savedStorage = _createStorage(
        directory: directory,
      );
      final Map<String, Map<String, Object?>> rows = await savedStorage.readAll(
        table: 'work_records',
      );
      expect(
        rows.keys,
        unorderedEquals(<String>[
          'isolate-keep-target',
          'isolate-write-target',
        ]),
      );
      await directory.delete(recursive: true);
    });

    test('recovers stale lock file left by a crashed mutation', () async {
      final Directory directory = await _createTempDirectory();
      final File file = PersistentKeyValueStorage.fileInDirectory(
        directory: directory,
      );
      final File lockFile = File('${file.path}.lock');
      final PersistentStorageTables existingTables =
          <String, Map<String, Map<String, Object?>>>{
            'work_records': <String, Map<String, Object?>>{
              'existing-record': <String, Object?>{
                'id': 'existing-record',
                'work_date': '2026-06-12',
              },
            },
          };
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(existingTables), flush: true);
      await lockFile.writeAsString('stale lock', flush: true);
      await lockFile.setLastModified(
        DateTime.now().subtract(const Duration(minutes: 3)),
      );
      final PersistentKeyValueStorage storage = PersistentKeyValueStorage(
        file: file,
      );

      await storage.write(
        table: 'work_records',
        key: 'new-record',
        value: <String, Object?>{'id': 'new-record', 'work_date': '2026-06-12'},
      );

      final Map<String, Map<String, Object?>> rows = await storage.readAll(
        table: 'work_records',
      );
      expect(
        rows.keys,
        unorderedEquals(<String>['existing-record', 'new-record']),
      );
      expect(await lockFile.exists(), isFalse);
      await directory.delete(recursive: true);
    });

    test('delete is idempotent when table or key is missing', () async {
      final Directory directory = await _createTempDirectory();
      final PersistentKeyValueStorage storage = _createStorage(
        directory: directory,
      );

      await storage.delete(table: 'work_records', key: 'missing-key');

      final Map<String, Map<String, Object?>> rows = await storage.readAll(
        table: 'work_records',
      );

      expect(rows, isEmpty);
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

    test('keeps existing file when temporary write fails', () async {
      final Directory directory = await _createTempDirectory();
      final File file = PersistentKeyValueStorage.fileInDirectory(
        directory: directory,
      );
      final PersistentStorageTables existingTables =
          <String, Map<String, Map<String, Object?>>>{
            'work_records': <String, Map<String, Object?>>{
              '2026-06-12': _createWorkRecordMap(),
            },
          };
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(existingTables), flush: true);
      await Directory('${file.path}.tmp').create();
      final PersistentKeyValueStorage storage = PersistentKeyValueStorage(
        file: file,
      );

      await expectLater(
        storage.write(
          table: 'work_records',
          key: '2026-06-13',
          value: <String, Object?>{'id': 'work-2', 'work_date': '2026-06-13'},
        ),
        throwsA(
          isA<PersistentKeyValueStorageException>().having(
            (PersistentKeyValueStorageException error) => error.message,
            'message',
            allOf(
              contains('action=write'),
              contains('table=work_records'),
              contains('key=2026-06-13'),
              contains('temporaryPath=${file.path}.tmp'),
            ),
          ),
        ),
      );

      final Object? savedTables = jsonDecode(await file.readAsString());
      expect(savedTables, existingTables);
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

Future<File> _compileStorageProcessWorker({
  required Directory directory,
}) async {
  final File executable = File(
    '${directory.path}${Platform.pathSeparator}storage_worker',
  );
  final ProcessResult result = await Process.run('dart', <String>[
    'compile',
    'exe',
    'test/core/storage/persistent_key_value_storage_process_worker.dart',
    '-o',
    executable.path,
  ], workingDirectory: Directory.current.path);
  if (result.exitCode != 0) {
    fail(_processFailureReason(result));
  }
  return executable;
}

Future<ProcessResult> _runStorageProcess({
  required File executable,
  required Directory directory,
  required String operation,
  required String key,
}) {
  return Process.run(executable.path, <String>[
    directory.path,
    operation,
    key,
  ], workingDirectory: Directory.current.path);
}

Future<void> _runStorageIsolates({
  required Directory directory,
  required List<_StorageIsolateMutation> mutations,
}) async {
  final ReceivePort receivePort = ReceivePort();
  final List<Isolate> isolates = <Isolate>[];
  try {
    for (final _StorageIsolateMutation mutation in mutations) {
      final Isolate isolate = await Isolate.spawn<List<Object>>(
        _runStorageIsolateWorker,
        <Object>[
          receivePort.sendPort,
          directory.path,
          mutation.operation,
          mutation.key,
        ],
      );
      isolates.add(isolate);
    }

    final StreamIterator<Object?> iterator = StreamIterator<Object?>(
      receivePort,
    );
    final List<SendPort> startPorts = <SendPort>[];
    while (startPorts.length < mutations.length) {
      if (!await iterator.moveNext()) {
        fail('isolate result port closed before ready');
      }
      final Object? message = iterator.current;
      startPorts.add(_parseStorageIsolateReady(message: message));
    }

    for (final SendPort startPort in startPorts) {
      startPort.send('start');
    }

    final List<Map<Object?, Object?>> results = <Map<Object?, Object?>>[];
    while (results.length < mutations.length) {
      if (!await iterator.moveNext()) {
        fail('isolate result port closed before result');
      }
      final Object? message = iterator.current;
      results.add(_parseStorageIsolateResult(message: message));
    }

    for (final Map<Object?, Object?> result in results) {
      if (result['exitCode'] != 0) {
        fail('error=${result['error']}\nstackTrace=${result['stackTrace']}');
      }
    }
  } finally {
    receivePort.close();
    for (final Isolate isolate in isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
  }
}

SendPort _parseStorageIsolateReady({required Object? message}) {
  if (message is! Map<Object?, Object?>) {
    fail('unexpected isolate message=$message');
  }
  if (message['type'] != 'ready') {
    fail('unexpected isolate message=$message');
  }
  return message['startPort']! as SendPort;
}

Map<Object?, Object?> _parseStorageIsolateResult({required Object? message}) {
  if (message is! Map<Object?, Object?>) {
    fail('unexpected isolate result=$message');
  }
  if (message['type'] != 'result') {
    fail('unexpected isolate result=$message');
  }
  return message;
}

Future<void> _runStorageIsolateWorker(List<Object> arguments) async {
  final SendPort sendPort = arguments[0] as SendPort;
  final String directoryPath = arguments[1] as String;
  final String operation = arguments[2] as String;
  final String key = arguments[3] as String;
  final ReceivePort startPort = ReceivePort();
  sendPort.send(<String, Object?>{
    'type': 'ready',
    'startPort': startPort.sendPort,
  });
  await startPort.first;
  startPort.close();
  try {
    final PersistentKeyValueStorage storage = PersistentKeyValueStorage(
      file: PersistentKeyValueStorage.fileInDirectory(
        directory: Directory(directoryPath),
      ),
    );
    if (operation == 'write') {
      await storage.write(
        table: 'work_records',
        key: key,
        value: <String, Object?>{'id': key, 'work_date': '2026-06-12'},
      );
      sendPort.send(<String, Object?>{'type': 'result', 'exitCode': 0});
      return;
    }
    if (operation == 'delete') {
      await storage.delete(table: 'work_records', key: key);
      sendPort.send(<String, Object?>{'type': 'result', 'exitCode': 0});
      return;
    }
    sendPort.send(<String, Object?>{
      'type': 'result',
      'exitCode': 64,
      'error': 'unknown operation=$operation key=$key',
    });
  } catch (error, stackTrace) {
    sendPort.send(<String, Object?>{
      'type': 'result',
      'exitCode': 1,
      'error': error.toString(),
      'stackTrace': stackTrace.toString(),
    });
  }
}

String _processFailureReason(ProcessResult result) {
  return 'stdout=${result.stdout}\nstderr=${result.stderr}';
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
