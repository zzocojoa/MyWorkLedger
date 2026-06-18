import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workledger/core/models/work_record.dart';
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

  group('buildWorkLedgerPersistentNotificationContent', () {
    test('uses idle body when there is no today record', () {
      final WorkLedgerPersistentNotificationContent content =
          buildWorkLedgerPersistentNotificationContent(record: null);

      expect(content.title, workLedgerNotificationTitle);
      expect(content.body, workLedgerNotificationIdleBody);
    });

    test('shows clock-in time after clock-in action', () {
      final WorkLedgerPersistentNotificationContent content =
          buildWorkLedgerPersistentNotificationContent(
            record: _record(
              clockInAt: DateTime(2026, 6, 18, 9, 7),
              clockOutAt: null,
            ),
          );

      expect(content.body, '출근 09:07');
    });

    test('shows clock-out time after clock-out action', () {
      final WorkLedgerPersistentNotificationContent content =
          buildWorkLedgerPersistentNotificationContent(
            record: _record(
              clockInAt: DateTime(2026, 6, 18, 9, 7),
              clockOutAt: DateTime(2026, 6, 18, 18, 42),
            ),
          );

      expect(content.body, '출근 09:07 · 퇴근 18:42');
    });

    test('shows clock-out time when only clock-out exists', () {
      final WorkLedgerPersistentNotificationContent content =
          buildWorkLedgerPersistentNotificationContent(
            record: _record(
              clockInAt: null,
              clockOutAt: DateTime(2026, 6, 18, 18, 42),
            ),
          );

      expect(content.body, '퇴근 18:42');
    });
  });
}

WorkRecord _record({
  required DateTime? clockInAt,
  required DateTime? clockOutAt,
}) {
  final DateTime now = DateTime(2026, 6, 18, 21, 0);
  return WorkRecord(
    id: 'work-test',
    workDate: DateTime(2026, 6, 18),
    clockInAt: clockInAt,
    clockOutAt: clockOutAt,
    tags: <WorkRecordTag>[],
    memo: null,
    createdAt: now,
    updatedAt: now,
  );
}
