import 'package:flutter/material.dart';
import '../../models/enums.dart';

/// 블록 피드백 BottomSheet
/// 2단계 수집:
///   1단계: timeFeel (짧았다 / 적당 / 길었다) — 3버튼
///   2단계: satisfaction (1 ~ 5) — 5버튼
///
/// 중립성: 유도 문구/색상 강조/축하 메시지 금지
class BlockFeedbackSheet extends StatefulWidget {
  final String blockLabel;
  final int plannedMinutes;
  final void Function(TimeFeel timeFeel, int satisfaction) onSubmit;
  final TimeFeel? initialTimeFeel;

  const BlockFeedbackSheet({
    super.key,
    required this.blockLabel,
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
      child:
          _timeFeel == null ? _buildTimeFeelStep() : _buildSatisfactionStep(),
    );
  }

  Widget _buildTimeFeelStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.blockLabel} ${widget.plannedMinutes}분',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text('시간이 어떻게 느껴졌나요?'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: TimeFeel.values.map((feel) {
            return FilledButton.tonal(
              onPressed: () => setState(() => _timeFeel = feel),
              child: Text(feel.label),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSatisfactionStep() {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.blockLabel} ${widget.plannedMinutes}분',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        const Text('만족도는?'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final score = i + 1;
            return FilledButton.tonal(
              onPressed: () => widget.onSubmit(_timeFeel!, score),
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
          onPressed: () => setState(() => _timeFeel = null),
          child: const Text('이전 단계로'),
        ),
      ],
    );
  }
}
