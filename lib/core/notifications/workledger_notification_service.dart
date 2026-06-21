import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

import '../models/work_record.dart';
import '../../features/work_record/data/local_storage_quick_record_settings_repository.dart';
import '../../features/work_record/data/local_storage_work_record_repository.dart';
import '../../features/work_record/domain/quick_record_settings.dart';
import '../../features/work_record/domain/quick_record_settings_repository.dart';
import '../../features/work_record/domain/work_record_repository.dart';
import '../storage/persistent_key_value_storage.dart';
import 'workledger_notification_action.dart';
import 'workledger_notification_refresh_signal.dart';

typedef WorkLedgerOpenHome = void Function();
typedef WorkLedgerOpenQuickRecord =
    void Function(WorkLedgerNotificationAction action);
typedef RefreshWorkLedgerPersistentNotification = Future<void> Function();

const int workLedgerPersistentNotificationId = 1001;
const String workLedgerNotificationChannelId = 'workledger_persistent_record';
const String workLedgerNotificationChannelName = '내근무장부 빠른 기록';
const String workLedgerNotificationChannelDescription =
    '상시 알림에서 출근과 퇴근을 빠르게 기록합니다.';
const String workLedgerNotificationImmediateActionDescription =
    '현재 시각만 쓰는 방식은 알림에서 바로 저장하고, 저장 전 선택 방식은 앱을 열어 시각을 고릅니다.';
const String workLedgerNotificationPayloadHome = 'workledger_home';
const String workLedgerNotificationTitle = '내근무장부';
const String workLedgerNotificationIdleBody = '앱을 열지 않고 출근과 퇴근을 기록할 수 있습니다.';

final class WorkLedgerNotificationException implements Exception {
  const WorkLedgerNotificationException(this.message);

  final String message;

  @override
  String toString() {
    return 'WorkLedgerNotificationException: $message';
  }
}

final class WorkLedgerNotificationSetupResult {
  const WorkLedgerNotificationSetupResult({
    required this.permissionGranted,
    required this.notificationShown,
  });

  final bool permissionGranted;
  final bool notificationShown;
}

final class WorkLedgerPersistentNotificationContent {
  const WorkLedgerPersistentNotificationContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

final class WorkLedgerNotificationService {
  WorkLedgerNotificationService({
    required this.plugin,
    required this.repository,
    required this.quickRecordSettingsRepository,
    required this.openHome,
    required this.openQuickRecord,
  });

  final FlutterLocalNotificationsPlugin plugin;
  final WorkRecordRepository repository;
  final QuickRecordSettingsRepository quickRecordSettingsRepository;
  final WorkLedgerOpenHome openHome;
  final WorkLedgerOpenQuickRecord openQuickRecord;
  bool _initialLaunchActionHandled = false;

