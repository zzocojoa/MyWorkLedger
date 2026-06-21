import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
import 'package:workledger/core/notifications/workledger_notification_action.dart';
import 'package:workledger/features/work_record/domain/quick_record_settings.dart';
import 'package:workledger/features/work_record/domain/work_record_repository.dart';

void main() {
  group('parseWorkLedgerNotificationAction', () {
    test('returns openHome for notification body taps', () {
      expect(
        parseWorkLedgerNotificationAction(actionId: null),
        WorkLedgerNotificationAction.openHome,
      );
      expect(
        parseWorkLedgerNotificationAction(actionId: ''),
        WorkLedgerNotificationAction.openHome,
      );
    });

    test('returns clock actions for known action ids', () {
      expect(
        parseWorkLedgerNotificationAction(actionId: workLedgerClockInActionId),
        WorkLedgerNotificationAction.clockIn,
      );
      expect(
        parseWorkLedgerNotificationAction(actionId: workLedgerClockOutActionId),
        WorkLedgerNotificationAction.clockOut,
      );
    });

    test('throws for unknown action ids', () {
      expect(
        () => parseWorkLedgerNotificationAction(actionId: 'unknown'),
        throwsA(isA<WorkLedgerNotificationActionException>()),
      );
    });
  });

  group('handleWorkLedgerNotificationAction', () {
    test(
      'does not change records when the notification body is tapped',
      () async {
        final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
          clockInError: null,
        );

        await handleWorkLedgerNotificationAction(
          actionId: null,
          repository: repository,
        );

        expect(repository.clockInCount, 0);
        expect(repository.clockOutCount, 0);
        expect(repository.clockInAtCount, 0);
        expect(repository.clockOutAtCount, 0);
      },
    );

    test('records clock in from the notification action', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        clockInError: null,
      );

      await handleWorkLedgerNotificationAction(
        actionId: workLedgerClockInActionId,
        repository: repository,
      );

      expect(repository.clockInCount, 1);
      expect(repository.clockOutCount, 0);
      expect(repository.clockInAtCount, 0);
      expect(repository.clockOutAtCount, 0);
    });

    test('records clock out from the notification action', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        clockInError: null,
      );

      await handleWorkLedgerNotificationAction(
        actionId: workLedgerClockOutActionId,
        repository: repository,
      );

      expect(repository.clockInCount, 0);
      expect(repository.clockOutCount, 1);
      expect(repository.clockInAtCount, 0);
      expect(repository.clockOutAtCount, 0);
    });

    test('keeps repository errors visible', () async {
      final _FakeWorkRecordRepository repository = _FakeWorkRecordRepository(
        clockInError: const WorkRecordRepositoryException(
          'test=notification action=clockIn',
        ),
      );

      expect(
        () => handleWorkLedgerNotificationAction(
          actionId: workLedgerClockInActionId,
          repository: repository,
        ),
        throwsA(isA<WorkRecordRepositoryException>()),
      );
    });
  });

  group('shouldOpenQuickRecordFromNotification', () {
    test('keeps clock actions in background for current-time mode', () {
      expect(
        shouldOpenQuickRecordFromNotification(
          action: WorkLedgerNotificationAction.clockIn,
          mode: QuickRecordMode.currentTimeOnly,
        ),
        isFalse,
      );
      expect(
        shouldOpenQuickRecordFromNotification(
          action: WorkLedgerNotificationAction.clockOut,
          mode: QuickRecordMode.currentTimeOnly,
        ),
        isFalse,
      );
    });

    test('opens clock actions in UI for choose-before-save mode', () {
      expect(
        shouldOpenQuickRecordFromNotification(
          action: WorkLedgerNotificationAction.clockIn,
          mode: QuickRecordMode.chooseBeforeSave,
        ),
        isTrue,
      );
      expect(
        shouldOpenQuickRecordFromNotification(
          action: WorkLedgerNotificationAction.clockOut,
          mode: QuickRecordMode.chooseBeforeSave,
        ),
        isTrue,
      );
      expect(
        shouldOpenQuickRecordFromNotification(
          action: WorkLedgerNotificationAction.openHome,
          mode: QuickRecordMode.chooseBeforeSave,
        ),
        isFalse,
      );
    });
  });
}

final class _FakeWorkRecordRepository implements WorkRecordRepository {
  _FakeWorkRecordRepository({required this.clockInError});

  final WorkRecordRepositoryException? clockInError;
  int clockInCount = 0;
  int clockOutCount = 0;
  int clockInAtCount = 0;
  int clockOutAtCount = 0;

  @override
  Future<WorkRecord?> findToday() async {
    return null;
  }

  @override
  Future<WorkRecord?> findByDate({required DateTime workDate}) async {
    return null;
  }

  @override
  Future<List<WorkRecord>> findByMonth({
    required int year,
    required int month,
  }) async {
    return <WorkRecord>[];
  }

  @override
  Future<WorkRecord> clockIn() async {
    final WorkRecordRepositoryException? error = clockInError;
    if (error != null) {
      throw error;
    }
    clockInCount += 1;
    return _record();
  }

  @override
  Future<WorkRecord> clockOut() async {
    clockOutCount += 1;
    return _record();
  }

  @override
  Future<WorkRecord> clockInAt({required DateTime clockInAt}) async {
    clockInAtCount += 1;
    throw const WorkRecordRepositoryException(
      'unexpected selected clock-in notification call',
    );
  }

  @override
  Future<WorkRecord> clockOutAt({required DateTime clockOutAt}) async {
    clockOutAtCount += 1;
    throw const WorkRecordRepositoryException(
      'unexpected selected clock-out notification call',
    );
  }

  @override
  Future<WorkRecord> updateToday({
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    return _record();
  }

  @override
  Future<WorkRecord> upsertByDate({
    required DateTime workDate,
    required DateTime? clockInAt,
    required DateTime? clockOutAt,
    required List<WorkRecordTag> tags,
    required String? memo,
  }) async {
    throw const WorkRecordRepositoryException('unexpected upsertByDate call');
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

WorkRecord _record() {
  final DateTime now = DateTime(2026, 6, 12, 9);
  return WorkRecord(
    id: 'work-test',
    workDate: DateTime(2026, 6, 12),
    clockInAt: now,
    clockOutAt: null,
    tags: <WorkRecordTag>[],
    memo: null,
    createdAt: now,
    updatedAt: now,
  );
}
