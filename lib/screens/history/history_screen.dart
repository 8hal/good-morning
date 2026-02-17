import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/datetime_utils.dart';
import '../../models/session.dart';
import '../../providers/history_provider.dart';
import 'widgets/session_card.dart';

/// History 화면
/// - 날짜별 그룹핑 + 카드 형태 세션 목록
/// - 점수 평균/분석/추천 금지 (실험 중립성)
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  /// 세션 목록을 날짜 그룹별로 분류
  Map<String, List<Session>> _groupByDate(List<Session> sessions) {
    final grouped = <String, List<Session>>{};
    for (final s in sessions) {
      final key = DateTimeUtils.formatDateGroup(s.startAt);
      grouped.putIfAbsent(key, () => []).add(s);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('📅 기록')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(historyProvider),
        child: historyAsync.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return _buildEmptyState(context, ref, theme);
            }
            return _buildSessionList(context, sessions, theme);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildErrorState(context, ref, theme),
        ),
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    List<Session> sessions,
    ThemeData theme,
  ) {
    final grouped = _groupByDate(sessions);
    final dateKeys = grouped.keys.toList();

    return CustomScrollView(
      slivers: [
        for (final dateKey in dateKeys) ...[
          // 날짜 헤더
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                dateKey,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // 해당 날짜의 세션 카드들
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final session = grouped[dateKey]![index];
                return SessionCard(
                  session: session,
                  onTap: () => context.push('/history/${session.id}'),
                );
              },
              childCount: grouped[dateKey]!.length,
            ),
          ),
        ],
        // 하단 여백
        const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history,
                    size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text('아직 루틴 기록이 없습니다',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 4),
                Text('첫 루틴을 시작해 보세요',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => context.go('/start'),
                  child: const Text('Start로 이동'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text('기록을 불러올 수 없습니다',
                    style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ref.invalidate(historyProvider),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
