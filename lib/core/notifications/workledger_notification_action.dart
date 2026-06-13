import '../../features/work_record/domain/work_record_repository.dart';

const String workLedgerClockInActionId = 'workledger_clock_in';
const String workLedgerClockOutActionId = 'workledger_clock_out';

enum WorkLedgerNotificationAction { openHome, clockIn, clockOut }

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
