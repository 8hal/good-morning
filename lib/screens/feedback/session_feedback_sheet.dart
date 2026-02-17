import 'package:flutter/material.dart';

/// 세션 종합 피드백 BottomSheet
/// 수집 항목:
///   - overallSatisfaction (1~5)
///   - repeatIntent (예/아니오)
///   - energyAtStart (1~5)
///
/// 중립성: 유도 문구/축하/요약/평균 노출 금지
class SessionFeedbackSheet extends StatefulWidget {
  final void Function({
    required int overallSatisfaction,
    required bool repeatIntent,
    required int energyAtStart,
  }) onSubmit;

  const SessionFeedbackSheet({
    super.key,
    required this.onSubmit,
  });

  @override
  State<SessionFeedbackSheet> createState() => _SessionFeedbackSheetState();
}

class _SessionFeedbackSheetState extends State<SessionFeedbackSheet> {
  int _step = 0; // 0: overall, 1: repeat, 2: energy
  int? _overall;
  bool? _repeat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0:
        return _buildOverallStep();
      case 1:
        return _buildRepeatStep();
      case 2:
        return _buildEnergyStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStepIndicator() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          final isActive = i == _step;
          return Container(
            width: isActive ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOverallStep() {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepIndicator(),
        Text('루틴 종료', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        const Text('오늘 아침 루틴의 전체 만족도는?'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final score = i + 1;
            return FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _overall = score;
                  _step = 1;
                });
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: Text('$score', style: const TextStyle(fontSize: 16)),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('낮음',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              Text('높음',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepIndicator(),
        const Text('같은 구성을 내일도 하겠습니까?'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _repeat = true;
                  _step = 2;
                });
              },
              child: const Text('예'),
            ),
            FilledButton.tonal(
              onPressed: () {
                setState(() {
                  _repeat = false;
                  _step = 2;
                });
              },
              child: const Text('아니오'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('이전 단계로'),
        ),
      ],
    );
  }

  Widget _buildEnergyStep() {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepIndicator(),
        const Text('시작 시 에너지 수준은?'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final score = i + 1;
            return FilledButton.tonal(
              onPressed: () {
                widget.onSubmit(
                  overallSatisfaction: _overall!,
                  repeatIntent: _repeat!,
                  energyAtStart: score,
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: Text('$score', style: const TextStyle(fontSize: 16)),
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('낮음',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
              Text('높음',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('이전 단계로'),
        ),
      ],
    );
  }
}
