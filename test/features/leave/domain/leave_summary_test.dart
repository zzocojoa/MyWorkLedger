import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/features/leave/data/local_storage_leave_repository.dart';
import 'package:workledger/features/leave/domain/add_leave_usage.dart';
import 'package:workledger/features/leave/domain/leave_summary.dart';
import 'package:workledger/features/leave/domain/load_leave_summary.dart';
import 'package:workledger/features/leave/domain/save_total_leave.dart';

import '../../../core/storage/in_memory_key_value_storage.dart';

void main() {
  group('leave summary use cases', () {
    test('calculates remaining leave from balance and usages', () async {
      int idValue = 0;
      final LocalStorageLeaveRepository repository = _createRepository(
        idGenerator: () {
          idValue += 1;
          return 'leave-$idValue';
        },
      );

      await saveTotalLeave(
        repository: repository,
        year: 2026,
        totalLeaveMinutes: 7200,
      );
      await addLeaveUsage(
        repository: repository,
        usedOn: DateTime(2026, 6, 3),
        usedLeaveMinutes: 480,
        memo: '개인 일정',
      );
      await addLeaveUsage(
        repository: repository,
        usedOn: DateTime(2026, 6, 10),
        usedLeaveMinutes: 240,
        memo: '오전 반차',
      );

      final LeaveSummary summary = await loadLeaveSummary(
        repository: repository,
        year: 2026,
      );

      expect(summary.totalLeaveMinutes, 7200);
      expect(summary.usedLeaveMinutes, 720);
      expect(summary.remainingLeaveMinutes, 6480);
      expect(summary.isExceeded, isFalse);
    });

    test('marks exceeded state without blocking usage save', () async {
      int idValue = 0;
      final LocalStorageLeaveRepository repository = _createRepository(
        idGenerator: () {
          idValue += 1;
          return 'leave-$idValue';
        },
      );

      await saveTotalLeave(
        repository: repository,
        year: 2026,
        totalLeaveMinutes: 480,
      );
      await addLeaveUsage(
        repository: repository,
        usedOn: DateTime(2026, 6, 3),
        usedLeaveMinutes: 960,
        memo: '초과 사용',
      );

      final LeaveSummary summary = await loadLeaveSummary(
        repository: repository,
        year: 2026,
      );

      expect(summary.remainingLeaveMinutes, -480);
      expect(summary.isExceeded, isTrue);
    });

    test('keeps 30-minute validation in total leave and usage use cases', () {
      final LocalStorageLeaveRepository repository = _createRepository(
        idGenerator: () => 'leave-1',
      );

      expect(
        () => saveTotalLeave(
          repository: repository,
          year: 2026,
          totalLeaveMinutes: 7210,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => addLeaveUsage(
          repository: repository,
          usedOn: DateTime(2026, 6, 3),
          usedLeaveMinutes: 10,
          memo: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('filters usages by selected year when building summary', () {
      final LeaveSummary summary = buildLeaveSummary(
        year: 2026,
        balance: null,
        usages: <LeaveUsage>[
          _usage(
            id: 'previous-year',
            usedOn: DateTime(2025, 12, 31),
            usedLeaveMinutes: 480,
          ),
          _usage(
            id: 'current-year',
            usedOn: DateTime(2026, 1, 2),
            usedLeaveMinutes: 240,
          ),
        ],
      );

      expect(summary.usedLeaveMinutes, 240);
      expect(summary.usages.map((LeaveUsage usage) => usage.id), <String>[
        'current-year',
      ]);
    });
  });
}

LocalStorageLeaveRepository _createRepository({
  required String Function() idGenerator,
}) {
  return LocalStorageLeaveRepository(
    storage: InMemoryKeyValueStorage.empty(),
    clock: () => DateTime.parse('2026-06-12T09:00:00'),
    idGenerator: idGenerator,
  );
}

LeaveUsage _usage({
  required String id,
  required DateTime usedOn,
  required int usedLeaveMinutes,
}) {
  return LeaveUsage(
    id: id,
    usedOn: usedOn,
    usedLeaveMinutes: usedLeaveMinutes,
    memo: null,
    createdAt: DateTime.parse('2026-06-12T09:00:00'),
    updatedAt: DateTime.parse('2026-06-12T09:00:00'),
  );
}
