import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_state.dart';
import '../models/routine_suggestion.dart';
import '../models/user_settings.dart';
import 'auth_provider.dart';
import 'service_providers.dart';
import 'settings_provider.dart';
import 'user_block_preset_provider.dart';

/// 현재 루틴 제안 상태를 관리하는 StateNotifier
final morningAssistantProvider = StateNotifierProvider<
    MorningAssistantNotifier, AsyncValue<RoutineSuggestion>>((ref) {
  return MorningAssistantNotifier(ref);
});

class MorningAssistantNotifier
    extends StateNotifier<AsyncValue<RoutineSuggestion>> {
  final Ref _ref;

  MorningAssistantNotifier(this._ref) : super(const AsyncValue.loading());

  /// 초기 제안 생성 (앱 시작 시 호출)
  Future<void> loadSuggestion() async {
    state = const AsyncValue.loading();

    // #region agent log
    debugPrint('[DEBUG-PROVIDER-A] loadSuggestion started');
    // #endregion

    try {
      final uid = _ref.read(currentUidProvider);
      
      // #region agent log
      debugPrint('[DEBUG-PROVIDER-B] uid: $uid');
      // #endregion
      
      final assistant = _ref.read(morningAssistantServiceProvider);
      final firestoreService = _ref.read(firestoreServiceProvider);

      final settings = _ref.read(settingsProvider).value ?? const UserSettings();
      final presets = _ref.read(userBlockPresetsProvider).value ?? [];

      // #region agent log
      debugPrint('[DEBUG-PROVIDER-C] Context loaded: presets=${presets.length}, settings=${settings.defaultCommuteType.name}');
      // #endregion

      // 마지막 세션 조회
      final lastSession =
          uid != null ? await firestoreService.getLastSession(uid) : null;

      // #region agent log
      debugPrint('[DEBUG-PROVIDER-D] Last session: ${lastSession != null ? lastSession.dateKey : "null"}');
      // #endregion

      final suggestion = await assistant.generateSuggestion(
        now: DateTime.now(),
        lastSession: lastSession,
        presets: presets,
        settings: settings,
      );

      // #region agent log
      debugPrint('[DEBUG-PROVIDER-E] Suggestion generated: blocks=${suggestion.blocks.length}');
      // #endregion

      if (mounted) {
        state = AsyncValue.data(suggestion);
      }
    } catch (e, st) {
      // #region agent log
      debugPrint('[DEBUG-PROVIDER-ERROR] 루틴 제안 생성 실패: $e');
      debugPrint('[DEBUG-PROVIDER-ERROR] Stack trace: $st');
      // #endregion
      
      debugPrint('루틴 제안 생성 실패: $e');
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// 온보딩 결과를 반영한 제안 생성
  Future<void> loadSuggestionWithContext({
    required String commuteType,
    required String anchorTime,
    required UserCondition condition,
  }) async {
    state = const AsyncValue.loading();

    try {
      final uid = _ref.read(currentUidProvider);
      final assistant = _ref.read(morningAssistantServiceProvider);
      final firestoreService = _ref.read(firestoreServiceProvider);
      final settings =
          _ref.read(settingsProvider).value ?? const UserSettings();
      final presets = _ref.read(userBlockPresetsProvider).value ?? [];

      final lastSession =
          uid != null ? await firestoreService.getLastSession(uid) : null;

      final suggestion = await assistant.generateSuggestion(
        now: DateTime.now(),
        lastSession: lastSession,
        presets: presets,
        settings: settings,
        commuteType: commuteType,
        anchorTime: anchorTime,
        condition: condition,
      );

      if (mounted) {
        state = AsyncValue.data(suggestion);
      }
    } catch (e, st) {
      debugPrint('온보딩 기반 루틴 제안 생성 실패: $e');
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// 자연어 수정 요청
  Future<bool> modify(String userMessage) async {
    final current = state.value;
    if (current == null) {
      debugPrint('[MODIFY-PROVIDER] state.value가 null — 수정 불가');
      return false;
    }

    try {
      final assistant = _ref.read(morningAssistantServiceProvider);
      final presets = _ref.read(userBlockPresetsProvider).value ?? [];
      debugPrint('[MODIFY-PROVIDER] 서비스 호출 시작: presets=${presets.length}');

      final updated = await assistant.modifySuggestion(
        userMessage: userMessage,
        currentSuggestion: current,
        presets: presets,
      );

      debugPrint('[MODIFY-PROVIDER] 서비스 응답: updated=${updated != null}, mounted=$mounted');

      if (updated != null) {
        debugPrint('[MODIFY-PROVIDER] 새 제안: blocks=${updated.blocks.length}, '
            'anchor=${updated.anchorTime}, commute=${updated.commuteType}');
        
        // 수동 변경사항 보존: 기존 블록과 이름 매칭하여 수정된 시간 유지
        final mergedBlocks = updated.blocks.map((newBlock) {
          final existingBlock = current.blocks.firstWhere(
            (b) => b.name == newBlock.name,
            orElse: () => newBlock,
          );
          
          // 이름이 같은 블록이 있고, AI가 기본 시간을 제안했다면 수동 변경 시간 유지
          if (existingBlock != newBlock && existingBlock.name == newBlock.name) {
            return newBlock.copyWith(minutes: existingBlock.minutes);
          }
          return newBlock;
        }).toList();

        final merged = updated.copyWith(blocks: mergedBlocks);
        
        for (final b in merged.blocks) {
          debugPrint('[MODIFY-PROVIDER]   블록: ${b.name} ${b.minutes}분');
        }

        state = AsyncValue.data(merged);
        debugPrint('[MODIFY-PROVIDER] state 업데이트 완료 (수동 변경사항 보존) ✓');
        return true;
      }

      debugPrint('[MODIFY-PROVIDER] 업데이트 실패: updated=${updated != null}, mounted=$mounted');
      return false;
    } catch (e, st) {
      debugPrint('[MODIFY-PROVIDER] 예외 발생: $e');
      debugPrint('[MODIFY-PROVIDER] 스택: ${st.toString().split('\n').take(5).join('\n')}');
      return false;
    }
  }

  /// 로컬에서 블록 순서 변경
  void reorderBlock(int from, int to) {
    final current = state.value;
    if (current == null ||
        from < 0 ||
        to < 0 ||
        from >= current.blocks.length ||
        to >= current.blocks.length) {
      return;
    }

    final blocks = List<SuggestedBlock>.from(current.blocks);
    final block = blocks.removeAt(from);
    blocks.insert(to, block);
    state = AsyncValue.data(current.copyWith(blocks: blocks));
  }

  /// 로컬에서 블록 삭제
  void deleteBlock(int index) {
    final current = state.value;
    if (current == null || index < 0 || index >= current.blocks.length) {
      return;
    }

    final blocks = List<SuggestedBlock>.from(current.blocks);
    blocks.removeAt(index);
    state = AsyncValue.data(current.copyWith(blocks: blocks));
  }

  /// 로컬에서 블록 시간 수정
  void updateBlockTime(int index, int minutes) {
    final current = state.value;
    if (current == null || index < 0 || index >= current.blocks.length) {
      return;
    }

    final blocks = List<SuggestedBlock>.from(current.blocks);
    blocks[index] = blocks[index].copyWith(minutes: minutes);
    state = AsyncValue.data(current.copyWith(blocks: blocks));
  }

  /// 로컬에서 앵커 타임 변경
  void setAnchorTime(String anchorTime) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(anchorTime: anchorTime));
  }

  /// 로컬에서 출퇴근 타입 변경
  void setCommuteType(String commuteType) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(commuteType: commuteType));
  }

  /// 제안 직접 설정 (외부에서)
  void setSuggestion(RoutineSuggestion suggestion) {
    state = AsyncValue.data(suggestion);
  }
}
