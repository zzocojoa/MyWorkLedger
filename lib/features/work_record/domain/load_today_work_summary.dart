import 'today_work_summary.dart';
import 'work_record_repository.dart';

Future<TodayWorkSummary> loadTodayWorkSummary({
  required WorkRecordRepository repository,
  required DateTime now,
}) async {
  return buildTodayWorkSummary(record: await repository.findToday(), now: now);
}
