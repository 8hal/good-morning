import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/utils/datetime_utils.dart';
import '../models/block.dart';
import '../models/block_preset.dart';
import '../models/enums.dart';
import '../models/session.dart';
import 'firestore_service.dart';
import 'local_queue_service.dart';
import 'notification_service.dart';

/// 블록 엔진: 세션/블록의 라이프사이클을 관리하는 오케스트레이터
///
/// 책임:
/// - 세션 시작/종료
/// - 블록 시작/종료(자동/수동)
/// - 알림 예약/취소
/// - 다음 블록 전환
class BlockEngine {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  final LocalQueueService _localQueueService;
  final Uuid _uuid;

  BlockEngine({
    required FirestoreService firestoreService,
    required NotificationService notificationService,
    required LocalQueueService localQueueService,
    Uuid? uuid,
  })  : _firestoreService = firestoreService,
        _notificationService = notificationService,
        _localQueueService = localQueueService,
        _uuid = uuid ?? const Uuid();

  // ──────────────────────────────────────────
  // Session Lifecycle
  // ──────────────────────────────────────────

  /// 세션 시작
  /// 반환: 생성된 Session (중복이면 null)
  Future<Session?> startSession({
    required String uid,
    required DateTime anchorTime,
    required CommuteType commuteType,
    required AnchorSource anchorSource,
  }) async {
    final now = DateTime.now();
    final session = Session(
      id: _uuid.v4(),
      uid: uid,
      dateKey: DateTimeUtils.toDateKey(now),
      anchorTime: anchorTime,
      commuteType: commuteType,
      startAt: now,
      anchorSource: anchorSource,
    );

    return await _firestoreService.createSession(session);
  }

  /// 세션 종료 + 종합 피드백 저장
  Future<void> endSession({
    required String sessionId,
    required int overallSatisfaction,
    required bool repeatIntent,
    required int energyAtStart,
  }) async {
    final updates = {
      'endAt': Timestamp.fromDate(DateTime.now()),
      'overallSatisfaction': overallSatisfaction,
      'repeatIntent': repeatIntent,
      'energyAtStart': energyAtStart,
    };
    try {
      await _firestoreService.updateSession(sessionId, updates);
    } catch (_) {
      await _localQueueService.enqueue(
        operation: 'updateSession',
        data: {
          'sessionId': sessionId,
          'updates': {
            'overallSatisfaction': overallSatisfaction,
            'repeatIntent': repeatIntent,
            'energyAtStart': energyAtStart,
            'endAtIso': DateTime.now().toIso8601String(),
          },
        },
      );
    }

    // 남은 알림 모두 취소
    await _notificationService.cancelAll();
  }

  // ──────────────────────────────────────────
  // Block Lifecycle
  // ──────────────────────────────────────────

  /// 블록 시작
  /// 1. Block 문서 생성
  /// 2. 알림 예약
  /// 반환: 생성된 Block (중복이면 null)
  Future<Block?> startBlock({
    required String sessionId,
    required BlockPreset preset,
  }) async {
    final now = DateTime.now();
    final plannedEndAt = now.add(Duration(minutes: preset.defaultMinutes));

    final block = Block(
      id: _uuid.v4(),
      sessionId: sessionId,
      blockType: preset.blockType,
      displayLabel: preset.label,
      plannedMinutes: preset.defaultMinutes,
      startAt: now,
      plannedEndAt: plannedEndAt,
    );

    final created = await _firestoreService.createBlock(block);
    if (created == null) return null;

    // 알림 예약
    await _notificationService.scheduleBlockEndNotification(
      blockId: block.id,
      sessionId: sessionId,
      blockType: preset.label,
      plannedMinutes: preset.defaultMinutes,
      scheduledAt: plannedEndAt,
    );

    return created;
  }

