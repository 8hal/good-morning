import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_settings.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// 사용자 설정 프로바이더
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettings>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  return SettingsNotifier(uid: uid, firestoreService: firestoreService);
});

class SettingsNotifier extends StateNotifier<AsyncValue<UserSettings>> {
  final String? uid;
  final FirestoreService firestoreService;

  SettingsNotifier({
    required this.uid,
    required this.firestoreService,
  }) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final currentUid = uid;
    if (currentUid == null) {
      state = const AsyncValue.data(UserSettings());
      return;
    }

    try {
      final settings = await firestoreService.getUserSettings(currentUid);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 설정 업데이트
  Future<void> updateSettings(UserSettings newSettings) async {
    final currentUid = uid;
    if (currentUid == null) return;

    try {
      await firestoreService.saveUserSettings(currentUid, newSettings);
      state = AsyncValue.data(newSettings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
