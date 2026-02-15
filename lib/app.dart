import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/service_providers.dart';
import 'router/app_router.dart';
import 'services/local_queue_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 앱 루트 위젯
class GoodMorningApp extends ConsumerStatefulWidget {
  const GoodMorningApp({super.key});

  @override
  ConsumerState<GoodMorningApp> createState() => _GoodMorningAppState();
}

class _GoodMorningAppState extends ConsumerState<GoodMorningApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_flushLocalQueue);
  }

  Future<void> _flushLocalQueue() async {
    final queue = ref.read(localQueueServiceProvider);
    final firestore = ref.read(firestoreServiceProvider);
    await queue.retryAll((operation, data) async {
      try {
        if (operation == 'updateBlock') {
          final sessionId = data['sessionId'] as String;
          final blockId = data['blockId'] as String;
          final updates = Map<String, dynamic>.from(
            data['updates'] as Map<String, dynamic>,
          );
          if (updates['endAtIso'] != null) {
            updates['endAt'] = Timestamp.fromDate(
              DateTime.parse(updates['endAtIso'] as String),
            );
            updates.remove('endAtIso');
          }
          await firestore.updateBlock(sessionId, blockId, updates);
          return true;
        }

        if (operation == 'updateSession') {
          final sessionId = data['sessionId'] as String;
          final updates = Map<String, dynamic>.from(
            data['updates'] as Map<String, dynamic>,
          );
          if (updates['endAtIso'] != null) {
            updates['endAt'] = Timestamp.fromDate(
              DateTime.parse(updates['endAtIso'] as String),
            );
            updates.remove('endAtIso');
          }
          await firestore.updateSession(sessionId, updates);
          return true;
        }
      } catch (_) {
        return false;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Good Morning',
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
