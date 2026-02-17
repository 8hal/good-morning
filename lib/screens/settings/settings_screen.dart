import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dev/seed_test_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';

/// Settings 화면
/// - 블록 관리 바로가기
/// - 로그아웃
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _seedTestData(WidgetRef ref, BuildContext context) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('테스트 데이터 생성 중...')),
    );

    final result = await SeedTestData.seed(uid);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result.successCount > 0) {
      ref.invalidate(historyProvider);
    }

    if (result.isFullSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${result.successCount}개 세션 생성 완료. History 탭에서 확인하세요.',
          ),
        ),
      );
    } else {
      // 에러 또는 부분 실패 → 상세 다이얼로그
      _showSeedResultDialog(context, result);
    }
  }

  void _showSeedResultDialog(BuildContext context, SeedResult result) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.hasError ? Icons.error : Icons.warning_amber,
              color: result.hasError
                  ? theme.colorScheme.error
                  : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              result.hasError ? '시딩 오류' : '부분 성공',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '결과: ${result.successCount}/${result.totalCount} 세션 성공',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (result.error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    result.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text('실행 로그:', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    result.logs.join('\n'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (result.stackTrace != null) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  title: Text('스택 트레이스',
                      style: theme.textTheme.labelMedium),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          result.stackTrace!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    await ref.read(authServiceProvider).signOut();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그아웃되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 블록 관리 바로가기
            Card(
              child: ListTile(
                leading: const Icon(Icons.view_module),
                title: const Text('블록 관리'),
                subtitle: const Text('블록 추가·수정·삭제·순서 변경'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/blocks'),
              ),
            ),
            // 개발용 테스트 데이터 버튼 (debug 모드에서만)
            if (kDebugMode)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bug_report),
                  title: const Text('테스트 데이터 생성'),
                  subtitle: const Text('최근 5일치 세션 + 블록'),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => _seedTestData(ref, context),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _signOut(ref, context),
                child: const Text('로그아웃'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
