import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/datetime_utils.dart';
import '../../providers/history_provider.dart';

/// History 화면
/// - 세션 리스트 (날짜 + commuteType만 표시)
/// - 점수 평균/분석/추천 금지 (실험 중립성)
///
/// Step 4 최소 구현:
/// - 세션 리스트(날짜, commuteType, 시작/종료 시각)
/// - 점수/평균/추천 노출 없음
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록'),
      ),
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('기록이 없습니다.'));
          }

          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final endText = session.endAt == null
                  ? '-'
                  : DateTimeUtils.formatTime(session.endAt!);
              return ListTile(
                title: Text(
                  DateTimeUtils.formatDate(session.startAt),
                ),
                subtitle: Text(
                  '${session.commuteType.label} · ${DateTimeUtils.formatTime(session.startAt)} - $endText',
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('조회 실패: $e')),
      ),
    );
  }
}
