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

  Widget _buildOverallStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('루틴 종료', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('오늘 아침 루틴의 전체 만족도는?'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final score = i + 1;
            return ElevatedButton(
              onPressed: () {
                setState(() {
                  _overall = score;
                  _step = 1;
                });
              },
              child: Text('$score'),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRepeatStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('같은 구성을 내일도 하겠습니까?'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _repeat = true;
                  _step = 2;
                });
              },
              child: const Text('예'),
            ),
            ElevatedButton(
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
      ],
    );
  }

  Widget _buildEnergyStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('시작 시 에너지 수준은?'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final score = i + 1;
            return ElevatedButton(
              onPressed: () {
                widget.onSubmit(
                  overallSatisfaction: _overall!,
                  repeatIntent: _repeat!,
                  energyAtStart: score,
                );
              },
              child: Text('$score'),
            );
          }),
        ),
      ],
    );
  }
}