  Future<WorkLedgerNotificationSetupResult> initialize() async {
    try {
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_workledger_notification'),
        ),
        onDidReceiveNotificationResponse: _handleForegroundResponse,
        onDidReceiveBackgroundNotificationResponse:
            workLedgerNotificationBackgroundHandler,
      );
      await _handleInitialLaunchAction();
      final bool permissionGranted = await _requestAndroidPermission();
      if (!permissionGranted) {
        return const WorkLedgerNotificationSetupResult(
          permissionGranted: false,
          notificationShown: false,
        );
      }
      await showPersistentNotification();
      return const WorkLedgerNotificationSetupResult(
        permissionGranted: true,
        notificationShown: true,
      );
    } on WorkRecordRepositoryException catch (error) {
      throw WorkLedgerNotificationException(
        'action=initialize cause=${error.toString()}',
      );
    } on QuickRecordSettingsRepositoryException catch (error) {
      throw WorkLedgerNotificationException(
        'action=initialize cause=${error.toString()}',
      );
    } on WorkLedgerNotificationActionException catch (error) {
      throw WorkLedgerNotificationException(
        'action=initialize cause=${error.toString()}',
      );
    } on PlatformException catch (error) {
      throw WorkLedgerNotificationException(
        'action=initialize plugin=flutter_local_notifications code=${error.code} message=${error.message} details=${error.details}',
      );
    }
  }

  Future<void> showPersistentNotification() async {
    await showWorkLedgerPersistentNotification(
      plugin: plugin,
      repository: repository,
      quickRecordSettingsRepository: quickRecordSettingsRepository,
    );
  }

  Future<bool> _requestAndroidPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? granted = await androidPlugin?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> _handleForegroundResponse(NotificationResponse response) async {
    final WorkLedgerNotificationAction action =
        parseWorkLedgerNotificationAction(actionId: response.actionId);
    await _handleNotificationResponseAction(
      action: action,
      actionId: response.actionId,
    );
  }

  Future<void> _handleInitialLaunchAction() async {
    if (_initialLaunchActionHandled) {
      return;
    }
    _initialLaunchActionHandled = true;
    final NotificationAppLaunchDetails? launchDetails = await plugin
        .getNotificationAppLaunchDetails();
    final NotificationResponse? response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp != true || response == null) {
      return;
    }
    final WorkLedgerNotificationAction action =
        parseWorkLedgerNotificationAction(actionId: response.actionId);
    await _handleNotificationResponseAction(
      action: action,
      actionId: response.actionId,
    );
  }

  Future<void> _handleNotificationResponseAction({
    required WorkLedgerNotificationAction action,
    required String? actionId,
  }) async {
    switch (action) {
      case WorkLedgerNotificationAction.openHome:
        openHome();
      case WorkLedgerNotificationAction.clockIn:
      case WorkLedgerNotificationAction.clockOut:
        final QuickRecordMode mode = await _resolveQuickRecordMode(
          quickRecordSettingsRepository: quickRecordSettingsRepository,
        );
        if (shouldOpenQuickRecordFromNotification(action: action, mode: mode)) {
          openQuickRecord(action);
          return;
        }
        await handleWorkLedgerNotificationAction(
          actionId: actionId,
          repository: repository,
        );
        notifyWorkLedgerNotificationActionHandled();
        await showPersistentNotification();
    }
  }
}

NotificationDetails buildWorkLedgerPersistentNotificationDetails({
  required QuickRecordMode mode,
}) {
  final bool showsUserInterface = mode == QuickRecordMode.chooseBeforeSave;
  return NotificationDetails(
    android: AndroidNotificationDetails(
      workLedgerNotificationChannelId,
      workLedgerNotificationChannelName,
      channelDescription: workLedgerNotificationChannelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.status,
      visibility: NotificationVisibility.public,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          workLedgerClockInActionId,
          '출근하기',
          showsUserInterface: showsUserInterface,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          workLedgerClockOutActionId,
          '퇴근하기',
          showsUserInterface: showsUserInterface,
          cancelNotification: false,
        ),
      ],
    ),
  );
}

Future<void> showWorkLedgerPersistentNotification({
  required FlutterLocalNotificationsPlugin plugin,
  required WorkRecordRepository repository,
  required QuickRecordSettingsRepository quickRecordSettingsRepository,
}) async {
  final WorkRecord? todayRecord = await repository.findToday();
  final QuickRecordMode mode = await _resolveQuickRecordMode(
    quickRecordSettingsRepository: quickRecordSettingsRepository,
  );
  final WorkLedgerPersistentNotificationContent content =
      buildWorkLedgerPersistentNotificationContent(record: todayRecord);
  await plugin.show(
    id: workLedgerPersistentNotificationId,
    title: content.title,
    body: content.body,
    notificationDetails: buildWorkLedgerPersistentNotificationDetails(
      mode: mode,
    ),
    payload: workLedgerNotificationPayloadHome,
  );
}

