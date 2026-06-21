import '../../../core/models/work_record.dart';
import '../../../core/storage/key_value_storage.dart';
import '../domain/work_record_repository.dart';

typedef WorkRecordClock = DateTime Function();
typedef WorkRecordIdGenerator = String Function();

final class LocalStorageWorkRecordRepository implements WorkRecordRepository {
  const LocalStorageWorkRecordRepository({
    required this.storage,
    required this.clock,
    required this.idGenerator,
  });

  final KeyValueStorage storage;
  final WorkRecordClock clock;
  final WorkRecordIdGenerator idGenerator;

  static const String workRecordsTable = 'work_records';

  @override
  Future<WorkRecord?> findToday() async {
    final DateTime now = clock();
    final DateTime today = _dateOnly(now);
    return findByDate(workDate: today);
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    final DateTime targetDate = _dateOnly(workDate);
    return _readByDate(targetDate);
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    _validateYearMonth(year: year, month: month);
    final Map<String, Map<String, Object?>> rows = await storage.readAll(
      table: workRecordsTable,
    );
    final List<WorkRecord> records = <WorkRecord>[];
    for (final MapEntry<String, Map<String, Object?>> row in rows.entries) {
      final WorkRecord record = _parseRecordMap(key: row.key, map: row.value);
      if (record.workDate.year == year && record.workDate.month == month) {
        records.add(record);
      }
    }
    return _sortByWorkDate(records);
  }

  @override
  Future<WorkRecord> clockIn() async {
    final DateTime now = clock();
    return _clockInAt(action: 'clockIn', clockInAt: now, savedAt: now);
  }

  @override
  Future<WorkRecord> clockInAt({required DateTime clockInAt}) async {
    final DateTime now = clock();
    return _clockInAt(action: 'clockInAt', clockInAt: clockInAt, savedAt: now);
  }

  Future<WorkRecord> _clockInAt({
    required String action,
    required DateTime clockInAt,
    required DateTime savedAt,
  }) async {
    final DateTime today = _dateOnly(savedAt);
    _validateRecordTimesForDate(
      action: action,
      workDate: today,
      clockInAt: clockInAt,
      clockOutAt: null,
    );
    final WorkRecord? existingRecord = await _readByDate(today);
    if (existingRecord != null && existingRecord.clockInAt != null) {
      throw WorkRecordRepositoryException(
        'action=$action table=$workRecordsTable workDate=${_formatDateOnly(today)} clockInAt=${clockInAt.toIso8601String()} rule=already clocked in',
      );
    }

    final WorkRecord record = existingRecord == null
        ? WorkRecord(
            id: idGenerator(),
            workDate: today,
            clockInAt: clockInAt,
            clockOutAt: null,
            tags: <WorkRecordTag>[],
            memo: null,
            createdAt: savedAt,
            updatedAt: savedAt,
          )
        : existingRecord.copyWith(
            id: existingRecord.id,
            workDate: existingRecord.workDate,
            clockInAt: clockInAt,
            clockOutAt: existingRecord.clockOutAt,
            tags: existingRecord.tags,
            memo: existingRecord.memo,
            createdAt: existingRecord.createdAt,
            updatedAt: savedAt,
          );

    await _write(record);
    return record;
  }

  @override
  Future<WorkRecord> clockOut() async {
    final DateTime now = clock();
    return _clockOutAt(action: 'clockOut', clockOutAt: now, savedAt: now);
  }

  @override
  Future<WorkRecord> clockOutAt({required DateTime clockOutAt}) async {
    final DateTime now = clock();
    return _clockOutAt(
      action: 'clockOutAt',
      clockOutAt: clockOutAt,
      savedAt: now,
    );
  }

  Future<WorkRecord> _clockOutAt({
    required String action,
    required DateTime clockOutAt,
    required DateTime savedAt,
  }) async {
    final DateTime today = _dateOnly(savedAt);
    _validateRecordTimesForDate(
      action: action,
      workDate: today,
      clockInAt: null,
      clockOutAt: clockOutAt,
    );
    final WorkRecord? existingRecord = await _readByDate(today);
    if (existingRecord == null) {
      throw WorkRecordRepositoryException(
        'action=$action table=$workRecordsTable workDate=${_formatDateOnly(today)} clockOutAt=${clockOutAt.toIso8601String()} rule=missing work record',
      );
    }
    final DateTime? clockInAt = existingRecord.clockInAt;
    if (clockInAt == null) {
      throw WorkRecordRepositoryException(
        'action=$action table=$workRecordsTable workDate=${_formatDateOnly(today)} clockOutAt=${clockOutAt.toIso8601String()} rule=missing clock-in',
      );
    }
    if (existingRecord.clockOutAt != null) {
      throw WorkRecordRepositoryException(
        'action=$action table=$workRecordsTable workDate=${_formatDateOnly(today)} clockOutAt=${clockOutAt.toIso8601String()} rule=already clocked out',
      );
    }
    if (clockOutAt.isBefore(clockInAt)) {
      throw WorkRecordRepositoryException(
        'action=$action table=$workRecordsTable workDate=${_formatDateOnly(today)} clockInAt=${clockInAt.toIso8601String()} clockOutAt=${clockOutAt.toIso8601String()} rule=clock-out must be after clock-in',
      );
    }

    final WorkRecord record = existingRecord.copyWith(
      id: existingRecord.id,
      workDate: existingRecord.workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: existingRecord.tags,
      memo: existingRecord.memo,
      createdAt: existingRecord.createdAt,
      updatedAt: savedAt,
    );

    await _write(record);
    return record;
  }

