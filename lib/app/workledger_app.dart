import 'package:flutter/material.dart';

import '../core/theme/workledger_design_tokens.dart';
import '../features/compensation_reference/domain/compensation_reference_repository.dart';
import '../features/leave/domain/leave_repository.dart';
import '../features/pricing/domain/pricing_intent_repository.dart';
import '../features/settings/presentation/notification_settings_screen.dart';
import '../features/work_record/domain/work_record_repository.dart';
import '../features/work_record/presentation/work_record_home_screen.dart';
import '../features/work_rule/domain/work_rule_repository.dart';
import '../l10n/app_localizations.dart';

final class WorkLedgerApp extends StatelessWidget {
  const WorkLedgerApp({
    required this.workRecordRepository,
    required this.leaveRepository,
    required this.workRuleRepository,
    required this.compensationReferenceRepository,
    required this.pricingIntentRepository,
    required this.configureNotifications,
    required this.now,
    required this.navigatorKey,
    super.key,
  });

  final WorkRecordRepository workRecordRepository;
  final LeaveRepository leaveRepository;
  final WorkRuleRepository workRuleRepository;
  final CompensationReferenceRepository compensationReferenceRepository;
  final PricingIntentRepository pricingIntentRepository;
  final ConfigureWorkLedgerNotifications configureNotifications;
  final DateTime Function() now;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (BuildContext context) {
        return AppLocalizations.of(context).appTitle;
      },
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: createWorkLedgerTheme(),
      home: WorkRecordHomeScreen(
        repository: workRecordRepository,
        leaveRepository: leaveRepository,
        workRuleRepository: workRuleRepository,
        compensationReferenceRepository: compensationReferenceRepository,
        pricingIntentRepository: pricingIntentRepository,
        configureNotifications: configureNotifications,
        now: now,
      ),
    );
  }
}
