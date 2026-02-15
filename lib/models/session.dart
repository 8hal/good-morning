import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// 하루의 아침 루틴 세션
class Session {
  final String id;
  final String uid;
  final String dateKey; // "2026-02-11"
  final DateTime anchorTime;
  final CommuteType commuteType;
  final DateTime startAt;
  final DateTime? endAt;
  final int? overallSatisfaction; // 1~5
  final bool? repeatIntent;
  final int? energyAtStart; // 1~5
  final AnchorSource anchorSource;

  const Session({
    required this.id,
    required this.uid,
    required this.dateKey,
    required this.anchorTime,
    required this.commuteType,
    required this.startAt,
    this.endAt,
    this.overallSatisfaction,
    this.repeatIntent,
    this.energyAtStart,
    required this.anchorSource,
  });

  /// 세션이 활성 상태인지 (종료되지 않음)
  bool get isActive => endAt == null;

  /// Firestore 문서 → Session
  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session(
      id: doc.id,
      uid: data['uid'] as String,
      dateKey: data['dateKey'] as String,
      anchorTime: (data['anchorTime'] as Timestamp).toDate(),
      commuteType: CommuteType.fromJson(data['commuteType'] as String),
      startAt: (data['startAt'] as Timestamp).toDate(),
      endAt: data['endAt'] != null
          ? (data['endAt'] as Timestamp).toDate()
          : null,
      overallSatisfaction: data['overallSatisfaction'] as int?,
      repeatIntent: data['repeatIntent'] as bool?,
      energyAtStart: data['energyAtStart'] as int?,
      anchorSource: AnchorSource.fromJson(data['anchorSource'] as String),
    );
  }

  /// Session → Firestore 문서
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'dateKey': dateKey,
      'anchorTime': Timestamp.fromDate(anchorTime),
      'commuteType': commuteType.toJson(),
      'startAt': Timestamp.fromDate(startAt),
      'endAt': endAt != null ? Timestamp.fromDate(endAt!) : null,
      'overallSatisfaction': overallSatisfaction,
      'repeatIntent': repeatIntent,
      'energyAtStart': energyAtStart,
      'anchorSource': anchorSource.toJson(),
    };
  }

  /// 불변 복사 (업데이트용)
  Session copyWith({
    DateTime? endAt,
    int? overallSatisfaction,
    bool? repeatIntent,
    int? energyAtStart,
  }) {
    return Session(
      id: id,
      uid: uid,
      dateKey: dateKey,
      anchorTime: anchorTime,
      commuteType: commuteType,
      startAt: startAt,
      endAt: endAt ?? this.endAt,
      overallSatisfaction: overallSatisfaction ?? this.overallSatisfaction,
      repeatIntent: repeatIntent ?? this.repeatIntent,
      energyAtStart: energyAtStart ?? this.energyAtStart,
      anchorSource: anchorSource,
    );
  }
}