  @override
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    final DateTime now = clock();
    final DateTime today = _dateOnly(now);
    final WorkRecord? existingRecord = await _readByDate(today);
    if (existingRecord == null) {
      throw WorkRecordRepositoryException(
        'action=updateToday table=$workRecordsTable workDate=${_formatDateOnly(today)} rule=missing work record',
      );
    }
    _validateRecordTimesForDate(
      action: 'updateToday',
      workDate: today,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
    );

    final WorkRecord record = existingRecord.copyWith(
      id: existingRecord.id,
      workDate: existingRecord.workDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
      tags: tags,
      memo: memo,
      createdAt: existingRecord.createdAt,
      updatedAt: now,
    );

    await _write(record);
    return record;
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    final DateTime now = clock();
    final DateTime targetDate = _dateOnly(workDate);
    _validateRecordTimesForDate(
      action: 'upsertByDate',
      workDate: targetDate,
      clockInAt: clockInAt,
      clockOutAt: clockOutAt,
    );
    final WorkRecord? existingRecord = await _readByDate(targetDate);
    final WorkRecord record = existingRecord == null
        ? WorkRecord(
            id: idGenerator(),
            workDate: targetDate,
            clockInAt: clockInAt,
            clockOutAt: clockOutAt,
            tags: tags,
            memo: memo,
            createdAt: now,
            updatedAt: now,
          )
        : existingRecord.copyWith(
            id: existingRecord.id,
            workDate: existingRecord.workDate,
            clockInAt: clockInAt,
            clockOutAt: clockOutAt,
            tags: tags,
            memo: memo,
            createdAt: existingRecord.createdAt,
            updatedAt: now,
          );

    await _write(record);
    return record;
  }

  @override
  Future<void> deleteToday() async {
    final DateTime now = clock();
    final DateTime today = _dateOnly(now);
    final WorkRecord? existingRecord = await _readByDate(today);
    if (existingRecord == null) {
      throw WorkRecordRepositoryException(
        'action=deleteToday table=$workRecordsTable workDate=${_formatDateOnly(today)} rule=missing work record',
      );
    }
    await storage.delete(
      table: workRecordsTable,
      key: _formatDateOnly(existingRecord.workDate),
    );
  }

  @override
  Future<void> deleteByDate({required DateTime workDate}) async {
    final DateTime targetDate = _dateOnly(workDate);
    final WorkRecord? existingRecord = await _readByDate(targetDate);
    if (existingRecord == null) {
      throw WorkRecordRepositoryException(
        'action=deleteByDate table=$workRecordsTable workDate=${_formatDateOnly(targetDate)} rule=missing work record',
      );
    }
    await storage.delete(
      table: workRecordsTable,
      key: _formatDateOnly(existingRecord.workDate),
    );
  }

  Future<WorkRecord?> _readByDate(DateTime workDate) async {
    final String key = _formatDateOnly(workDate);
    final Map<String, Object?>? map = await storage.read(
      table: workRecordsTable,
      key: key,
    );
    if (map == null) {
      return null;
    }
    return _parseRecordMap(key: key, map: map);
  }

  Future<void> _write(WorkRecord record) async {
    await storage.write(
      table: workRecordsTable,
      key: _formatDateOnly(record.workDate),
      value: record.toMap(),
    );
  }
}

WorkRecord _parseRecordMap({
  required String key,
  required Map<String, Object?> map,
}) {
  try {
    return WorkRecord.fromMap(map);
  } on WorkRecordParseException catch (error) {
    throw WorkRecordRepositoryException(
      'action=parse table=${LocalStorageWorkRecordRepository.workRecordsTable} key=$key cause=${error.message}',
    );
  } on ArgumentError catch (error) {
    throw WorkRecordRepositoryException(
      'action=parse table=${LocalStorageWorkRecordRepository.workRecordsTable} key=$key cause=${error.message}',
    );
  }
}

List<WorkRecord> _sortByWorkDate(List<WorkRecord> records) {
  final List<WorkRecord> sortedRecords = List<WorkRecord>.of(records);
  sortedRecords.sort((WorkRecord left, WorkRecord right) {
    final int dateCompare = left.workDate.compareTo(right.workDate);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return left.id.compareTo(right.id);
  });
  return sortedRecords;
}

void _validateYearMonth({required int year, required int month}) {
  if (year < 2000 || year > 2100) {
    throw WorkRecordRepositoryException(
      'action=findByMonth table=${LocalStorageWorkRecordRepository.workRecordsTable} year=$year rule=between 2000 and 2100',
    );
  }
  if (month < 1 || month > 12) {
    throw WorkRecordRepositoryException(
      'action=findByMonth table=${LocalStorageWorkRecordRepository.workRecordsTable} month=$month rule=between 1 and 12',
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _isSameDate({required DateTime left, required DateTime right}) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

void _validateRecordTimesForDate({
  required String action,
  required DateTime workDate,
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
}) {
  if (clockInAt != null && !_isSameDate(left: workDate, right: clockInAt)) {
    throw WorkRecordRepositoryException(
      'action=$action table=${LocalStorageWorkRecordRepository.workRecordsTable} workDate=${_formatDateOnly(workDate)} clockInAt=${clockInAt.toIso8601String()} rule=clock-in date must match workDate',
    );
  }
  if (clockOutAt != null && !_isSameDate(left: workDate, right: clockOutAt)) {
    throw WorkRecordRepositoryException(
      'action=$action table=${LocalStorageWorkRecordRepository.workRecordsTable} workDate=${_formatDateOnly(workDate)} clockOutAt=${clockOutAt.toIso8601String()} rule=clock-out date must match workDate',
    );
  }
}

String _formatDateOnly(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
