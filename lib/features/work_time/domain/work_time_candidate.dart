enum WorkTimeCandidateStatus { unavailable, available }

final class WorkTimeCandidateSummary {
  const WorkTimeCandidateSummary({
    required this.status,
    required this.nonWorkdayDuration,
    required this.earlyWorkDuration,
    required this.overtimeDuration,
    required this.nightWorkDuration,
    required this.reason,
  });

  final WorkTimeCandidateStatus status;
  final Duration nonWorkdayDuration;
  final Duration earlyWorkDuration;
  final Duration overtimeDuration;
  final Duration nightWorkDuration;
  final String? reason;

  bool get isAvailable {
    return status == WorkTimeCandidateStatus.available;
  }

  bool get hasActiveTags {
    return activeTagCount > 0;
  }

  int get activeTagCount {
    final List<Duration> durations = <Duration>[
      nonWorkdayDuration,
      earlyWorkDuration,
      overtimeDuration,
      nightWorkDuration,
    ];
    return durations
        .where((Duration duration) => duration > Duration.zero)
        .length;
  }
}
