import '../../../core/models/leave_balance.dart';
import '../../../core/models/leave_usage.dart';

const int leaveMinutesPerDay = 480;

final class LeaveSummaryException implements Exception {
  const LeaveSummaryException(this.message);

  final String message;

  @override
  String toString() {
    return 'LeaveSummaryException: $message';
  }
}

final class LeaveSummary {
  LeaveSummary({
    required this.year,
    required this.balance,
    required List<LeaveUsage> usages,
  }) : usages = List<LeaveUsage>.unmodifiable(usages) {
    _validateLeaveSummary(this);
  }

  final int year;
  final LeaveBalance? balance;
  final List<LeaveUsage> usages;

  int get totalLeaveMinutes {
    return balance?.totalLeaveMinutes ?? 0;
  }

  int get usedLeaveMinutes {
    return usages.fold(0, (int total, LeaveUsage usage) {
      return total + usage.usedLeaveMinutes;
    });
  }

  int get remainingLeaveMinutes {
    return totalLeaveMinutes - usedLeaveMinutes;
  }

  bool get isExceeded {
    return remainingLeaveMinutes < 0;
  }
}

LeaveSummary buildLeaveSummary({
  required int year,
  required LeaveBalance? balance,
  required List<LeaveUsage> usages,
}) {
  final List<LeaveUsage> filteredUsages = usages
      .where((LeaveUsage usage) => usage.usedOn.year == year)
      .toList(growable: false);
  return LeaveSummary(year: year, balance: balance, usages: filteredUsages);
}

void _validateLeaveSummary(LeaveSummary summary) {
  if (summary.year < 2000 || summary.year > 2100) {
    throw LeaveSummaryException(
      'model=LeaveSummary field=year value=${summary.year} rule=between 2000 and 2100',
    );
  }
  final LeaveBalance? balance = summary.balance;
  if (balance != null && balance.year != summary.year) {
    throw LeaveSummaryException(
      'model=LeaveSummary field=balance.year value=${balance.year} expected=${summary.year}',
    );
  }
  for (final LeaveUsage usage in summary.usages) {
    if (usage.usedOn.year != summary.year) {
      throw LeaveSummaryException(
        'model=LeaveSummary usageId=${usage.id} field=usedOn value=${usage.usedOn.toIso8601String()} expectedYear=${summary.year}',
      );
    }
  }
}
