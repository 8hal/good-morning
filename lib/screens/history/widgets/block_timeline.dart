import 'package:flutter/material.dart';
import '../../../core/utils/datetime_utils.dart';
import '../../../models/block.dart';
import '../../../models/enums.dart';

/// 세션 상세의 블록 타임라인 위젯
/// 세로선 + 점으로 시간순 블록을 표시
class BlockTimeline extends StatelessWidget {
  final List<Block> blocks;
  final DateTime? sessionEndAt;

  const BlockTimeline({
    super.key,
    required this.blocks,
    this.sessionEndAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (blocks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            '기록된 블록이 없습니다',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < blocks.length; i++)
          _BlockTimelineItem(
            block: blocks[i],
            isLast: i == blocks.length - 1,
          ),
        // 세션 종료 마커
        if (sessionEndAt != null)
          _SessionEndMarker(endAt: sessionEndAt!),
      ],
    );
  }
}

/// 타임라인의 개별 블록 항목
class _BlockTimelineItem extends StatelessWidget {
  final Block block;
  final bool isLast;

  const _BlockTimelineItem({
    required this.block,
    required this.isLast,
  });

  String get _timeFeelDisplay {
    if (block.timeFeel == null) return '';
    switch (block.timeFeel!) {
      case TimeFeel.short_:
        return '⚡ 짧았다';
      case TimeFeel.ok:
        return '👍 적당';
      case TimeFeel.long_:
        return '🐌 길었다';
    }
  }

  String? get _timeDiffDisplay {
    if (block.actualMinutes == null) return null;
    final diff = block.actualMinutes! - block.plannedMinutes;
    if (diff == 0) return null;
    if (diff > 0) return '⏰ +$diff분';
    return '⚡ $diff분';
  }

  Color? _timeDiffColor(ThemeData theme) {
    if (block.actualMinutes == null) return null;
    final diff = block.actualMinutes! - block.plannedMinutes;
    if (diff > 0) return Colors.orange.shade700;
    if (diff < 0) return Colors.green.shade700;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final startTime = DateTimeUtils.formatTime(block.startAt);
    final durationText = block.actualMinutes != null
        ? '${block.actualMinutes}분'
        : '${block.plannedMinutes}분';

    final hasFeedback = block.timeFeel != null || block.satisfaction != null;
    final timeDiff = _timeDiffDisplay;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시간 라벨
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                startTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // 타임라인 점 + 선
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 블록 정보
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 블록 이름 + 소요 시간
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          block.displayLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        durationText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      if (timeDiff != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          timeDiff,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _timeDiffColor(theme),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 피드백 정보 (있는 경우만)
                  if (hasFeedback) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (block.timeFeel != null)
                          Text(
                            _timeFeelDisplay,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        if (block.timeFeel != null &&
                            block.satisfaction != null)
                          Text(
                            ' · ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        if (block.satisfaction != null)
                          Text(
                            '⭐' * block.satisfaction!,
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 세션 종료 마커
class _SessionEndMarker extends StatelessWidget {
  final DateTime endAt;

  const _SessionEndMarker({required this.endAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endTime = DateTimeUtils.formatTime(endAt);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시간 라벨
        SizedBox(
          width: 52,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              endTime,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        // 종료 점
        SizedBox(
          width: 24,
          child: Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // 종료 라벨
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '세션 종료',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}
