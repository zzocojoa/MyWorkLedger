import 'package:flutter/material.dart';

import '../features/leave/domain/leave_repository.dart';
import '../features/pricing/domain/pricing_intent_repository.dart';
import '../features/work_record/domain/work_record_repository.dart';
import '../features/work_record/presentation/work_record_home_screen.dart';
import '../l10n/app_localizations.dart';

final class WorkLedgerApp extends StatelessWidget {
  const WorkLedgerApp({
    required this.workRecordRepository,
    required this.leaveRepository,
    required this.pricingIntentRepository,
    required this.now,
    required this.navigatorKey,
    super.key,
  });

  final WorkRecordRepository workRecordRepository;
  final LeaveRepository leaveRepository;
  final PricingIntentRepository pricingIntentRepository;
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF181D26),
          primary: const Color(0xFF181D26),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF181D26),
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF181D26),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF181D26),
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: Color(0xFFDDDDDD)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
      home: WorkRecordHomeScreen(
        repository: workRecordRepository,
        leaveRepository: leaveRepository,
        pricingIntentRepository: pricingIntentRepository,
        now: now,
      ),
    );
  }
}
