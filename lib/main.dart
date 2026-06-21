import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import 'app/workledger_app.dart';
import 'core/notifications/workledger_notification_action.dart';
import 'core/notifications/workledger_notification_service.dart';
import 'core/storage/persistent_key_value_storage.dart';
import 'features/compensation_reference/data/local_storage_compensation_reference_repository.dart';
import 'features/leave/data/local_storage_leave_repository.dart';
import 'features/pricing/data/local_storage_pricing_intent_repository.dart';
import 'features/work_record/data/local_storage_quick_record_settings_repository.dart';
import 'features/work_record/data/local_storage_work_record_repository.dart';
import 'features/work_rule/data/local_storage_work_rule_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final PersistentKeyValueStorage storage = PersistentKeyValueStorage(
    file: PersistentKeyValueStorage.fileInDirectory(
      directory: await getApplicationSupportDirectory(),
    ),
  );
  DateTime now() {
    return DateTime.now();
  }

  final LocalStorageWorkRecordRepository repository =
      LocalStorageWorkRecordRepository(
        storage: storage,
        clock: now,
        idGenerator: () => 'work-${now().microsecondsSinceEpoch}',
      );
  final LocalStorageLeaveRepository leaveRepository =
      LocalStorageLeaveRepository(
        storage: storage,
        clock: now,
        idGenerator: () => 'leave-${now().microsecondsSinceEpoch}',
      );
  final LocalStoragePricingIntentRepository pricingIntentRepository =
      LocalStoragePricingIntentRepository(
        storage: storage,
        clock: now,
        idGenerator: () => 'pricing-${now().microsecondsSinceEpoch}',
      );
  final LocalStorageQuickRecordSettingsRepository
  quickRecordSettingsRepository = LocalStorageQuickRecordSettingsRepository(
    storage: storage,
    clock: now,
  );
  final LocalStorageWorkRuleRepository workRuleRepository =
      LocalStorageWorkRuleRepository(
        storage: storage,
        clock: now,
        idGenerator: () => 'work-rule-${now().microsecondsSinceEpoch}',
      );
  final LocalStorageCompensationReferenceRepository
  compensationReferenceRepository = LocalStorageCompensationReferenceRepository(
    storage: storage,
    clock: now,
    idGenerator: () => 'compensation-reference-${now().microsecondsSinceEpoch}',
  );
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final WorkLedgerNotificationActionController notificationActionController =
      WorkLedgerNotificationActionController();
  final WorkLedgerNotificationService notificationService =
      WorkLedgerNotificationService(
        plugin: FlutterLocalNotificationsPlugin(),
        repository: repository,
        quickRecordSettingsRepository: quickRecordSettingsRepository,
        openHome: () {
          navigatorKey.currentState?.popUntil((Route<dynamic> route) {
            return route.isFirst;
          });
        },
        openQuickRecord: (WorkLedgerNotificationAction action) {
          navigatorKey.currentState?.popUntil((Route<dynamic> route) {
            return route.isFirst;
          });
          notificationActionController.request(action: action);
        },
      );
  await notificationService.initialize();

  runApp(
    WorkLedgerApp(
      workRecordRepository: repository,
      quickRecordSettingsRepository: quickRecordSettingsRepository,
      leaveRepository: leaveRepository,
      workRuleRepository: workRuleRepository,
      compensationReferenceRepository: compensationReferenceRepository,
      pricingIntentRepository: pricingIntentRepository,
      configureNotifications: notificationService.initialize,
      notificationActionController: notificationActionController,
      now: now,
      navigatorKey: navigatorKey,
    ),
  );
}
