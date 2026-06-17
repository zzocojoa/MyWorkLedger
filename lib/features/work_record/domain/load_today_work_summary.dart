import '../../../core/models/work_record.dart';
import 'today_work_summary.dart';
import 'work_record_repository.dart';

Future<TodayWorkSummary> loadTodayWorkSummary({
  required WorkRecordRepository repository,
  required DateTime now,
}) async {
  final WorkRecord? todayRecord = await repository.findToday();
  final List<WorkRecord> currentMonthRecords = await repository.findByMonth(
    year: now.year,
    month: now.month,
  );
  return buildTodayWorkSummary(
    record: todayRecord,
    currentMonthRecords: currentMonthRecords,
    now: now,
  );
}
