import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/block.dart';
import '../models/session.dart';
import '../models/user_settings.dart';

/// Firestore CRUD 서비스
/// 모든 쿼리는 uid 기반 필터링
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ──────────────────────────────────────────
  // User Settings
  // ──────────────────────────────────────────

  /// 사용자 설정 조회 (없으면 기본값)
  Future<UserSettings> getUserSettings(String uid) async {
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    return UserSettings.fromFirestore(doc);
  }

  /// 사용자 설정 저장/업데이트
  Future<void> saveUserSettings(String uid, UserSettings settings) async {
    await _db
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(settings.toFirestore(), SetOptions(merge: true));
  }

  // ──────────────────────────────────────────
  // Sessions
  // ──────────────────────────────────────────

  /// 세션 생성 (중복 방지: 같은 dateKey + uid의 활성 세션이 있으면 null 반환)
  Future<Session?> createSession(Session session) async {
    // 중복 체크
    final existing = await _db
        .collection(AppConstants.sessionsCollection)
        .where('uid', isEqualTo: session.uid)
        .where('dateKey', isEqualTo: session.dateKey)
        .where('endAt', isNull: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return null; // 이미 활성 세션 존재
    }

    final docRef = _db
        .collection(AppConstants.sessionsCollection)
        .doc(session.id);
    await docRef.set(session.toFirestore());
    return session;
  }

  /// 세션 업데이트 (종료, 피드백 등)
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> updates,
  ) async {
    await _db
        .collection(AppConstants.sessionsCollection)
        .doc(sessionId)
        .update(updates);
  }

  /// 세션 단건 조회 (ID 기반)
  Future<Session> getSession(String sessionId) async {
    final doc = await _db
        .collection(AppConstants.sessionsCollection)
        .doc(sessionId)
        .get();
    return Session.fromFirestore(doc);
  }

  /// 현재 활성 세션 조회 (uid + endAt == null)
  Future<Session?> getActiveSession(String uid) async {
    final snapshot = await _db
        .collection(AppConstants.sessionsCollection)
        .where('uid', isEqualTo: uid)
        .where('endAt', isNull: true)
        .orderBy('startAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Session.fromFirestore(snapshot.docs.first);
  }

  /// 마지막 완료 세션 조회 (AI 컨텍스트용)
  Future<Session?> getLastSession(String uid) async {
    final snapshot = await _db
        .collection(AppConstants.sessionsCollection)
        .where('uid', isEqualTo: uid)
        .where('endAt', isNull: false)
        .orderBy('startAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Session.fromFirestore(snapshot.docs.first);
  }

  /// 과거 세션 목록 조회 (최신순, 페이지네이션 가능)
  Future<List<Session>> getSessionHistory(
    String uid, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _db
        .collection(AppConstants.sessionsCollection)
        .where('uid', isEqualTo: uid)
        .where('endAt', isNull: false)
        .orderBy('startAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Session.fromFirestore(doc)).toList();
  }

  // ──────────────────────────────────────────
  // Blocks (subcollection of sessions)
  // ──────────────────────────────────────────

  /// 블록 생성 (중복 방지: 세션 내 활성 블록이 있으면 null 반환)
  Future<Block?> createBlock(Block block) async {
    // 중복 체크
    final existing = await _db
        .collection(AppConstants.sessionsCollection)
        .doc(block.sessionId)
        .collection(AppConstants.blocksSubcollection)
        .where('endAt', isNull: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return null; // 이미 활성 블록 존재
    }

    final docRef = _db
        .collection(AppConstants.sessionsCollection)
        .doc(block.sessionId)
        .collection(AppConstants.blocksSubcollection)
        .doc(block.id);
    await docRef.set(block.toFirestore());
    return block;
  }

  /// 블록 업데이트 (종료, 피드백 등)
  Future<void> updateBlock(
    String sessionId,
    String blockId,
    Map<String, dynamic> updates,
  ) async {
    await _db
        .collection(AppConstants.sessionsCollection)
        .doc(sessionId)
        .collection(AppConstants.blocksSubcollection)
        .doc(blockId)
        .update(updates);
  }

  /// 세션의 모든 블록 조회 (시작 시간순)
  Future<List<Block>> getBlocks(String sessionId) async {
    final snapshot = await _db
        .collection(AppConstants.sessionsCollection)
        .doc(sessionId)
        .collection(AppConstants.blocksSubcollection)
        .orderBy('startAt')
        .get();

    return snapshot.docs
        .map((doc) => Block.fromFirestore(doc, sessionId))
        .toList();
  }

  /// 현재 활성 블록 조회
  Future<Block?> getActiveBlock(String sessionId) async {
    final snapshot = await _db
        .collection(AppConstants.sessionsCollection)
        .doc(sessionId)
        .collection(AppConstants.blocksSubcollection)
        .where('endAt', isNull: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Block.fromFirestore(snapshot.docs.first, sessionId);
  }

  /// 미수집 피드백 블록 조회 (endAt != null, timeFeel == null)
  Future<List<Block>> getPendingFeedbackBlocks(String sessionId) async {
    final allBlocks = await getBlocks(sessionId);
    return allBlocks.where((b) => b.isPendingFeedback).toList();
  }
}
