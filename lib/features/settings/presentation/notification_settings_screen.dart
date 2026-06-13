import 'package:flutter/material.dart';

import '../../../core/notifications/workledger_notification_service.dart';

typedef ConfigureWorkLedgerNotifications =
    Future<WorkLedgerNotificationSetupResult> Function();

final class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    required this.configureNotifications,
    super.key,
  });

  final ConfigureWorkLedgerNotifications configureNotifications;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

final class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  String? _statusMessage;
  bool _isSaving = false;

  Future<void> _configureNotifications() async {
    setState(() {
      _statusMessage = null;
      _isSaving = true;
    });
    try {
      final WorkLedgerNotificationSetupResult result = await widget
          .configureNotifications();
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = _formatNotificationSetupResult(result: result);
        _isSaving = false;
      });
    } on WorkLedgerNotificationException catch (error) {
      _showError('알림을 설정할 수 없습니다. ${error.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = message;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDDDDDD)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        '상시 알림',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF181D26),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '알림에서 출근하기와 퇴근하기를 바로 실행합니다.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF41454D),
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _isSaving ? null : _configureNotifications,
                        child: Text(_isSaving ? '설정 중' : '권한 요청 및 알림 다시 표시'),
                      ),
                    ],
                  ),
                ),
              ),
              if (_statusMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  _statusMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF181D26),
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _formatNotificationSetupResult({
  required WorkLedgerNotificationSetupResult result,
}) {
  if (!result.permissionGranted) {
    return '알림 권한이 허용되지 않았습니다. 홈 기록은 계속 사용할 수 있습니다.';
  }
  if (!result.notificationShown) {
    return '알림 권한은 허용됐지만 상시 알림을 표시하지 못했습니다.';
  }
  return '상시 알림이 표시되었습니다.';
}
