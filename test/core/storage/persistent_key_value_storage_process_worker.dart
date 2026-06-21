import 'dart:io';

import 'package:workledger/core/storage/persistent_key_value_storage.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 3) {
    stderr.writeln(
      'usage: persistent_key_value_storage_process_worker <directory> <operation> <key>',
    );
    exitCode = 64;
    return;
  }

  final String directoryPath = arguments[0];
  final String operation = arguments[1];
  final String key = arguments[2];
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
    return;
  }

  if (operation == 'delete') {
    await storage.delete(table: 'work_records', key: key);
    return;
  }

  stderr.writeln('unknown operation=$operation key=$key');
  exitCode = 64;
}
