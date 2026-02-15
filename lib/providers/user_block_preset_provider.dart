import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_block_preset.dart';
import '../services/user_block_preset_service.dart';
import 'auth_provider.dart';

/// UserBlockPresetService 싱글톤
final userBlockPresetServiceProvider = Provider<UserBlockPresetService>((ref) {
  return UserBlockPresetService();
});

/// 사용자 블록 프리셋 목록 (order 순)
final userBlockPresetsProvider = StreamProvider<List<UserBlockPreset>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) {
    return Stream.value([]);
  }

  final service = ref.watch(userBlockPresetServiceProvider);
  return service.watchUserPresets(uid);
});
