import 'package:flutter/foundation.dart';

import '../../features/work_record/domain/work_record_repository.dart';

const String workLedgerClockInActionId = 'workledger_clock_in';
const String workLedgerClockOutActionId = 'workledger_clock_out';

enum WorkLedgerNotificationAction { openHome, clockIn, clockOut }

final class WorkLedgerNotificationActionController extends ChangeNotifier {
  WorkLedgerNotificationAction? _pendingAction;

  WorkLedgerNotificationAction? takePendingAction() {
    final WorkLedgerNotificationAction? action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  void request({required WorkLedgerNotificationAction action}) {
    _pendingAction = action;
    notifyListeners();
  }
}

final class WorkLedgerNotificationActionException implements Exception {
  const WorkLedgerNotificationActionException(this.message);

  final String message;

  @override
  String toString() {
    return 'WorkLedgerNotificationActionException: $message';
  }
}

WorkLedgerNotificationAction parseWorkLedgerNotificationAction({
  required String? actionId,
}) {
  if (actionId == null || actionId.isEmpty) {
    return WorkLedgerNotificationAction.openHome;
  }
  return switch (actionId) {
    workLedgerClockInActionId => WorkLedgerNotificationAction.clockIn,
    workLedgerClockOutActionId => WorkLedgerNotificationAction.clockOut,
    _ => throw WorkLedgerNotificationActionException(
      'action=parse actionId=$actionId rule=known notification action',
    ),
  };
}

bool shouldOpenQuickRecordFromNotification({
  required WorkLedgerNotificationAction action,
}) {
  return switch (action) {
    WorkLedgerNotificationAction.openHome => false,
    WorkLedgerNotificationAction.clockIn => false,
    WorkLedgerNotificationAction.clockOut => false,
  };
}

Future<void> handleWorkLedgerNotificationAction({
  required String? actionId,
  required WorkRecordRepository repository,
}) async {
  final WorkLedgerNotificationAction action = parseWorkLedgerNotificationAction(
    actionId: actionId,
  );
  switch (action) {
    case WorkLedgerNotificationAction.openHome:
      return;
    case WorkLedgerNotificationAction.clockIn:
      await repository.clockIn();
    case WorkLedgerNotificationAction.clockOut:
      await repository.clockOut();
  }
}