WorkLedgerPersistentNotificationContent
buildWorkLedgerPersistentNotificationContent({required WorkRecord? record}) {
  if (record == null) {
    return const WorkLedgerPersistentNotificationContent(
      title: workLedgerNotificationTitle,
      body: workLedgerNotificationIdleBody,
    );
  }

  final DateTime? clockInAt = record.clockInAt;
  final DateTime? clockOutAt = record.clockOutAt;
  if (clockInAt != null && clockOutAt != null) {
    return WorkLedgerPersistentNotificationContent(
      title: workLedgerNotificationTitle,
      body:
          '출근 ${_formatWorkLedgerNotificationClock(value: clockInAt)} · 퇴근 ${_formatWorkLedgerNotificationClock(value: clockOutAt)}',
    );
  }
  if (clockInAt != null) {
    return WorkLedgerPersistentNotificationContent(
      title: workLedgerNotificationTitle,
      body: '출근 ${_formatWorkLedgerNotificationClock(value: clockInAt)}',
    );
  }
  if (clockOutAt != null) {
    return WorkLedgerPersistentNotificationContent(
      title: workLedgerNotificationTitle,
      body: '퇴근 ${_formatWorkLedgerNotificationClock(value: clockOutAt)}',
    );
  }
  return const WorkLedgerPersistentNotificationContent(
    title: workLedgerNotificationTitle,
    body: workLedgerNotificationIdleBody,
  );
}

String _formatWorkLedgerNotificationClock({required DateTime value}) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

@pragma('vm:entry-point')
Future<void> workLedgerNotificationBackgroundHandler(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final _PersistentWorkLedgerRepositories repositories =
      await _createPersistentWorkLedgerRepositories();
  final WorkLedgerNotificationAction action = parseWorkLedgerNotificationAction(
    actionId: response.actionId,
  );
  final QuickRecordMode mode = await _resolveQuickRecordMode(
    quickRecordSettingsRepository: repositories.quickRecordSettingsRepository,
  );
  if (shouldOpenQuickRecordFromNotification(action: action, mode: mode)) {
    return;
  }
  await handleWorkLedgerNotificationAction(
    actionId: response.actionId,
    repository: repositories.workRecordRepository,
  );
  notifyWorkLedgerNotificationActionHandled();
  await showWorkLedgerPersistentNotification(
    plugin: FlutterLocalNotificationsPlugin(),
    repository: repositories.workRecordRepository,
    quickRecordSettingsRepository: repositories.quickRecordSettingsRepository,
  );
}

Future<WorkRecordRepository> createPersistentWorkRecordRepository() async {
  final _PersistentWorkLedgerRepositories repositories =
      await _createPersistentWorkLedgerRepositories();
  return repositories.workRecordRepository;
}

Future<_PersistentWorkLedgerRepositories>
_createPersistentWorkLedgerRepositories() async {
  final PersistentKeyValueStorage storage = PersistentKeyValueStorage(
    file: PersistentKeyValueStorage.fileInDirectory(
      directory: await getApplicationSupportDirectory(),
    ),
  );
  DateTime now() {
    return DateTime.now();
  }

  return _PersistentWorkLedgerRepositories(
    workRecordRepository: LocalStorageWorkRecordRepository(
      storage: storage,
      clock: now,
      idGenerator: () => 'work-${now().microsecondsSinceEpoch}',
    ),
    quickRecordSettingsRepository: LocalStorageQuickRecordSettingsRepository(
      storage: storage,
      clock: now,
    ),
  );
}

Future<QuickRecordMode> _resolveQuickRecordMode({
  required QuickRecordSettingsRepository quickRecordSettingsRepository,
}) async {
  final QuickRecordSettings? settings = await quickRecordSettingsRepository
      .findActive();
  return settings?.mode ?? QuickRecordMode.currentTimeOnly;
}

final class _PersistentWorkLedgerRepositories {
  const _PersistentWorkLedgerRepositories({
    required this.workRecordRepository,
    required this.quickRecordSettingsRepository,
  });

  final WorkRecordRepository workRecordRepository;
  final QuickRecordSettingsRepository quickRecordSettingsRepository;
}
