import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/features/work_record/domain/load_today_work_summary.dart';
import 'package:workledger/features/work_record/domain/today_work_status.dart';
import 'package:workledger/features/work_record/domain/today_work_summary.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';

void main() {
  group('buildTodayWorkSummary', () {
    test('returns before clock-in state when there is no record', () {
      final TodayWorkSummary summary = buildTodayWorkSummary(
        record: null,
        now: DateTime.parse('2026-06-12T09:03:00'),
      );

      expect(summary.status, TodayWorkStatus.beforeClockIn);
      expect(summary.statusText, '아직 출근 전');
      expect(summary.primaryAction, TodayWorkPrimaryAction.clockIn);
      expect(summary.primaryButtonLabel, '출근하기');
      expect(summary.secondaryAction, isNull);
      expect(summary.elapsedDuration, isNull);
      expect(summary.workedDuration, isNull);
    });

    test('returns before clock-in state when an empty record exists', () {
      final WorkRecord record = _createRecord(
        clockInAt: null,
        clockOutAt: null,
      );

      final TodayWorkSummary summary = buildTodayWorkSummary(
        record: record,
        now: DateTime.parse('2026-06-12T09:03:00'),
      );

      expect(summary.status, TodayWorkStatus.beforeClockIn);
      expect(summary.primaryButtonLabel, '출근하기');
      expect(summary.record, record);
    });

    test(
      'returns working state and elapsed duration when only clock-in exists',
      () {
        final WorkRecord record = _createRecord(
          clockInAt: DateTime.parse('2026-06-12T09:03:00'),
          clockOutAt: null,
        );

        final TodayWorkSummary summary = buildTodayWorkSummary(
          record: record,
          now: DateTime.parse('2026-06-12T12:45:00'),
        );

        expect(summary.status, TodayWorkStatus.working);
        expect(summary.statusText, '근무 중');
        expect(summary.primaryAction, TodayWorkPrimaryAction.clockOut);
        expect(summary.primaryButtonLabel, '퇴근하기');
        expect(summary.elapsedDuration, const Duration(hours: 3, minutes: 42));
        expect(summary.workedDuration, isNull);
      },
    );

    test(
      'returns after clock-out state and worked duration when both times exist',
      () {
        final WorkRecord record = _createRecord(
          clockInAt: DateTime.parse('2026-06-12T09:03:00'),
          clockOutAt: DateTime.parse('2026-06-12T18:42:00'),
        );

        final TodayWorkSummary summary = buildTodayWorkSummary(
          record: record,
          now: DateTime.parse('2026-06-12T19:00:00'),
        );

        expect(summary.status, TodayWorkStatus.afterClockOut);
        expect(summary.statusText, '오늘 기록 완료');
        expect(summary.primaryAction, TodayWorkPrimaryAction.editTodayRecord);
        expect(summary.primaryButtonLabel, '오늘 기록 수정');
        expect(
          summary.secondaryAction,
          TodayWorkSecondaryAction.viewMonthlySummary,
        );
        expect(summary.secondaryButtonLabel, '월간 요약 보기');
        expect(summary.elapsedDuration, isNull);
        expect(summary.workedDuration, const Duration(hours: 9, minutes: 39));
      },
    );

    test('throws when clock-out exists without clock-in', () {
      final WorkRecord record = _createRecord(
        clockInAt: null,
        clockOutAt: DateTime.parse('2026-06-12T18:42:00'),
      );

      expect(
        () => buildTodayWorkSummary(
          record: record,
          now: DateTime.parse('2026-06-12T19:00:00'),
        ),
        throwsA(isA<TodayWorkSummaryException>()),
      );
    });

    test(
      'throws when current time is before clock-in during working state',
      () {
        final WorkRecord record = _createRecord(
          clockInAt: DateTime.parse('2026-06-12T10:00:00'),
          clockOutAt: null,
        );

        expect(
          () => buildTodayWorkSummary(
            record: record,
            now: DateTime.parse('2026-06-12T09:00:00'),
          ),
          throwsA(isA<TodayWorkSummaryException>()),
        );
      },
    );
  });

  group('duration calculators', () {
    test('calculateWorkedDuration uses Duration instead of raw minutes', () {
      final Duration duration = calculateWorkedDuration(
        clockInAt: DateTime.parse('2026-06-12T09:03:00'),
        clockOutAt: DateTime.parse('2026-06-12T18:42:00'),
      );

      expect(duration, const Duration(hours: 9, minutes: 39));
    });

    test(
      'calculateWorkedDuration throws when clock-out is before clock-in',
      () {
        expect(
          () => calculateWorkedDuration(
            clockInAt: DateTime.parse('2026-06-12T18:42:00'),
            clockOutAt: DateTime.parse('2026-06-12T09:03:00'),
          ),
          throwsA(isA<TodayWorkSummaryException>()),
        );
      },
    );
  });

  group('loadTodayWorkSummary', () {
    test(
      'loads today record from repository and builds summary with injected time',
      () async {
        final WorkRecord record = _createRecord(
          clockInAt: DateTime.parse('2026-06-12T09:03:00'),
          clockOutAt: null,
        );
        final FakeWorkRecordRepository repository = FakeWorkRecordRepository(
          record: record,
        );

        final TodayWorkSummary summary = await loadTodayWorkSummary(
          repository: repository,
          now: DateTime.parse('2026-06-12T12:45:00'),
        );

        expect(summary.status, TodayWorkStatus.working);
        expect(summary.elapsedDuration, const Duration(hours: 3, minutes: 42));
        expect(repository.findTodayCallCount, 1);
      },
    );

    test('does not hide repository errors', () async {
      final ThrowingWorkRecordRepository repository =
          ThrowingWorkRecordRepository();

      expect(
        () => loadTodayWorkSummary(
          repository: repository,
          now: DateTime.parse('2026-06-12T12:45:00'),
        ),
        throwsA(isA<WorkRecordRepositoryException>()),
      );
    });
  });
}

WorkRecord _createRecord({
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
}) {
  return WorkRecord(
    id: 'work-1',
    workDate: DateTime(2026, 6, 12),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: <WorkRecordTag>[],
    memo: null,
    createdAt: DateTime.parse('2026-06-12T09:00:00'),
    updatedAt: DateTime.parse('2026-06-12T09:00:00'),
  );
}

final class FakeWorkRecordRepository implements WorkRecordRepository {
  FakeWorkRecordRepository({required this.record});

  final WorkRecord? record;
  int findTodayCallCount = 0;

  @override
  Future<WorkRecord?> findToday() async {
    findTodayCallCount += 1;
    return record;
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    throw const WorkRecordRepositoryException('unexpected findByMonth call');
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

final class ThrowingWorkRecordRepository implements WorkRecordRepository {
  @override
  Future<WorkRecord?> findToday() async {
    throw const WorkRecordRepositoryException('read failed');
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    throw const WorkRecordRepositoryException('unexpected findByMonth call');
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
