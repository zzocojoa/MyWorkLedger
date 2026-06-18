import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';

typedef WorkLedgerNotificationRefresh = void Function();

const String _workLedgerNotificationRefreshPortName =
    'workledger_notification_refresh';

final ValueNotifier<int> workLedgerNotificationRefreshSignal =
    ValueNotifier<int>(0);
bool _isRefreshListenerActive = false;

final class WorkLedgerNotificationRefreshListener {
  WorkLedgerNotificationRefreshListener({required this.onRefresh});

  final WorkLedgerNotificationRefresh onRefresh;
  ReceivePort? _receivePort;
  StreamSubscription<dynamic>? _subscription;

  void start() {
    stop();
    workLedgerNotificationRefreshSignal.addListener(onRefresh);
    _isRefreshListenerActive = true;
    final ReceivePort receivePort = ReceivePort();
    final bool registered = IsolateNameServer.registerPortWithName(
      receivePort.sendPort,
      _workLedgerNotificationRefreshPortName,
    );
    if (!registered) {
      receivePort.close();
      workLedgerNotificationRefreshSignal.removeListener(onRefresh);
      _isRefreshListenerActive = false;
      throw const WorkLedgerNotificationRefreshException(
        'action=start name=workledger_notification_refresh rule=register port',
      );
    }
    _receivePort = receivePort;
    _subscription = receivePort.listen((dynamic message) {
      onRefresh();
    });
  }

  void stop() {
    workLedgerNotificationRefreshSignal.removeListener(onRefresh);
    _isRefreshListenerActive = false;
    _subscription?.cancel();
    _subscription = null;
    _receivePort?.close();
    _receivePort = null;
    IsolateNameServer.removePortNameMapping(
      _workLedgerNotificationRefreshPortName,
    );
  }
}

final class WorkLedgerNotificationRefreshException implements Exception {
  const WorkLedgerNotificationRefreshException(this.message);

  final String message;

  @override
  String toString() {
    return 'WorkLedgerNotificationRefreshException: $message';
  }
}

void notifyWorkLedgerNotificationActionHandled() {
  if (_isRefreshListenerActive) {
    workLedgerNotificationRefreshSignal.value += 1;
    return;
  }
  final SendPort? sendPort = IsolateNameServer.lookupPortByName(
    _workLedgerNotificationRefreshPortName,
  );
  sendPort?.send(null);
}
