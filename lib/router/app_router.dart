import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/start/start_screen.dart';
import '../screens/now/now_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/settings/settings_screen.dart';

/// 탭 인덱스 ↔ 경로 매핑
const _tabPaths = ['/start', '/history', '/settings'];

/// ShellRoute용 Scaffold (하단 네비게이션 바 포함)
class _MainShell extends StatelessWidget {
  final Widget child;
  const _MainShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _tabPaths.indexOf(location);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Column(
      children: [
        Expanded(child: child),
        NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(_tabPaths[i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.play_circle_outline),
              selectedIcon: Icon(Icons.play_circle),
              label: 'Start',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ],
    );
  }
}

/// 앱 라우터 설정
/// 알림 탭 → 딥링크로 피드백 화면 이동 지원
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/start',
    routes: [
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: '/start',
            name: 'start',
            builder: (context, state) => const StartScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/now',
        name: 'now',
        builder: (context, state) => const NowScreen(),
      ),
    ],
  );
}
