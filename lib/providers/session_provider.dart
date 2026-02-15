import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// 현재 활성 세션 상태
final activeSessionProvider =
    StateNotifierProvider<ActiveSessionNotifier, AsyncValue<Session?>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ActiveSessionNotifier(uid: uid, firestoreService: firestoreService);
});

class ActiveSessionNotifier extends StateNotifier<AsyncValue<Session?>> {
  final String? uid;
  final FirestoreService firestoreService;

  ActiveSessionNotifier({
    required this.uid,
    required this.firestoreService,
  }) : super(const AsyncValue.loading()) {
    _loadActiveSession();
  }

  Future<void> _loadActiveSession() async {
    final currentUid = uid;
    if (currentUid == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final session = await firestoreService.getActiveSession(currentUid);
      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 세션 설정 (시작 후)
  void setSession(Session session) {
    state = AsyncValue.data(session);
  }

  /// 세션 해제 (종료 후)
  void clearSession() {
    state = const AsyncValue.data(null);
  }

  /// 새로고침
  Future<void> refresh() async {
    await _loadActiveSession();
  }
}
