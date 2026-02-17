import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/datetime_utils.dart';
import '../models/block.dart';
import '../models/enums.dart';
import '../models/session.dart';

/// 시딩 결과
class SeedResult {
  final int successCount;
  final int totalCount;
  final List<String> logs;
  final String? error;
  final String? stackTrace;

  const SeedResult({
    required this.successCount,
    required this.totalCount,
    required this.logs,
    this.error,
    this.stackTrace,
  });

  bool get hasError => error != null;
  bool get isFullSuccess => successCount == totalCount && !hasError;
}

/// 개발용 테스트 데이터 시딩
/// Settings 화면에서 호출
class SeedTestData {
  static const _uuid = Uuid();
  static final _db = FirebaseFirestore.instance;

  static void _log(List<String> logs, String message) {
    logs.add(message);
    debugPrint('[SEED] $message');
  }

  /// 최근 5일치 세션 + 블록 생성 (단계별 로깅 포함)
  static Future<SeedResult> seed(String uid) async {
    final logs = <String>[];
    var successCount = 0;

    try {
      _log(logs, '시작 — uid: $uid');

      // Firestore 연결 확인
      _log(logs, 'Firestore 연결 확인 중...');
      try {
        await _db.collection(AppConstants.sessionsCollection).limit(1).get();
        _log(logs, 'Firestore 연결 OK');
      } catch (e) {
        _log(logs, 'Firestore 연결 실패: $e');
        return SeedResult(
          successCount: 0,
          totalCount: 5,
          logs: logs,
          error: 'Firestore 연결 실패: $e',
        );
      }

      final now = DateTime.now();
      _log(logs, '현재 시각: $now');

      final sessionsData = _buildTestSessions();
      _log(logs, '시드 데이터 ${sessionsData.length}개 세션 준비 완료');

      for (var i = 0; i < sessionsData.length; i++) {
        final seed = sessionsData[i];
        final label = '세션 ${i + 1}/${sessionsData.length} '
            '(${seed.daysAgo}일 전, ${seed.commuteType.label})';

        try {
          _log(logs, '$label 생성 시작...');

          final sessionDate = DateTime(
            now.year,
            now.month,
            now.day - seed.daysAgo,
            seed.startHour,
            seed.startMin,
          );
          final dateKey = DateTimeUtils.toDateKey(sessionDate);
          _log(logs, '  dateKey: $dateKey, startAt: $sessionDate');

          // 블록 데이터 구성
          var cursor = sessionDate;
          final blocks = <Block>[];
          for (final bs in seed.blocks) {
            final blockId = _uuid.v4();
            final blockEnd = cursor.add(
              Duration(minutes: bs.actualMin ?? bs.plannedMinutes),
            );
            blocks.add(Block(
              id: blockId,
              sessionId: '',
              blockType: bs.blockType,
              displayLabel: bs.displayLabel,
              plannedMinutes: bs.plannedMinutes,
              startAt: cursor,
              plannedEndAt: cursor.add(Duration(minutes: bs.plannedMinutes)),
              endAt: blockEnd,
              endedBy: EndedBy.auto_,
              actualMinutes: bs.actualMin,
              timeFeel: bs.timeFeel,
              satisfaction: bs.satisfaction,
            ));
            cursor = blockEnd;
          }
          _log(logs, '  블록 ${blocks.length}개 준비 (종료: $cursor)');

          // 세션 저장
          final sessionId = _uuid.v4();
          final session = Session(
            id: sessionId,
            uid: uid,
            dateKey: dateKey,
            anchorTime: sessionDate.add(const Duration(hours: 3)),
            commuteType: seed.commuteType,
            startAt: sessionDate,
            endAt: cursor,
            overallSatisfaction: seed.overallSatisfaction,
            energyAtStart: seed.energyAtStart,
            anchorSource: AnchorSource.manual,
          );

          _log(logs, '  세션 문서 저장 중... (id: ${sessionId.substring(0, 8)}...)');
          final sessionRef = _db
              .collection(AppConstants.sessionsCollection)
              .doc(sessionId);
          await sessionRef.set(session.toFirestore());
          _log(logs, '  세션 문서 저장 OK');

          // 블록 저장
          for (var j = 0; j < blocks.length; j++) {
            final block = blocks[j];
            final updatedBlock = Block(
              id: block.id,
              sessionId: sessionId,
              blockType: block.blockType,
              displayLabel: block.displayLabel,
              plannedMinutes: block.plannedMinutes,
              startAt: block.startAt,
              plannedEndAt: block.plannedEndAt,
              endAt: block.endAt,
              endedBy: block.endedBy,
              actualMinutes: block.actualMinutes,
              timeFeel: block.timeFeel,
              satisfaction: block.satisfaction,
            );
            await sessionRef
                .collection(AppConstants.blocksSubcollection)
                .doc(block.id)
                .set(updatedBlock.toFirestore());
          }
          _log(logs, '  블록 ${blocks.length}개 저장 OK');
          _log(logs, '$label 완료 ✓');
          successCount++;
        } catch (e, st) {
          _log(logs, '$label 실패 ✗: $e');
          _log(logs, '  스택: ${st.toString().split('\n').take(3).join(' → ')}');
        }
      }

      _log(logs, '완료 — $successCount/${sessionsData.length} 세션 성공');
      return SeedResult(
        successCount: successCount,
        totalCount: sessionsData.length,
        logs: logs,
      );
    } catch (e, st) {
      _log(logs, '치명적 오류: $e');
      return SeedResult(
        successCount: successCount,
        totalCount: 5,
        logs: logs,
        error: e.toString(),
        stackTrace: st.toString(),
      );
    }
  }

