enum WorkTimeCandidateStatus { unavailable, available }

final class WorkTimeCandidateSummary {
  const WorkTimeCandidateSummary({
    required this.status,
    required this.overtimeDuration,
    required this.nightWorkDuration,
    required this.reason,
  });

  final WorkTimeCandidateStatus status;
  final Duration overtimeDuration;
  final Duration nightWorkDuration;
  final String? reason;

  bool get isAvailable {
    return status == WorkTimeCandidateStatus.available;
  }
}
