import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block.dart';

/// 현재 진행 중인 블록 상태
/// BlockEngine에서 블록 시작/종료 시 직접 업데이트
final activeBlockProvider =
    StateNotifierProvider<ActiveBlockNotifier, Block?>((ref) {
  return ActiveBlockNotifier();
});

class ActiveBlockNotifier extends StateNotifier<Block?> {
  ActiveBlockNotifier() : super(null);

  /// 블록 설정 (시작 후)
  void setBlock(Block block) {
    state = block;
  }

  /// 블록 해제 (종료 후)
  void clearBlock() {
    state = null;
  }

  /// 블록 업데이트 (피드백 등)
  void updateBlock(Block updated) {
    state = updated;
  }
}
