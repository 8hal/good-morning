import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/datetime_utils.dart';
import '../models/block.dart';
import '../models/enums.dart';
import '../models/session.dart';

/// 개발용 테스트 데이터 시딩
/// Settings 화면에서 호출
class SeedTestData {
  static const _uuid = Uuid();
  static final _db = FirebaseFirestore.instance;

  /// 최근 5일치 세션 + 블록 생성
  static Future<int> seed(String uid) async {
    final now = DateTime.now();
    var createdCount = 0;

    final sessionsData = [
      // 오늘
      const _SessionSeed(
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
      const _SessionSeed(
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
      const _SessionSeed(
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
      const _SessionSeed(
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
      const _SessionSeed(
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

    for (final seed in sessionsData) {
      final sessionDate = DateTime(
        now.year, now.month, now.day - seed.daysAgo,
        seed.startHour, seed.startMin,
      );
      final dateKey = DateTimeUtils.toDateKey(sessionDate);

      // 세션 종료 시간 계산 (블록 합산)
      var cursor = sessionDate;
      final blocks = <Block>[];
      for (final bs in seed.blocks) {
        final blockId = _uuid.v4();
        final blockEnd = cursor.add(Duration(minutes: bs.actualMin ?? bs.plannedMinutes));
        blocks.add(Block(
          id: blockId,
          sessionId: '', // 아래에서 설정
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

      // Firestore에 저장
      final sessionRef = _db
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId);
      await sessionRef.set(session.toFirestore());

      for (final block in blocks) {
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

      createdCount++;
    }

    return createdCount;
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
