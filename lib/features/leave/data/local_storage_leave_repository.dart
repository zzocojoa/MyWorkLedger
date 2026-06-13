import '../../../core/models/leave_balance.dart';
import '../../../core/models/leave_usage.dart';
import '../../../core/storage/key_value_storage.dart';
import '../domain/leave_repository.dart';

typedef LeaveClock = DateTime Function();
typedef LeaveIdGenerator = String Function();

final class LocalStorageLeaveRepository implements LeaveRepository {
  const LocalStorageLeaveRepository({
    required this.storage,
    required this.clock,
    required this.idGenerator,
  });

  final KeyValueStorage storage;
  final LeaveClock clock;
  final LeaveIdGenerator idGenerator;

  static const String leaveBalancesTable = 'leave_balances';
  static const String leaveUsagesTable = 'leave_usages';

  @override
  Future<LeaveBalance?> findBalanceByYear({required int year}) async {
    _validateYear(year: year, action: 'findBalanceByYear');
    final Map<String, Object?>? map = await storage.read(
      table: leaveBalancesTable,
      key: _formatYearKey(year),
    );
    if (map == null) {
      return null;
    }
    return _parseBalanceMap(key: _formatYearKey(year), map: map);
  }

  @override
  Future<LeaveBalance> saveBalance({
    required int year,
    required int totalLeaveMinutes,
  }) async {
    _validateYear(year: year, action: 'saveBalance');
    final DateTime now = clock();
    final LeaveBalance? existingBalance = await findBalanceByYear(year: year);
    final LeaveBalance balance = existingBalance == null
        ? LeaveBalance(
            id: idGenerator(),
            year: year,
            totalLeaveMinutes: totalLeaveMinutes,
            createdAt: now,
            updatedAt: now,
          )
        : existingBalance.copyWith(
            id: existingBalance.id,
            year: existingBalance.year,
            totalLeaveMinutes: totalLeaveMinutes,
            createdAt: existingBalance.createdAt,
            updatedAt: now,
          );
    await storage.write(
      table: leaveBalancesTable,
      key: _formatYearKey(year),
      value: balance.toMap(),
    );
    return balance;
  }

  @override
  Future<List<LeaveUsage>> findUsagesByYear({required int year}) async {
    _validateYear(year: year, action: 'findUsagesByYear');
    final Map<String, Map<String, Object?>> rows = await storage.readAll(
      table: leaveUsagesTable,
    );
    final List<LeaveUsage> usages = <LeaveUsage>[];
    for (final MapEntry<String, Map<String, Object?>> row in rows.entries) {
      final LeaveUsage usage = _parseUsageMap(key: row.key, map: row.value);
      if (usage.usedOn.year == year) {
        usages.add(usage);
      }
    }
    return _sortUsages(usages);
  }

  @override
  Future<LeaveUsage> addUsage({
    required DateTime usedOn,
    required int usedLeaveMinutes,
    required String? memo,
  }) async {
    final DateTime now = clock();
    final DateTime usedOnDate = _dateOnly(usedOn);
    final LeaveUsage usage = LeaveUsage(
      id: idGenerator(),
      usedOn: usedOnDate,
      usedLeaveMinutes: usedLeaveMinutes,
      memo: memo,
      createdAt: now,
      updatedAt: now,
    );
    await storage.write(
      table: leaveUsagesTable,
      key: usage.id,
      value: usage.toMap(),
    );
    return usage;
  }

  @override
  Future<void> deleteUsage({required String id}) async {
    final String trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw const LeaveRepositoryException(
        'action=deleteUsage table=leave_usages id= rule=non-empty id',
      );
    }
    final Map<String, Object?>? map = await storage.read(
      table: leaveUsagesTable,
      key: trimmedId,
    );
    if (map == null) {
      throw LeaveRepositoryException(
        'action=deleteUsage table=$leaveUsagesTable id=$trimmedId rule=missing leave usage',
      );
    }
    _parseUsageMap(key: trimmedId, map: map);
    await storage.delete(table: leaveUsagesTable, key: trimmedId);
  }
}

LeaveBalance _parseBalanceMap({
  required String key,
  required Map<String, Object?> map,
}) {
  try {
    return LeaveBalance.fromMap(map);
  } on LeaveBalanceParseException catch (error) {
    throw LeaveRepositoryException(
      'action=parseBalance table=${LocalStorageLeaveRepository.leaveBalancesTable} key=$key cause=${error.message}',
    );
  } on ArgumentError catch (error) {
    throw LeaveRepositoryException(
      'action=parseBalance table=${LocalStorageLeaveRepository.leaveBalancesTable} key=$key cause=${error.message}',
    );
  }
}

LeaveUsage _parseUsageMap({
  required String key,
  required Map<String, Object?> map,
}) {
  try {
    return LeaveUsage.fromMap(map);
  } on LeaveUsageParseException catch (error) {
    throw LeaveRepositoryException(
      'action=parseUsage table=${LocalStorageLeaveRepository.leaveUsagesTable} key=$key cause=${error.message}',
    );
  } on ArgumentError catch (error) {
    throw LeaveRepositoryException(
      'action=parseUsage table=${LocalStorageLeaveRepository.leaveUsagesTable} key=$key cause=${error.message}',
    );
  }
}

List<LeaveUsage> _sortUsages(List<LeaveUsage> usages) {
  final List<LeaveUsage> sortedUsages = List<LeaveUsage>.of(usages);
  sortedUsages.sort((LeaveUsage left, LeaveUsage right) {
    final int dateCompare = left.usedOn.compareTo(right.usedOn);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return left.id.compareTo(right.id);
  });
  return sortedUsages;
}

void _validateYear({required int year, required String action}) {
  if (year < 2000 || year > 2100) {
    throw LeaveRepositoryException(
      'action=$action year=$year rule=between 2000 and 2100',
    );
  }
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _formatYearKey(int year) {
  return year.toString().padLeft(4, '0');
}
