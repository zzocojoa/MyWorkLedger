// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'WorkLedger';

  @override
  String get appKoreanName => '내근무장부';

  @override
  String get homeThisMonth => '이번 달';

  @override
  String get homeTotalWork => '총 근무';

  @override
  String get homeRemainingLeave => '남은 연차';

  @override
  String get homePreparing => '준비 중';

  @override
  String get homeMonthlySummary => '월간 요약';

  @override
  String get homeLeaveManagement => '연차 관리';

  @override
  String get monthlySummaryCompensationReferenceTitle => '포괄임금 시간 대비';

  @override
  String get monthlySummaryCompensationReferenceStartLabel => '포괄임금 포함 시간';

  @override
  String get monthlySummaryCompensationActualLabel => '실제 기록';

  @override
  String get monthlySummaryCompensationIncludedDurationLabel => '포괄임금 시간';

  @override
  String get monthlySummaryCompensationExcessReferenceLabel => '초과 참고';
}
