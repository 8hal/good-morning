import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dev/seed_test_data.dart';
import '../../providers/auth_provider.dart';

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

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('테스트 데이터 생성 중...')),
      );
      final count = await SeedTestData.seed(uid);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count개 세션이 생성되었습니다. History 탭에서 확인하세요.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
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
