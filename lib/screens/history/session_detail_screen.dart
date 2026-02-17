import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/datetime_utils.dart';
import '../../models/enums.dart';
import '../../providers/session_detail_provider.dart';
import 'widgets/block_timeline.dart';

/// 세션 상세 화면
/// 세션 요약 + 블록 타임라인
class SessionDetailScreen extends ConsumerWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  /// 에너지 레벨 라벨
  String _energyLabel(int energy) {
    switch (energy) {
      case 1:
        return '😫 매우 낮음';
      case 2:
        return '😔 낮음';
      case 3:
        return '😐 보통';
      case 4:
        return '😊 좋음';
      case 5:
        return '🔥 최고';
      default:
        return '$energy';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(sessionDetailProvider(sessionId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: detailAsync.whenOrNull(
          data: (detail) => Text(
            DateTimeUtils.formatDate(detail.session.startAt),
          ),
        ),
      ),
      body: detailAsync.when(
        data: (detail) {
          final session = detail.session;
          final blocks = detail.blocks;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(sessionDetailProvider(sessionId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 세션 요약 카드
                  _buildSummaryCard(context, theme, session),
                  const SizedBox(height: 24),
                  // 블록 타임라인 헤더
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      '블록 타임라인',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 블록 타임라인
                  BlockTimeline(
                    blocks: blocks,
                    sessionEndAt: session.endAt,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text('세션 정보를 불러올 수 없습니다',
                  style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () =>
                    ref.invalidate(sessionDetailProvider(sessionId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme,
    dynamic session,
  ) {
    final commuteIcon =
        session.commuteType == CommuteType.home ? '🏠' : '🏢';
    final startTime = DateTimeUtils.formatTime(session.startAt);
    final endTime = session.endAt != null
        ? DateTimeUtils.formatTime(session.endAt!)
        : '진행 중';
    final duration = session.endAt != null
        ? DateTimeUtils.formatDuration(
            session.endAt!.difference(session.startAt))
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 출퇴근 타입
            Row(
              children: [
                Text(commuteIcon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  session.commuteType.label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 시간 정보
            _buildInfoRow(
              theme,
              Icons.schedule,
              '$startTime → $endTime',
            ),
            if (duration != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                theme,
                Icons.timer_outlined,
                '소요: $duration',
              ),
            ],
            // 만족도 (있는 경우)
            if (session.overallSatisfaction != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                theme,
                Icons.star_outline,
                '만족도: ${'⭐' * session.overallSatisfaction!} (${session.overallSatisfaction}/5)',
              ),
            ],
            // 시작 에너지 (있는 경우)
            if (session.energyAtStart != null) ...[
              const SizedBox(height: 6),
              _buildInfoRow(
                theme,
                Icons.bolt_outlined,
                '시작 에너지: ${_energyLabel(session.energyAtStart!)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
