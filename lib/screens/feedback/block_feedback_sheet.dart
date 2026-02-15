import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// 블록 피드백 BottomSheet
/// 2단계 수집:
///   1단계: timeFeel (짧았다 / 적당 / 길었다) — 3버튼
///   2단계: satisfaction (1 ~ 5) — 5버튼
///
/// 중립성: 유도 문구/색상 강조/축하 메시지 금지
class BlockFeedbackSheet extends StatefulWidget {
  final String blockType;
  final int plannedMinutes;
  final void Function(TimeFeel timeFeel, int satisfaction) onSubmit;
  final TimeFeel? initialTimeFeel;

  const BlockFeedbackSheet({
    super.key,
    required this.blockType,
    required this.plannedMinutes,
    required this.onSubmit,
    this.initialTimeFeel,
  });

  @override
  State<BlockFeedbackSheet> createState() => _BlockFeedbackSheetState();
}

class _BlockFeedbackSheetState extends State<BlockFeedbackSheet> {
  TimeFeel? _timeFeel;

  @override
  void initState() {
    super.initState();
    _timeFeel = widget.initialTimeFeel;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: _timeFeel == null ? _buildTimeFeelStep() : _buildSatisfactionStep(),
    );
  }

  Widget _buildTimeFeelStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.blockType} ${widget.plannedMinutes}분',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        // 중립적 질문 — 유도 없이 사실만
        const Text('시간이 어떻게 느껴졌나요?'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TimeFeel.values.map((feel) {
            return ElevatedButton(
              onPressed: () => setState(() => _timeFeel = feel),
              child: Text(feel.label),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSatisfactionStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.blockType} ${widget.plannedMinutes}분',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        // 중립적 질문
        const Text('만족도는?'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final score = i + 1;
            return ElevatedButton(
              onPressed: () => widget.onSubmit(_timeFeel!, score),
              child: Text('$score'),
            );
          }),
        ),
      ],
    );
  }
}
