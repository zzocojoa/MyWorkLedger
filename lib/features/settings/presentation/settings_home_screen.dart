import 'package:flutter/material.dart';

import '../../compensation_reference/domain/compensation_reference_repository.dart';
import '../../leave/domain/leave_repository.dart';
import '../../leave/presentation/leave_balance_settings_screen.dart';
import '../../work_rule/domain/work_rule_repository.dart';
import 'notification_settings_screen.dart';
import 'work_settings_screen.dart';

final class SettingsHomeScreen extends StatelessWidget {
  const SettingsHomeScreen({
    required this.workRuleRepository,
    required this.compensationReferenceRepository,
    required this.leaveRepository,
    required this.configureNotifications,
    required this.now,
    super.key,
  });

  final WorkRuleRepository workRuleRepository;
  final CompensationReferenceRepository compensationReferenceRepository;
  final LeaveRepository leaveRepository;
  final ConfigureWorkLedgerNotifications configureNotifications;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            _SettingsRow(
              icon: Icons.schedule_outlined,
              title: '근무 설정',
              subtitle: '정시, 연장/야간, 포함 시간 비교',
              onTap: () => _openWorkSettings(context: context),
            ),
            _SettingsDivider(),
            _SettingsRow(
              icon: Icons.event_available_outlined,
              title: '총 연차',
              subtitle: '올해 총 연차 직접 입력',
              onTap: () => _openLeaveBalanceSettings(context: context),
            ),
            _SettingsDivider(),
            _SettingsRow(
              icon: Icons.notifications_active_outlined,
              title: '알림',
              subtitle: '상시 알림 권한과 빠른 기록',
              onTap: () => _openNotificationSettings(context: context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWorkSettings({required BuildContext context}) async {
    final DateTime currentMonth = now();
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => WorkSettingsScreen(
          workRuleRepository: workRuleRepository,
          compensationReferenceRepository: compensationReferenceRepository,
          targetMonth: DateTime(currentMonth.year, currentMonth.month),
        ),
      ),
    );
  }

  Future<void> _openLeaveBalanceSettings({
    required BuildContext context,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            LeaveBalanceSettingsScreen(repository: leaveRepository, now: now),
      ),
    );
  }

  Future<void> _openNotificationSettings({
    required BuildContext context,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => NotificationSettingsScreen(
          configureNotifications: configureNotifications,
        ),
      ),
    );
  }
}

final class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: <Widget>[
            Icon(icon, color: const Color(0xFF181D26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF181D26),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6F737A),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: Color(0xFF8B8F96)),
          ],
        ),
      ),
    );
  }
}

final class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFEAEAEA));
  }
}
