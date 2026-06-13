import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/features/leave/data/local_storage_leave_repository.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('LocalStorageLeaveRepository', () {
    test('saves and reads yearly leave balance', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageLeaveRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () => 'leave-balance-1',
      );

      final LeaveBalance balance = await repository.saveBalance(
        year: 2026,
        totalLeaveMinutes: 7200,
      );
      final LeaveBalance? savedBalance = await repository.findBalanceByYear(
        year: 2026,
      );

      expect(balance.id, 'leave-balance-1');
      expect(balance.year, 2026);
      expect(balance.totalLeaveMinutes, 7200);
      expect(savedBalance, balance);
    });

    test(
      'updates same year balance without creating a second balance',
      () async {
        DateTime now = DateTime.parse('2026-06-12T09:00:00');
        final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
        final LocalStorageLeaveRepository repository = _createRepository(
          storage: storage,
          clock: () => now,
          idGenerator: () => 'leave-balance-1',
        );

        final LeaveBalance firstBalance = await repository.saveBalance(
          year: 2026,
          totalLeaveMinutes: 7200,
        );
        now = DateTime.parse('2026-06-13T09:00:00');
        final LeaveBalance updatedBalance = await repository.saveBalance(
          year: 2026,
          totalLeaveMinutes: 7680,
        );

        expect(updatedBalance.id, firstBalance.id);
        expect(updatedBalance.createdAt, firstBalance.createdAt);
        expect(updatedBalance.updatedAt, DateTime.parse('2026-06-13T09:00:00'));
        expect(updatedBalance.totalLeaveMinutes, 7680);
      },
    );

    test('adds usage and reads selected year usages sorted by date', () async {
      int idValue = 0;
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageLeaveRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () {
          idValue += 1;
          return 'leave-usage-$idValue';
        },
      );

      await repository.addUsage(
        usedOn: DateTime(2025, 12, 31),
        usedLeaveMinutes: 480,
        memo: '이전 연도',
      );
      await repository.addUsage(
        usedOn: DateTime(2026, 6, 10),
        usedLeaveMinutes: 240,
        memo: '오전 반차',
      );
      await repository.addUsage(
        usedOn: DateTime(2026, 6, 3),
        usedLeaveMinutes: 480,
        memo: '개인 일정',
      );

      final List<LeaveUsage> usages = await repository.findUsagesByYear(
        year: 2026,
      );

      expect(usages.map((LeaveUsage usage) => usage.id), <String>[
        'leave-usage-3',
        'leave-usage-2',
      ]);
      expect(usages.map((LeaveUsage usage) => usage.usedOn), <DateTime>[
        DateTime(2026, 6, 3),
        DateTime(2026, 6, 10),
      ]);
    });

    test('deleteUsage removes selected leave usage only', () async {
      int idValue = 0;
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageLeaveRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () {
          idValue += 1;
          return 'leave-usage-$idValue';
        },
      );
      final LeaveUsage firstUsage = await repository.addUsage(
        usedOn: DateTime(2026, 6, 3),
        usedLeaveMinutes: 480,
        memo: '개인 일정',
      );
      final LeaveUsage secondUsage = await repository.addUsage(
        usedOn: DateTime(2026, 6, 10),
        usedLeaveMinutes: 240,
        memo: '오전 반차',
      );

      await repository.deleteUsage(id: firstUsage.id);

      final List<LeaveUsage> usages = await repository.findUsagesByYear(
        year: 2026,
      );
      expect(usages, <LeaveUsage>[secondUsage]);
      expect(
        await storage.read(
          table: LocalStorageLeaveRepository.leaveUsagesTable,
          key: firstUsage.id,
        ),
        isNull,
      );
    });

    test('deleteUsage throws when usage is missing', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      final LocalStorageLeaveRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () => 'unused-id',
      );

      await expectLater(
        repository.deleteUsage(id: 'missing-usage'),
        throwsA(
          isA<LeaveRepositoryException>().having(
            (LeaveRepositoryException error) => error.message,
            'message',
            allOf(
              contains('action=deleteUsage'),
              contains('table=leave_usages'),
              contains('id=missing-usage'),
            ),
          ),
        ),
      );
    });

    test('throws explicit error when stored balance cannot parse', () async {
      final InMemoryKeyValueStorage storage = InMemoryKeyValueStorage.empty();
      await storage.write(
        table: LocalStorageLeaveRepository.leaveBalancesTable,
        key: '2026',
        value: <String, Object?>{
          'id': 'leave-balance-1',
          'year': '2026',
          'total_leave_minutes': 7200,
          'created_at': '2026-06-12T09:00:00',
          'updated_at': '2026-06-12T09:00:00',
        },
      );
      final LocalStorageLeaveRepository repository = _createRepository(
        storage: storage,
        clock: () => DateTime.parse('2026-06-12T09:00:00'),
        idGenerator: () => 'unused-id',
      );

      expect(
        () => repository.findBalanceByYear(year: 2026),
        throwsA(isA<LeaveRepositoryException>()),
      );
    });
  });
}

LocalStorageLeaveRepository _createRepository({
  required InMemoryKeyValueStorage storage,
  required DateTime Function() clock,
  required String Function() idGenerator,
}) {
  return LocalStorageLeaveRepository(
    storage: storage,
    clock: clock,
    idGenerator: idGenerator,
  );
}
