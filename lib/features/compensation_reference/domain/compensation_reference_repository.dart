import '../../../core/models/compensation_reference_setting.dart';

final class CompensationReferenceRepositoryException implements Exception {
  const CompensationReferenceRepositoryException(this.message);

  final String message;

  @override
  String toString() {
    return 'CompensationReferenceRepositoryException: $message';
  }
}

abstract interface class CompensationReferenceRepository {
  Future<CompensationReferenceSetting?> findApplicableForMonth({
    required int year,
    required int month,
  });

  Future<CompensationReferenceSetting> save({
    required CompensationReferenceMode mode,
    required int fixedIncludedOvertimeMinutes,
    required int fixedIncludedNightMinutes,
    required int fixedIncludedHolidayMinutes,
    required DateTime effectiveFromMonth,
    required String? memo,
  });
}
