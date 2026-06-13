import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/leave_balance.dart';
import 'package:workledger/core/models/leave_usage.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/models/work_rule.dart';
import 'package:workledger/features/leave/domain/leave_repository.dart';
import 'package:workledger/features/monthly_summary/domain/load_monthly_summary.dart';
import 'package:workledger/features/monthly_summary/domain/monthly_summary.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';
import 'package:workledger/features/work_rule/domain/work_rule_repository.dart';

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
      final _FakeWorkRuleRepository workRuleRepository =
          _FakeWorkRuleRepository(rule: _workRule(), findActiveError: null);

      final MonthlySummaryViewData viewData = await loadMonthlySummary(
        workRecordRepository: repository,
        leaveRepository: leaveRepository,
        workRuleRepository: workRuleRepository,
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
      expect(
        viewData.displayTotalWorkedDuration,
        const Duration(hours: 10, minutes: 30),
      );
      expect(viewData.leaveSummary.totalLeaveMinutes, 7200);
      expect(viewData.leaveSummary.usedLeaveMinutes, 720);
      expect(viewData.leaveSummary.remainingLeaveMinutes, 6480);
      expect(viewData.monthlyUsedLeaveMinutes, 240);
      expect(viewData.workRule, _workRule());
      expect(
        viewData.workTimeCandidateSummary.earlyWorkDuration,
        Duration.zero,
      );
      expect(
        viewData.workTimeCandidateSummary.nonWorkdayDuration,
        Duration.zero,
      );
      expect(
        viewData.workTimeCandidateSummary.overtimeDuration,
        const Duration(hours: 2, minutes: 30),
      );
      expect(viewData.compensationReferenceSummary.isVisible, isFalse);
    });

    test(
      'keeps fixed included comparison hidden from monthly summary',
      () async {
        final MonthlySummaryViewData viewData = await loadMonthlySummary(
          workRecordRepository: _FakeWorkRecordRepository(
            monthlyRecords: <WorkRecord>[
              _record(
                id: 'late-work',
                clockInAt: DateTime(2026, 6, 1, 9, 0),
                clockOutAt: DateTime(2026, 6, 1, 21, 30),
                tags: <WorkRecordTag>[],
              ),
            ],
            findByMonthError: null,
          ),
          leaveRepository: _FakeLeaveRepository(
            balance: null,
            usages: <LeaveUsage>[],
            findBalanceError: null,
            findUsagesError: null,
          ),
          workRuleRepository: _FakeWorkRuleRepository(
            rule: _workRule(),
            findActiveError: null,
          ),
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        );

        expect(
          viewData.workSummary.totalWorkedDuration,
          const Duration(hours: 12, minutes: 30),
        );
        expect(viewData.compensationReferenceSummary.isVisible, isFalse);
        expect(viewData.compensationReferenceSummary.rows, isEmpty);
      },
    );

    test(
      'separates non-workday and time candidates with break excluded total',
      () async {
        final MonthlySummaryViewData viewData = await loadMonthlySummary(
          workRecordRepository: _FakeWorkRecordRepository(
            monthlyRecords: <WorkRecord>[
              _record(
                id: 'saturday-work',
                clockInAt: DateTime(2026, 6, 13, 7, 26),
                clockOutAt: DateTime(2026, 6, 13, 21, 26),
                tags: <WorkRecordTag>[],
              ),
            ],
            findByMonthError: null,
          ),
          leaveRepository: _FakeLeaveRepository(
            balance: null,
            usages: <LeaveUsage>[],
            findBalanceError: null,
            findUsagesError: null,
          ),
          workRuleRepository: _FakeWorkRuleRepository(
            rule: _workRule(),
            findActiveError: null,
          ),
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        );

        expect(
          viewData.workSummary.totalWorkedDuration,
          const Duration(hours: 14),
        );
        expect(viewData.displayTotalWorkedDuration, const Duration(hours: 13));
        expect(
          viewData.workTimeCandidateSummary.nonWorkdayDuration,
          const Duration(hours: 13),
        );
        expect(
          viewData.workTimeCandidateSummary.earlyWorkDuration,
          const Duration(hours: 1, minutes: 34),
        );
        expect(
          viewData.workTimeCandidateSummary.overtimeDuration,
          const Duration(hours: 3, minutes: 26),
        );
        expect(
          viewData.workTimeCandidateSummary.nightWorkDuration,
          Duration.zero,
        );
      },
    );

    test(
      'combines early work and excludes delayed checkout overtime',
      () async {
        final MonthlySummaryViewData viewData = await loadMonthlySummary(
          workRecordRepository: _FakeWorkRecordRepository(
            monthlyRecords: <WorkRecord>[
              _record(
                id: 'early-and-late',
                clockInAt: DateTime(2026, 6, 1, 7, 26),
                clockOutAt: DateTime(2026, 6, 1, 21, 26),
                tags: <WorkRecordTag>[],
              ),
              _record(
                id: 'delayed-checkout',
                clockInAt: DateTime(2026, 6, 2, 9, 0),
                clockOutAt: DateTime(2026, 6, 2, 23, 30),
                tags: <WorkRecordTag>[WorkRecordTag.delayedCheckout],
              ),
            ],
            findByMonthError: null,
          ),
          leaveRepository: _FakeLeaveRepository(
            balance: null,
            usages: <LeaveUsage>[],
            findBalanceError: null,
            findUsagesError: null,
          ),
          workRuleRepository: _FakeWorkRuleRepository(
            rule: _workRule(),
            findActiveError: null,
          ),
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        );

        expect(
          viewData.workTimeCandidateSummary.earlyWorkDuration,
          const Duration(hours: 1, minutes: 34),
        );
        expect(
          viewData.workTimeCandidateSummary.overtimeDuration,
          const Duration(hours: 3, minutes: 26),
        );
        expect(
          viewData.workTimeCandidateSummary.nightWorkDuration,
          Duration.zero,
        );
      },
    );

    test(
      'returns unavailable work time candidates when work rule is missing',
      () async {
        final MonthlySummaryViewData viewData = await loadMonthlySummary(
          workRecordRepository: _FakeWorkRecordRepository(
            monthlyRecords: <WorkRecord>[
              _record(
                id: 'june-1',
                clockInAt: DateTime(2026, 6, 1, 9, 0),
                clockOutAt: DateTime(2026, 6, 1, 20, 30),
                tags: <WorkRecordTag>[],
              ),
            ],
            findByMonthError: null,
          ),
          leaveRepository: _FakeLeaveRepository(
            balance: null,
            usages: <LeaveUsage>[],
            findBalanceError: null,
            findUsagesError: null,
          ),
          workRuleRepository: _FakeWorkRuleRepository(
            rule: null,
            findActiveError: null,
          ),
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        );

        expect(viewData.workRule, isNull);
        expect(
          viewData.displayTotalWorkedDuration,
          const Duration(hours: 11, minutes: 30),
        );
        expect(viewData.workTimeCandidateSummary.isAvailable, isFalse);
        expect(viewData.workTimeCandidateSummary.reason, 'workRuleMissing');
      },
    );

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
          workRuleRepository: _FakeWorkRuleRepository(
            rule: null,
            findActiveError: null,
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
          workRuleRepository: _FakeWorkRuleRepository(
            rule: null,
            findActiveError: null,
          ),
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        ),
        throwsA(isA<LeaveRepositoryException>()),
      );
    });

    test('raises work rule repository errors without hiding them', () async {
      expect(
        () => loadMonthlySummary(
          workRecordRepository: _FakeWorkRecordRepository(
            monthlyRecords: <WorkRecord>[],
            findByMonthError: null,
          ),
          leaveRepository: _FakeLeaveRepository(
            balance: null,
            usages: <LeaveUsage>[],
            findBalanceError: null,
            findUsagesError: null,
          ),
          workRuleRepository: _FakeWorkRuleRepository(
            rule: null,
            findActiveError: const WorkRuleRepositoryException(
              'action=findActive rule=test failure',
            ),
          ),
          targetMonth: const MonthlySummaryMonth(year: 2026, month: 6),
        ),
        throwsA(isA<WorkRuleRepositoryException>()),
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

WorkRule _workRule() {
  return WorkRule(
    id: 'active-rule',
    regularStartTimeMinutes: 540,
    regularEndTimeMinutes: 1080,
    breakMinutes: 60,
    workWeekdays: <int>[1, 2, 3, 4, 5],
    createdAt: DateTime(2026, 6, 1, 9),
    updatedAt: DateTime(2026, 6, 1, 9),
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

final class _FakeWorkRuleRepository implements WorkRuleRepository {
  const _FakeWorkRuleRepository({
    required this.rule,
    required this.findActiveError,
  });

  final WorkRule? rule;
  final WorkRuleRepositoryException? findActiveError;

  @override
  Future<WorkRule?> findActive() async {
    final WorkRuleRepositoryException? error = findActiveError;
    if (error != null) {
      throw error;
    }
    return rule;
  }

  @override
  Future<WorkRule> save({
    required int regularStartTimeMinutes,
    required int regularEndTimeMinutes,
    required int breakMinutes,
    required List<int> workWeekdays,
  }) async {
    throw const WorkRuleRepositoryException('unexpected save call');
  }
}
