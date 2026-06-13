// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'WorkLedger';

  @override
  String get appKoreanName => 'WorkLedger';

  @override
  String get homeThisMonth => 'This month';

  @override
  String get homeTotalWork => 'Total work';

  @override
  String get homeRemainingLeave => 'Remaining leave';

  @override
  String get homePreparing => 'Preparing';

  @override
  String get homeMonthlySummary => 'Monthly summary';

  @override
  String get homeLeaveManagement => 'Leave';
}
