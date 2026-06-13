import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';
import 'package:workledger/features/monthly_summary/domain/load_monthly_summary.dart';
import 'package:workledger/features/monthly_summary/domain/monthly_summary.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';

void main() {
  group('loadMonthlySummary', () {
    test('loads target month records and calculates summary', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        monthlyRecords: <WorkRecord>[
          _record(
            id: 'june-1',
            clockInAt: DateTime(2026, 6, 1, 9, 0),
            clockOutAt: DateTime(2026, 6, 1, 20, 30),
            tags: <WorkRecordTag>[WorkRecordTag.overtime],
          ),
        ],
        findByMonthError: null,
      );
      final _FakeLeaveRepository leaveRepository = _FakeLeaveRepository(
        balance: _leaveBalance(totalLeaveMinutes: 7200),
        usages: <LeaveUsage>[
          _leaveUsage(
            id: 'leave-previous-month',
            usedOn: DateTime(2026, 5, 31),
            usedLeaveMinutes: 480,
          ),
          _leaveUsage(
            id: 'leave-current-month',
            usedOn: DateTime(2026, 6, 10),
            usedLeaveMinutes: 240,
          ),
        ],
        findBalanceError: null,
        findUsagesError: null,
      );

      final MonthlySummaryViewData viewData = await loadMonthlySummary(
        workRecordRepository: repository,
        leaveRepository: leaveRepository,
        targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
      );

      expect(repository.requestedYear, 2026);
      expect(repository.requestedMonth, 6);
      expect(leaveRepository.requestedBalanceYear, 2026);
      expect(leaveRepository.requestedUsagesYear, 2026);
      expect(viewData.workSummary.completedWorkDayCount, 1);
      expect(
        viewData.workSummary.totalWorkedDuration,
        const Duration(hours: 11, minutes: 30),
      );
      expect(viewData.leaveSummary.totalLeaveMinutes, 7200);
      expect(viewData.leaveSummary.usedLeaveMinutes, 720);
      expect(viewData.leaveSummary.remainingLeaveMinutes, 6480);
      expect(viewData.monthlyUsedLeaveMinutes, 240);
    });

    test('raises repository errors without hiding them', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        monthlyRecords: <WorkRecord>[],
        findByMonthError: const WorkRecordRepositoryException(
          'action=findByMonth year=2026 month=6 rule=test failure',
        ),
      );

      expect(
        () => loadMonthlySummary(
          workRecordRepository: repository,
          leaveRepository: _FakeLeaveRepository(
            balance: null,
            usages: <LeaveUsage>[],
            findBalanceError: null,
            findUsagesError: null,
          ),
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        ),
        throwsA(isA<WorkRecordRepositoryException>()),
      );
    });

    test('raises leave repository errors without hiding them', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        monthlyRecords: <WorkRecord>[],
        findByMonthError: null,
      );
      final _FakeLeaveRepository leaveRepository = _FakeLeaveRepository(
        balance: null,
        usages: <LeaveUsage>[],
        findBalanceError: const LeaveRepositoryException(
          'action=findBalanceByYear year=2026 rule=test failure',
        ),
        findUsagesError: null,
      );

      expect(
        () => loadMonthlySummary(
          workRecordRepository: repository,
          leaveRepository: leaveRepository,
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        ),
        throwsA(isA<LeaveRepositoryException>()),
      );
    });
  });
}

WorkRecord _record({
  required String id,
  required DateTime clockInAt,
  required DateTime clockOutAt,
  required List<WorkRecordTag> tags,
}) {
  return WorkRecord(
    id: id,
    workDate: DateTime(clockInAt.year, clockInAt.month, clockInAt.day),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: tags,
    memo: null,
    createdAt: clockInAt,
    updatedAt: clockOutAt,
  );
}

LeaveBalance _leaveBalance({required int totalLeaveMinutes}) {
  return LeaveBalance(
    id: 'leave-balance-2026',
    year: 2026,
    totalLeaveMinutes: totalLeaveMinutes,
    createdAt: DateTime(2026, 1, 1, 9),
    updatedAt: DateTime(2026, 1, 1, 9),
  );
}

LeaveUsage _leaveUsage({
  required String id,
  required DateTime usedOn,
  required int usedLeaveMinutes,
}) {
  return LeaveUsage(
    id: id,
    usedOn: usedOn,
    usedLeaveMinutes: usedLeaveMinutes,
    memo: null,
    createdAt: DateTime(2026, 1, 1, 9),
    updatedAt: DateTime(2026, 1, 1, 9),
  );
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  _FakeWorkRecordRepository({
    required this.monthlyRecords,
    required this.findByMonthError,
  });

  final List<WorkRecord> monthlyRecords;
  final WorkRecordRepositoryException? findByMonthError;
  int? requestedYear;
  int? requestedMonth;

  @override
  Future<WorkRecord?> findToday() async {
    throw const WorkRecordRepositoryException('unexpected findToday call');
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    requestedYear = year;
    requestedMonth = month;
    final WorkRecordRepositoryException? error = findByMonthError;
    if (error != null) {
      throw error;
    }
    return monthlyRecords;
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
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException('unexpected updateToday call');
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

final class _FakeLeaveRepository implements LeaveRepository {
  _FakeLeaveRepository({
    required this.balance,
    required this.usages,
    required this.findBalanceError,
    required this.findUsagesError,
  });

  final LeaveBalance? balance;
  final List<LeaveUsage> usages;
  final LeaveRepositoryException? findBalanceError;
  final LeaveRepositoryException? findUsagesError;
  int? requestedBalanceYear;
  int? requestedUsagesYear;

  @override
  Future<LeaveBalance?> findBalanceByYear({required int year}) async {
    requestedBalanceYear = year;
    final LeaveRepositoryException? error = findBalanceError;
    if (error != null) {
      throw error;
    }
    return balance;
  }

  @override
  Future<LeaveBalance> saveBalance({
    required int year,
    required int totalLeaveMinutes,
  }) async {
    throw const LeaveRepositoryException('unexpected saveBalance call');
  }

  @override
  Future<List<LeaveUsage>> findUsagesByYear({required int year}) async {
    requestedUsagesYear = year;
    final LeaveRepositoryException? error = findUsagesError;
    if (error != null) {
      throw error;
    }
    return usages;
  }

  @override
  Future<LeaveUsage> addUsage({
    required DateTime usedOn,
    required int usedLeaveMinutes,
    required String? memo,
  }) async {
    throw const LeaveRepositoryException('unexpected addUsage call');
  }

  @override
  Future<void> deleteUsage({required String id}) async {
    throw const LeaveRepositoryException('unexpected deleteUsage call');
  }
}
