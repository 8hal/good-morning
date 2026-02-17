import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/datetime_utils.dart';
import '../../providers/active_block_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routine_plan_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/service_providers.dart';
import '../../models/enums.dart';
import '../../models/block.dart';
import '../../services/notification_service.dart';
import '../feedback/block_feedback_sheet.dart';
import '../feedback/session_feedback_sheet.dart';

/// Now 화면
/// - 현재 블록 타이머 (남은 시간 / 종료 예정 시각)
/// - 수동 종료 버튼
/// - 다음 블록 정보 (순서만, 추천/강조 금지)
/// - 루틴 종료 버튼
///
/// Step 2 최소 구현:
/// - 현재 블록 진행 정보 표시
/// - 블록 수동 종료 + 피드백 수집
/// - 다음 블록 시작 또는 세션 종료
class NowScreen extends ConsumerStatefulWidget {
  const NowScreen({super.key});

  @override
  ConsumerState<NowScreen> createState() => _NowScreenState();
}

class _NowScreenState extends ConsumerState<NowScreen> {
  bool _busy = false;
  Timer? _ticker;
  StreamSubscription<NotificationActionEvent>? _notificationSub;
  bool _autoEnding = false;
  bool _recovered = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_recoverOnEnter);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkAutoEndDue();
    });
    _notificationSub = NotificationService.actionEvents.listen(
      _handleNotificationEvent,
    );
    final notificationService = ref.read(notificationServiceProvider);
    final pendingLaunch = notificationService.takePendingLaunchEvent();
    if (pendingLaunch != null) {
      Future.microtask(() => _handleNotificationEvent(pendingLaunch));
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> _recoverOnEnter() async {
    if (_recovered) return;
    _recovered = true;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final engine = ref.read(blockEngineProvider);
    final state = await engine.recoverState(uid);
    if (!mounted) return;

    if (state.session != null) {
      ref.read(activeSessionProvider.notifier).setSession(state.session!);
    }
    if (state.activeBlock != null) {
      ref.read(activeBlockProvider.notifier).setBlock(state.activeBlock!);
    }

    for (final pending in state.pendingFeedback) {
      await _collectFeedbackForEndedBlock(pending);
    }
  }

  TimeFeel? _mapActionToTimeFeel(String? actionId) {
    switch (actionId) {
      case 'timefeel_short':
        return TimeFeel.short_;
      case 'timefeel_ok':
        return TimeFeel.ok;
      case 'timefeel_long':
        return TimeFeel.long_;
      default:
        return null;
    }
  }

  Future<void> _handleNotificationEvent(NotificationActionEvent event) async {
    final block = ref.read(activeBlockProvider);
    if (block == null) return;

    String? payloadBlockId;
    try {
      if (event.payload != null) {
        final json = jsonDecode(event.payload!) as Map<String, dynamic>;
        payloadBlockId = json['blockId'] as String?;
      }
    } catch (_) {}

    if (payloadBlockId != null && payloadBlockId != block.id) return;

    final engine = ref.read(blockEngineProvider);
    final ended = block.endAt == null ? await engine.endBlockAuto(block) : block;
    ref.read(activeBlockProvider.notifier).updateBlock(ended);

    final feel = _mapActionToTimeFeel(event.actionId);
    await _collectFeedbackForEndedBlock(ended, presetTimeFeel: feel);
    await _advanceOrFinish();
  }

  Future<void> _checkAutoEndDue() async {
    if (_autoEnding || _busy) return;
    final block = ref.read(activeBlockProvider);
    if (block == null) return;
    if (block.endAt != null) return;
    if (DateTime.now().isBefore(block.plannedEndAt)) return;

    _autoEnding = true;
    try {
      final engine = ref.read(blockEngineProvider);
      final ended = await engine.endBlockAuto(block);
      ref.read(activeBlockProvider.notifier).updateBlock(ended);
      await _collectFeedbackForEndedBlock(ended);
      await _advanceOrFinish();
    } finally {
      _autoEnding = false;
    }
  }

  Future<void> _collectFeedbackForEndedBlock(
    Block ended, {
    TimeFeel? presetTimeFeel,
  }) async {
    final engine = ref.read(blockEngineProvider);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) {
        return BlockFeedbackSheet(
          blockLabel: ended.displayLabel,
          plannedMinutes: ended.plannedMinutes,
          initialTimeFeel: presetTimeFeel,
          onSubmit: (timeFeel, satisfaction) async {
            try {
              await engine.saveBlockFeedback(
                sessionId: ended.sessionId,
                blockId: ended.id,
                timeFeel: timeFeel,
                satisfaction: satisfaction,
              );
            } catch (_) {
              // 저장 실패해도 시트는 닫음 (로컬 큐에서 재시도)
            }
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  Future<void> _manualEndBlock() async {
    final block = ref.read(activeBlockProvider);
    if (block == null) return;
    setState(() => _busy = true);
    try {
      final engine = ref.read(blockEngineProvider);
      final ended = await engine.endBlockManual(block);
      ref.read(activeBlockProvider.notifier).updateBlock(ended);
      await _collectFeedbackForEndedBlock(ended);
      await _advanceOrFinish();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('블록 종료 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advanceOrFinish() async {
    final sessionAsync = ref.read(activeSessionProvider);
    final session = sessionAsync.value;
    if (session == null) return;

    final planState = ref.read(routinePlanProvider);
    final engine = ref.read(blockEngineProvider);

    if (planState.hasNext) {
      ref.read(routinePlanProvider.notifier).advance();
      final nextPreset = ref.read(routinePlanProvider).currentBlock;
      if (nextPreset == null) return;

      final started = await engine.startBlock(
        sessionId: session.id,
        preset: nextPreset,
      );
      if (started != null) {
        ref.read(activeBlockProvider.notifier).setBlock(started);
      }
      return;
    }

    await _finishSession(session.id);
  }

  Future<void> _finishSession(String sessionId) async {
    final engine = ref.read(blockEngineProvider);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return SessionFeedbackSheet(
          onSubmit: ({
            required overallSatisfaction,
            required repeatIntent,
            required energyAtStart,
          }) async {
            await engine.endSession(
              sessionId: sessionId,
              overallSatisfaction: overallSatisfaction,
              repeatIntent: repeatIntent,
              energyAtStart: energyAtStart,
            );
            ref.read(activeSessionProvider.notifier).clearSession();
            ref.read(activeBlockProvider.notifier).clearBlock();
            ref.read(routinePlanProvider.notifier).clear();
            if (context.mounted) Navigator.of(context).pop();
          },
        );
      },
    );

    if (mounted) context.go('/start');
  }

  Future<void> _endRoutineNow() async {
    final block = ref.read(activeBlockProvider);
    final session = ref.read(activeSessionProvider).value;
    if (block == null || session == null) return;

    setState(() => _busy = true);
    try {
      final engine = ref.read(blockEngineProvider);
      final ended = await engine.endBlockManual(block);
      ref.read(activeBlockProvider.notifier).updateBlock(ended);
      await _collectFeedbackForEndedBlock(ended);
      await _finishSession(session.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('루틴 종료 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = ref.watch(activeBlockProvider);
    final sessionAsync = ref.watch(activeSessionProvider);
    final planState = ref.watch(routinePlanProvider);
    final remaining = block == null
        ? Duration.zero
        : block.plannedEndAt.difference(DateTime.now());
    final totalDuration = block == null
        ? Duration.zero
        : Duration(minutes: block.plannedMinutes);
    final elapsed = totalDuration - remaining;
    final progress = totalDuration.inSeconds > 0
        ? (elapsed.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('진행 중'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: sessionAsync.when(
          data: (session) {
            if (session == null || block == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('진행 중인 루틴이 없습니다.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/start'),
                    child: const Text('Start로 이동'),
                  ),
                ],
              );
            }

            return Column(
              children: [
                const Spacer(),
                // 원형 프로그레스 + 남은 시간
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            block.displayLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateTimeUtils.formatRemainingTime(remaining),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontFeatures: [const FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            '${block.plannedMinutes}분 중',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '종료 예정 ${DateTimeUtils.formatTime(block.plannedEndAt)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                // 다음 블록 미리보기
                if (planState.hasNext) ...[
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.skip_next, color: Colors.grey),
                      title: Text(
                        '다음: ${planState.selectedBlocks[planState.currentIndex + 1].label}',
                      ),
                      subtitle: Text(
                        '${planState.selectedBlocks[planState.currentIndex + 1].defaultMinutes}분',
                      ),
                    ),
                  ),
                ] else ...[
                  const Card(
                    child: ListTile(
                      leading: Icon(Icons.flag, color: Colors.grey),
                      title: Text('마지막 블록'),
                      subtitle: Text('이 블록 후 루틴이 종료됩니다'),
                    ),
                  ),
                ],
                const Spacer(),
                // 버튼 영역
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _manualEndBlock,
                    child: const Text('현재 블록 종료'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _endRoutineNow,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                    child: const Text('루틴 종료'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('오류: $e'),
        ),
      ),
    );
  }
}
