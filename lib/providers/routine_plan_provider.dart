import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block_preset.dart';

class RoutinePlanState {
  final List<BlockPreset> selectedBlocks;
  final int currentIndex;

  const RoutinePlanState({
    required this.selectedBlocks,
    required this.currentIndex,
  });

  const RoutinePlanState.empty()
      : selectedBlocks = const [],
        currentIndex = 0;

  bool get hasPlan => selectedBlocks.isNotEmpty;
  bool get hasNext => currentIndex + 1 < selectedBlocks.length;
  BlockPreset? get currentBlock =>
      hasPlan && currentIndex < selectedBlocks.length
          ? selectedBlocks[currentIndex]
          : null;
}

final routinePlanProvider =
    StateNotifierProvider<RoutinePlanNotifier, RoutinePlanState>((ref) {
  return RoutinePlanNotifier();
});

class RoutinePlanNotifier extends StateNotifier<RoutinePlanState> {
  RoutinePlanNotifier() : super(const RoutinePlanState.empty());

  void setPlan(List<BlockPreset> selectedBlocks) {
    state = RoutinePlanState(
      selectedBlocks: selectedBlocks,
      currentIndex: 0,
    );
  }

  void advance() {
    if (!state.hasNext) return;
    state = RoutinePlanState(
      selectedBlocks: state.selectedBlocks,
      currentIndex: state.currentIndex + 1,
    );
  }

  void clear() {
    state = const RoutinePlanState.empty();
  }
}

