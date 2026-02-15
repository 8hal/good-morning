import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// 아침 루틴의 활동 블록 (세션의 하위 문서)
class Block {
  final String id;
  final String sessionId;
  final String blockType;
  final int plannedMinutes;
  final DateTime startAt;
  final DateTime plannedEndAt;
  final DateTime? endAt;
  final EndedBy? endedBy;
  final int? actualMinutes;
  final TimeFeel? timeFeel;
  final int? satisfaction; // 1~5

  const Block({
    required this.id,
    required this.sessionId,
    required this.blockType,
    required this.plannedMinutes,
    required this.startAt,
    required this.plannedEndAt,
    this.endAt,
    this.endedBy,
    this.actualMinutes,
    this.timeFeel,
    this.satisfaction,
  });

  /// 블록이 진행 중인지
  bool get isActive => endAt == null;

  /// 피드백이 수집되었는지
  bool get hasFeedback => timeFeel != null && satisfaction != null;

  /// 피드백이 미수집인 종료된 블록인지
  bool get isPendingFeedback => endAt != null && !hasFeedback;

  /// Firestore 문서 → Block
  factory Block.fromFirestore(DocumentSnapshot doc, String sessionId) {
    final data = doc.data() as Map<String, dynamic>;
    return Block(
      id: doc.id,
      sessionId: sessionId,
      blockType: data['blockType'] as String,
      plannedMinutes: data['plannedMinutes'] as int,
      startAt: (data['startAt'] as Timestamp).toDate(),
      plannedEndAt: (data['plannedEndAt'] as Timestamp).toDate(),
      endAt: data['endAt'] != null
          ? (data['endAt'] as Timestamp).toDate()
          : null,
      endedBy: data['endedBy'] != null
          ? EndedBy.fromJson(data['endedBy'] as String)
          : null,
      actualMinutes: data['actualMinutes'] as int?,
      timeFeel: data['timeFeel'] != null
          ? TimeFeel.fromJson(data['timeFeel'] as String)
          : null,
      satisfaction: data['satisfaction'] as int?,
    );
  }

  /// Block → Firestore 문서
  Map<String, dynamic> toFirestore() {
    return {
      'blockType': blockType,
      'plannedMinutes': plannedMinutes,
      'startAt': Timestamp.fromDate(startAt),
      'plannedEndAt': Timestamp.fromDate(plannedEndAt),
      'endAt': endAt != null ? Timestamp.fromDate(endAt!) : null,
      'endedBy': endedBy?.toJson(),
      'actualMinutes': actualMinutes,
      'timeFeel': timeFeel?.toJson(),
      'satisfaction': satisfaction,
    };
  }

  /// 불변 복사 (업데이트용)
  Block copyWith({
    DateTime? endAt,
    EndedBy? endedBy,
    int? actualMinutes,
    TimeFeel? timeFeel,
    int? satisfaction,
  }) {
    return Block(
      id: id,
      sessionId: sessionId,
      blockType: blockType,
      plannedMinutes: plannedMinutes,
      startAt: startAt,
      plannedEndAt: plannedEndAt,
      endAt: endAt ?? this.endAt,
      endedBy: endedBy ?? this.endedBy,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      timeFeel: timeFeel ?? this.timeFeel,
      satisfaction: satisfaction ?? this.satisfaction,
    );
  }
}
