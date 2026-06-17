import 'package:flutter/material.dart';

import '../../../core/theme/workledger_design_tokens.dart';
import '../domain/work_time_candidate.dart';

final class WorkTimeCandidateSummaryCard extends StatelessWidget {
  const WorkTimeCandidateSummaryCard({required this.summary, super.key});

  final WorkTimeCandidateSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '근무 태그',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            _CandidateReferenceRows(summary: summary),
          ],
        ),
      ),
    );
  }
}

final class _CandidateReferenceRows extends StatelessWidget {
  const _CandidateReferenceRows({required this.summary});

  final WorkTimeCandidateSummary summary;

  @override
  Widget build(BuildContext context) {
    final List<_CandidateReferenceData> rows = _visibleCandidateRows(
      summary: summary,
    );
    return Column(
      children: <Widget>[
        for (int index = 0; index < rows.length; index += 1) ...<Widget>[
          if (index > 0) const SizedBox(height: workLedgerSpacingCompact),
          _CandidateReferenceRow(
            label: rows[index].label,
            value: _formatDuration(duration: rows[index].duration),
          ),
        ],
      ],
    );
  }
}

final class _CandidateReferenceData {
  const _CandidateReferenceData({required this.label, required this.duration});

  final String label;
  final Duration duration;
}

List<_CandidateReferenceData> _visibleCandidateRows({
  required WorkTimeCandidateSummary summary,
}) {
  final List<_CandidateReferenceData> rows = <_CandidateReferenceData>[
    _CandidateReferenceData(
      label: '휴무일 근무',
      duration: summary.nonWorkdayDuration,
    ),
    _CandidateReferenceData(
      label: '정시 근무',
      duration: summary.regularWorkDuration,
    ),
    _CandidateReferenceData(
      label: '정시 전 근무',
      duration: summary.earlyWorkDuration,
    ),
    _CandidateReferenceData(label: '연장 근무', duration: summary.overtimeDuration),
    _CandidateReferenceData(
      label: '야간 근무',
      duration: summary.nightWorkDuration,
    ),
  ];
  return rows
      .where((_CandidateReferenceData row) => row.duration > Duration.zero)
      .toList(growable: false);
}

final class _CandidateReferenceRow extends StatelessWidget {
  const _CandidateReferenceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: workLedgerColorMuted,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: workLedgerColorInk,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

String _formatDuration({required Duration duration}) {
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