  static List<_SessionSeed> _buildTestSessions() {
    return const [
      // 오늘
      _SessionSeed(
        daysAgo: 0,
        commuteType: CommuteType.home,
        startHour: 6,
        startMin: 30,
        energyAtStart: 4,
        overallSatisfaction: 4,
        blocks: [
          _BlockSeed('명상', 'meditation', 15, TimeFeel.ok, 4, actualMin: 15),
          _BlockSeed('운동', 'exercise', 30, TimeFeel.long_, 3, actualMin: 35),
          _BlockSeed('샤워', 'shower', 20, TimeFeel.ok, 5, actualMin: 15),
          _BlockSeed('아침 식사', 'breakfast', 30, TimeFeel.ok, 4, actualMin: 30),
          _BlockSeed('뉴스 확인', 'news', 20, TimeFeel.long_, 3, actualMin: 25),
        ],
      ),
      // 어제
      _SessionSeed(
        daysAgo: 1,
        commuteType: CommuteType.office,
        startHour: 7,
        startMin: 0,
        energyAtStart: 3,
        overallSatisfaction: 3,
        blocks: [
          _BlockSeed('운동', 'exercise', 30, TimeFeel.ok, 4, actualMin: 30),
          _BlockSeed('샤워', 'shower', 20, TimeFeel.short_, 4, actualMin: 18),
          _BlockSeed('아침 식사', 'breakfast', 25, TimeFeel.ok, 3, actualMin: 25),
          _BlockSeed('출근 준비', 'prepare', 30, TimeFeel.long_, 3, actualMin: 40),
          _BlockSeed('영어 공부', 'english', 20, TimeFeel.ok, 4, actualMin: 20),
          _BlockSeed('뉴스 확인', 'news', 15, null, null, actualMin: 15),
        ],
      ),
      // 2일 전
      _SessionSeed(
        daysAgo: 2,
        commuteType: CommuteType.home,
        startHour: 6,
        startMin: 45,
        energyAtStart: 5,
        overallSatisfaction: 5,
        blocks: [
          _BlockSeed('명상', 'meditation', 20, TimeFeel.ok, 5, actualMin: 20),
          _BlockSeed('운동', 'exercise', 40, TimeFeel.ok, 5, actualMin: 40),
          _BlockSeed('샤워', 'shower', 15, TimeFeel.ok, 4, actualMin: 15),
          _BlockSeed('독서', 'reading', 30, TimeFeel.short_, 5, actualMin: 25),
          _BlockSeed('아침 식사', 'breakfast', 25, TimeFeel.ok, 4, actualMin: 25),
        ],
      ),
      // 3일 전
      _SessionSeed(
        daysAgo: 3,
        commuteType: CommuteType.office,
        startHour: 7,
        startMin: 15,
        energyAtStart: 2,
        overallSatisfaction: 2,
        blocks: [
          _BlockSeed('샤워', 'shower', 15, TimeFeel.ok, 3, actualMin: 15),
          _BlockSeed('아침 식사', 'breakfast', 20, TimeFeel.long_, 2, actualMin: 30),
          _BlockSeed('출근 준비', 'prepare', 30, TimeFeel.ok, 3, actualMin: 30),
        ],
      ),
      // 5일 전
      _SessionSeed(
        daysAgo: 5,
        commuteType: CommuteType.home,
        startHour: 6,
        startMin: 0,
        energyAtStart: null,
        overallSatisfaction: null,
        blocks: [
          _BlockSeed('명상', 'meditation', 15, null, null, actualMin: 15),
          _BlockSeed('운동', 'exercise', 30, null, null, actualMin: 28),
          _BlockSeed('샤워', 'shower', 20, null, null, actualMin: 20),
          _BlockSeed('아침 식사', 'breakfast', 30, null, null, actualMin: 30),
        ],
      ),
    ];
  }
}

class _SessionSeed {
  final int daysAgo;
  final CommuteType commuteType;
  final int startHour;
  final int startMin;
  final int? energyAtStart;
  final int? overallSatisfaction;
  final List<_BlockSeed> blocks;

  const _SessionSeed({
    required this.daysAgo,
    required this.commuteType,
    required this.startHour,
    required this.startMin,
    this.energyAtStart,
    this.overallSatisfaction,
    required this.blocks,
  });
}

class _BlockSeed {
  final String displayLabel;
  final String blockType;
  final int plannedMinutes;
  final TimeFeel? timeFeel;
  final int? satisfaction;
  final int? actualMin;

  const _BlockSeed(
    this.displayLabel,
    this.blockType,
    this.plannedMinutes,
    this.timeFeel,
    this.satisfaction, {
    this.actualMin,
  });
}
