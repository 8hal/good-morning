import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../dev/debug_log.dart';
import '../../models/block_preset.dart';
import '../../models/enums.dart';
import '../../models/onboarding_state.dart';
import '../../providers/active_block_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/morning_assistant_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/routine_plan_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_block_preset_provider.dart';
import 'widgets/chat_input.dart';
import 'widgets/onboarding_flow.dart';
import 'widgets/suggestion_card.dart';

/// Start 화면 - 대화형 온보딩 → AI 기반 스마트 루틴 제안
///
/// Phase 1: 대화형 온보딩 (출퇴근, 앵커 타임, 컨디션 질문)
/// Phase 2: Gemini 루틴 제안 카드 + ChatInput
class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  bool _isBusy = false;
  String _defaultAnchorTime = '09:00';
  bool _anchorTimeLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAuthAndLoad();
    });
  }

  Future<void> _ensureAuthAndLoad() async {
    try {
      final authService = ref.read(authServiceProvider);
      if (authService.currentUser == null) {
        await authService.signInAnonymously();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 실패: $e')),
      );
      return;
    }

    await _waitForProviders();
    await _loadDefaultAnchorTime();
  }

  Future<void> _waitForProviders() async {
    for (int i = 0; i < 50; i++) {
      final settings = ref.read(settingsProvider);
      final presets = ref.read(userBlockPresetsProvider);
      if (!settings.isLoading && !presets.isLoading) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _loadDefaultAnchorTime() async {
    if (_anchorTimeLoaded) return;
    final uid = ref.read(currentUidProvider);
    if (uid != null) {
      try {
        final firestoreService = ref.read(firestoreServiceProvider);
        final lastSession = await firestoreService.getLastSession(uid);
        if (lastSession != null && mounted) {
          setState(() {
            _defaultAnchorTime =
                DateFormat('HH:mm').format(lastSession.anchorTime);
          });
        }
      } catch (_) {}
    }
    _anchorTimeLoaded = true;
  }

  String get _defaultCommuteType {
    final settings = ref.read(settingsProvider).value;
    return settings?.defaultCommuteType.name ?? 'office';
  }

  Future<void> _pickAnchorTime() async {
    final suggestion = ref.read(morningAssistantProvider).value;
    if (suggestion == null) return;

    final parts = suggestion.anchorTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 9,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      ref.read(morningAssistantProvider.notifier).setAnchorTime(formatted);
    }
  }

  Future<void> _startRoutine() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 중입니다. 잠시 후 다시 시도해 주세요.')),
      );
      return;
    }

    final suggestion = ref.read(morningAssistantProvider).value;
    if (suggestion == null) return;

    final selectedBlocks = suggestion.blocks
        .where((b) => b.selected)
        .map((b) => BlockPreset(
              blockType: 'free',
              defaultMinutes: b.minutes,
              label: b.name,
            ))
        .toList();

    if (selectedBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 블록을 선택해 주세요.')),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final engine = ref.read(blockEngineProvider);

      final anchorParts = suggestion.anchorTime.split(':');
      final now = DateTime.now();
      final anchorTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.tryParse(anchorParts.elementAtOrNull(0) ?? '') ?? 9,
        int.tryParse(anchorParts.elementAtOrNull(1) ?? '') ?? 0,
      );

      final commuteType = CommuteType.fromJson(suggestion.commuteType);

      final session = await engine.startSession(
        uid: uid,
        anchorTime: anchorTime,
        commuteType: commuteType,
        anchorSource: AnchorSource.manual,
      );

      if (!mounted) return;

      if (session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 활성 세션이 있습니다.')),
        );
        return;
      }

      final firstBlock = await engine.startBlock(
        sessionId: session.id,
        preset: selectedBlocks.first,
      );
      if (!mounted) return;
      if (firstBlock == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('블록 시작에 실패했습니다.')),
        );
        return;
      }

      ref.read(activeSessionProvider.notifier).setSession(session);
      ref.read(activeBlockProvider.notifier).setBlock(firstBlock);
      ref.read(routinePlanProvider.notifier).setPlan(selectedBlocks);

      if (!mounted) return;
      context.push('/now');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('루틴 시작 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool> _handleChatMessage(String message) async {
    return ref.read(morningAssistantProvider.notifier).modify(message);
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = ref.watch(activeSessionProvider);
    final onboarding = ref.watch(onboardingProvider);
    final suggestionAsync = ref.watch(morningAssistantProvider);
    final theme = Theme.of(context);
    final hasActiveSession = activeSession.value != null;
    final isComplete = onboarding.phase == OnboardingPhase.complete;

    // #region agent log
    dlog('start_screen.dart:build', 'build called', {
      'onboardingPhase': onboarding.phase.name,
      'isComplete': isComplete,
      'suggestionIsLoading': suggestionAsync.isLoading,
      'suggestionHasValue': suggestionAsync.hasValue,
      'suggestionHasError': suggestionAsync.hasError,
      'suggestionError': suggestionAsync.hasError ? suggestionAsync.error.toString() : null,
    }, 'H3');
    // #endregion

    return Scaffold(
      appBar: AppBar(title: const Text('Good Morning')),
      body: Column(
        children: [
          // 진행 중인 루틴 배너
          if (hasActiveSession)
            Material(
              color: theme.colorScheme.primaryContainer,
              child: InkWell(
                onTap: () => context.push('/now'),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '진행 중인 루틴이 있습니다',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: theme.colorScheme.onPrimaryContainer),
                    ],
                  ),
                ),
              ),
            ),

          // 메인 콘텐츠
          Expanded(
            child: isComplete
                // Phase 2: 루틴 제안 카드 (기존)
                ? suggestionAsync.when(
                    data: (suggestion) => SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: SuggestionCard(
                        suggestion: suggestion,
                        onAnchorTimeTap: _pickAnchorTime,
                        onCommuteTypeChanged: (type) {
                          ref
                              .read(morningAssistantProvider.notifier)
                              .setCommuteType(type);
                        },
                        onBlockToggle: (index) {
                          ref
                              .read(morningAssistantProvider.notifier)
                              .toggleBlock(index);
                        },
                        onToggleSelectAll: () {
                          ref
                              .read(morningAssistantProvider.notifier)
                              .toggleSelectAll();
                        },
                        onStart: _startRoutine,
                        isBusy: _isBusy,
                      ),
                    ),
                    loading: () => _buildLoadingState(theme),
                    error: (e, _) => _buildErrorState(theme, e),
                  )
                // Phase 1: 대화형 온보딩
                : OnboardingFlow(
                    state: onboarding,
                    defaultAnchorTime: _defaultAnchorTime,
                    defaultCommuteType: _defaultCommuteType,
                    onCommuteSelected: (type) => ref
                        .read(onboardingProvider.notifier)
                        .selectCommuteType(type),
                    onAnchorConfirmed: (time) => ref
                        .read(onboardingProvider.notifier)
                        .confirmAnchorTime(time),
                    onConditionSelected: (c) => ref
                        .read(onboardingProvider.notifier)
                        .selectCondition(c),
                  ),
          ),

          // Phase 2에서만 ChatInput 표시
          if (isComplete && suggestionAsync.hasValue)
            ChatInput(
              onSend: _handleChatMessage,
              enabled: !_isBusy,
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '오늘의 루틴을 준비하고 있습니다...',
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '루틴 제안을 불러오지 못했습니다',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.read(onboardingProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