  /// 블록 자동 종료 (타이머 만료)
  /// 피드백은 별도로 수집 (UI에서 처리)
  Future<Block> endBlockAuto(Block block) async {
    final updates = {
      'endAt': Timestamp.fromDate(block.plannedEndAt),
      'endedBy': EndedBy.auto_.toJson(),
      'actualMinutes': block.plannedMinutes,
    };

    try {
      await _firestoreService.updateBlock(
        block.sessionId,
        block.id,
        updates,
      );
    } catch (_) {
      await _localQueueService.enqueue(
        operation: 'updateBlock',
        data: {
          'sessionId': block.sessionId,
          'blockId': block.id,
          'updates': {
            'endAtIso': block.plannedEndAt.toIso8601String(),
            'endedBy': EndedBy.auto_.toJson(),
            'actualMinutes': block.plannedMinutes,
          },
        },
      );
    }

    return block.copyWith(
      endAt: block.plannedEndAt,
      endedBy: EndedBy.auto_,
      actualMinutes: block.plannedMinutes,
    );
  }

  /// 블록 수동 종료
  /// 1. 예약 알림 취소
  /// 2. Block 문서 업데이트
  /// 피드백은 별도로 수집 (UI에서 처리)
  Future<Block> endBlockManual(Block block) async {
    // 알림 취소
    await _notificationService.cancelBlockEndNotification(block.id);

    final now = DateTime.now();
    final actualMinutes = DateTimeUtils.minutesBetween(block.startAt, now);

    final updates = {
      'endAt': Timestamp.fromDate(now),
      'endedBy': EndedBy.manual.toJson(),
      'actualMinutes': actualMinutes,
    };

    try {
      await _firestoreService.updateBlock(
        block.sessionId,
        block.id,
        updates,
      );
    } catch (_) {
      await _localQueueService.enqueue(
        operation: 'updateBlock',
        data: {
          'sessionId': block.sessionId,
          'blockId': block.id,
          'updates': {
            'endAtIso': now.toIso8601String(),
            'endedBy': EndedBy.manual.toJson(),
            'actualMinutes': actualMinutes,
          },
        },
      );
    }

    return block.copyWith(
      endAt: now,
      endedBy: EndedBy.manual,
      actualMinutes: actualMinutes,
    );
  }

  /// 블록 피드백 저장
  /// 중복 방지: Firestore에서 기존 피드백 존재 여부를 직접 확인
  Future<void> saveBlockFeedback({
    required String sessionId,
    required String blockId,
    required TimeFeel timeFeel,
    required int satisfaction,
  }) async {
    // Firestore에서 기존 피드백 확인
    final blocks = await _firestoreService.getBlocks(sessionId);
    final block = blocks.where((b) => b.id == blockId).firstOrNull;
    if (block == null) return; // 블록이 존재하지 않으면 무시
    if (block.hasFeedback) return;

    final updates = {
      'timeFeel': timeFeel.toJson(),
      'satisfaction': satisfaction,
    };
    try {
      await _firestoreService.updateBlock(sessionId, blockId, updates);
    } catch (_) {
      await _localQueueService.enqueue(
        operation: 'updateBlock',
        data: {
          'sessionId': sessionId,
          'blockId': blockId,
          'updates': updates,
        },
      );
    }
  }

  // ──────────────────────────────────────────
  // Recovery
  // ──────────────────────────────────────────

  /// 미수집 피드백 블록 조회
  Future<List<Block>> getPendingFeedbackBlocks(String sessionId) async {
    return await _firestoreService.getPendingFeedbackBlocks(sessionId);
  }

  /// 앱 재시작 시 상태 복구
  /// - 활성 세션/블록 확인
  /// - 만료된 블록 자동 종료 처리
  /// - 미수집 피드백 확인
  Future<({Session? session, Block? activeBlock, List<Block> pendingFeedback})>
      recoverState(String uid) async {
    final session = await _firestoreService.getActiveSession(uid);
    if (session == null) {
      return (session: null, activeBlock: null, pendingFeedback: <Block>[]);
    }

    final activeBlock = await _firestoreService.getActiveBlock(session.id);
    final pendingFeedback =
        await _firestoreService.getPendingFeedbackBlocks(session.id);

    // 활성 블록이 이미 만료된 경우 자동 종료 처리
    if (activeBlock != null &&
        activeBlock.plannedEndAt.isBefore(DateTime.now())) {
      final ended = await endBlockAuto(activeBlock);
      return (
        session: session,
        activeBlock: null,
        pendingFeedback: [...pendingFeedback, ended],
      );
    }

    return (
      session: session,
      activeBlock: activeBlock,
      pendingFeedback: pendingFeedback,
    );
  }
}
