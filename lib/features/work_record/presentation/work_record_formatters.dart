import '../../../core/models/work_record.dart';

String formatTodayLabel({required DateTime now}) {
  return '오늘 · ${now.month}월 ${now.day}일 ${formatKoreanWeekday(value: now)}';
}

String formatKoreanWeekday({required DateTime value}) {
  return switch (value.weekday) {
    DateTime.monday => '월요일',
    DateTime.tuesday => '화요일',
    DateTime.wednesday => '수요일',
    DateTime.thursday => '목요일',
    DateTime.friday => '금요일',
    DateTime.saturday => '토요일',
    DateTime.sunday => '일요일',
    _ => throw ArgumentError.value(value.weekday, 'weekday', 'must be 1-7'),
  };
}

String formatClockTime({required DateTime value}) {
  final String hour = value.hour.toString().padLeft(2, '0');
  final String minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatNullableClockTime({required DateTime? value}) {
  if (value == null) {
    return '';
  }
  return formatClockTime(value: value);
}

String formatDateOnly(DateTime value) {
  final String year = value.year.toString().padLeft(4, '0');
  final String month = value.month.toString().padLeft(2, '0');
  final String day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatDurationForKorean({required Duration duration}) {
  if (duration.isNegative) {
    throw ArgumentError.value(duration, 'duration', 'must not be negative');
  }

  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  if (hours == 0) {
    return '$minutes분';
  }
  if (minutes == 0) {
    return '$hours시간';
  }
  return '$hours시간 $minutes분';
}

String formatWorkRecordTags({required List<WorkRecordTag> tags}) {
  return tags.map(formatWorkRecordTag).join(' · ');
}

String formatWorkRecordTag(WorkRecordTag tag) {
  return switch (tag) {
    WorkRecordTag.overtime => '야근',
    WorkRecordTag.delayedCheckout => '퇴근 지연',
    WorkRecordTag.holidayWork => '휴일근무',
  };
}
