import 'package:flutter/material.dart';

import '../../../core/models/pricing_intent_event.dart';
import '../../../core/theme/workledger_design_tokens.dart';
import '../domain/pricing_intent_repository.dart';
import '../domain/record_pricing_intent.dart';

final class PricingFakeDoorScreen extends StatefulWidget {
  const PricingFakeDoorScreen({required this.repository, super.key});

  final PricingIntentRepository repository;

  @override
  State<PricingFakeDoorScreen> createState() => _PricingFakeDoorScreenState();
}

final class _PricingFakeDoorScreenState extends State<PricingFakeDoorScreen> {
  String? _errorMessage;
  String? _successMessage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _recordScreenViewed();
  }

  Future<void> _recordScreenViewed() async {
    try {
      await recordPricingIntent(
        repository: widget.repository,
        eventType: PricingIntentEventType.pricingScreenViewed,
        selectedPlan: null,
        sourceScreen: 'pricing_fake_door',
      );
    } on PricingIntentRepositoryException catch (error) {
      _showError('가격 화면 진입 기록을 저장할 수 없습니다. ${error.toString()}');
    } on ArgumentError catch (error) {
      _showError('가격 화면 진입 기록을 저장할 수 없습니다. ${error.message}');
    }
  }

  Future<void> _recordPlanInterest({
    required PricingIntentEventType eventType,
    required PricingPlan selectedPlan,
  }) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await recordPricingIntent(
        repository: widget.repository,
        eventType: eventType,
        selectedPlan: selectedPlan,
        sourceScreen: 'pricing_fake_door',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _successMessage = '관심을 기록했습니다. MVP 테스트 중인 기능입니다.';
      });
    } on PricingIntentRepositoryException catch (error) {
      _showError('가격 관심 이벤트를 저장할 수 없습니다. ${error.toString()}');
    } on ArgumentError catch (error) {
      _showError('가격 관심 이벤트를 저장할 수 없습니다. ${error.message}');
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('월간 리포트')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            workLedgerSpacingLarge,
            workLedgerSpacingExtraSmall,
            workLedgerSpacingLarge,
            workLedgerSpacingLarge,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _PricingIntroCard(),
              const SizedBox(height: workLedgerSpacingMedium),
              _PricingPlanCard(
                title: 'Report Pass',
                description: '월간 리포트 1회',
                detail: '개인 기록 요약',
                buttonKey: const Key('reportPassInterestButton'),
                isSaving: _isSaving,
                onInterest: () => _recordPlanInterest(
                  eventType: PricingIntentEventType.reportPassTapped,
                  selectedPlan: PricingPlan.reportPass,
                ),
              ),
              const SizedBox(height: workLedgerSpacingMedium),
              _PricingPlanCard(
                title: 'Pro',
                description: '매월 리포트와 고급 요약',
                detail: '가격 보기 클릭 측정',
                buttonKey: const Key('proInterestButton'),
                isSaving: _isSaving,
                onInterest: () => _recordPlanInterest(
                  eventType: PricingIntentEventType.proPlanTapped,
                  selectedPlan: PricingPlan.pro,
                ),
              ),
              if (_successMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                _PricingMessage(message: _successMessage!),
              ],
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                _PricingMessage(message: _errorMessage!),
              ],
              const SizedBox(height: workLedgerSpacingMedium),
              Text(
                '법률 자문이나 증거 효력을 보장하지 않습니다.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: workLedgerColorMuted,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _PricingIntroCard extends StatelessWidget {
  const _PricingIntroCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorSignatureCoral,
        borderRadius: BorderRadius.circular(workLedgerRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '내 근무 기록을 월말에 정리하는 리포트 기능을 준비 중입니다.',
              style: workLedgerTitleMediumTextStyle.copyWith(
                color: workLedgerColorOnPrimary,
              ),
            ),
            const SizedBox(height: workLedgerSpacingSmall),
            Text(
              '실제 결제는 진행되지 않습니다.',
              style: workLedgerBodyTextStyle.copyWith(
                color: workLedgerColorOnPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PricingPlanCard extends StatelessWidget {
  const _PricingPlanCard({
    required this.title,
    required this.description,
    required this.detail,
    required this.buttonKey,
    required this.isSaving,
    required this.onInterest,
  });

  final String title;
  final String description;
  final String detail;
  final Key buttonKey;
  final bool isSaving;
  final VoidCallback onInterest;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorCanvas,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingExtraLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: workLedgerPricingCardTitleTextStyle.copyWith(
                color: workLedgerColorPricingInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: workLedgerBodyTextStyle.copyWith(
                color: workLedgerColorInk,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: workLedgerBodyTextStyle.copyWith(
                color: workLedgerColorMuted,
              ),
            ),
            const SizedBox(height: workLedgerSpacingMedium),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: buttonKey,
                onPressed: isSaving ? null : onInterest,
                style: FilledButton.styleFrom(
                  backgroundColor: workLedgerColorCanvas,
                  foregroundColor: workLedgerColorPricingInk,
                  minimumSize: const Size(132, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(workLedgerRadiusPill),
                  ),
                  side: const BorderSide(color: workLedgerColorHairline),
                  textStyle: workLedgerButtonTextStyle,
                ),
                child: const Text('관심 있음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PricingMessage extends StatelessWidget {
  const _PricingMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: workLedgerColorSurfaceSoft,
        border: Border.all(color: workLedgerColorHairline),
        borderRadius: BorderRadius.circular(workLedgerRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(workLedgerSpacingMedium),
        child: Text(
          message,
          style: workLedgerBodyTextStyle.copyWith(color: workLedgerColorInk),
        ),
      ),
    );
  }
}
