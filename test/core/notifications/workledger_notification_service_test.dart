import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/notifications/workledger_notification_action.dart';
import 'package:workledger/core/notifications/workledger_notification_service.dart';

void main() {
  test('builds persistent notification details with clock actions', () {
    final NotificationDetails details =
        buildWorkLedgerPersistentNotificationDetails();
    final AndroidNotificationDetails android = details.android!;

    expect(android.channelId, workLedgerNotificationChannelId);
    expect(android.channelName, workLedgerNotificationChannelName);
    expect(
      android.channelDescription,
      workLedgerNotificationChannelDescription,
    );
    expect(android.ongoing, isTrue);
    expect(android.autoCancel, isFalse);
    expect(android.actions, hasLength(2));
    expect(android.actions![0].id, workLedgerClockInActionId);
    expect(android.actions![0].title, '출근하기');
    expect(android.actions![0].showsUserInterface, isFalse);
    expect(android.actions![0].cancelNotification, isFalse);
    expect(android.actions![1].id, workLedgerClockOutActionId);
    expect(android.actions![1].title, '퇴근하기');
    expect(android.actions![1].showsUserInterface, isFalse);
    expect(android.actions![1].cancelNotification, isFalse);
  });
}
