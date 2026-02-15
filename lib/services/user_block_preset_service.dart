import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_block_preset.dart';

/// 사용자 정의 블록 프리셋 CRUD
class UserBlockPresetService {
  final FirebaseFirestore _firestore;

  UserBlockPresetService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 사용자 블록 컬렉션 참조
  CollectionReference _userPresetsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('blockPresets');
  }

  /// 블록 목록 조회 (order 순으로 정렬)
  Stream<List<UserBlockPreset>> watchUserPresets(String uid) {
    return _userPresetsCollection(uid)
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserBlockPreset.fromFirestore(doc))
          .toList();
    });
  }

  /// 블록 생성
  Future<UserBlockPreset> createPreset({
    required String uid,
    required String name,
    required int minutes,
  }) async {
    final now = DateTime.now();

    // 현재 최대 order 값 가져오기
    final snapshot = await _userPresetsCollection(uid)
        .orderBy('order', descending: true)
        .limit(1)
        .get();

    final maxOrder = snapshot.docs.isEmpty
        ? -1
        : (snapshot.docs.first.data() as Map<String, dynamic>)['order'] as int;

    final docRef = _userPresetsCollection(uid).doc();
    final preset = UserBlockPreset(
      id: docRef.id,
      name: name,
      minutes: minutes,
      order: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(preset.toFirestore());
    return preset;
  }

  /// 블록 수정
  Future<void> updatePreset({
    required String uid,
    required String presetId,
    String? name,
    int? minutes,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.now(),
    };
    if (name != null) updates['name'] = name;
    if (minutes != null) updates['minutes'] = minutes;

    await _userPresetsCollection(uid).doc(presetId).update(updates);
  }

  /// 블록 삭제
  Future<void> deletePreset({
    required String uid,
    required String presetId,
  }) async {
    await _userPresetsCollection(uid).doc(presetId).delete();
  }

  /// 순서 변경 (드래그 앤 드롭 후 호출)
  /// newOrder: 이동할 새 위치 (0부터 시작)
  Future<void> reorderPreset({
    required String uid,
    required String presetId,
    required int newOrder,
  }) async {
    final batch = _firestore.batch();
    final collection = _userPresetsCollection(uid);

    // 1. 모든 블록 가져오기
    final snapshot = await collection.orderBy('order').get();
    final presets = snapshot.docs
        .map((doc) => UserBlockPreset.fromFirestore(doc))
        .toList();

    // 2. 이동할 블록 찾기
    final targetIndex = presets.indexWhere((p) => p.id == presetId);
    if (targetIndex == -1) return;

    final target = presets.removeAt(targetIndex);
    presets.insert(newOrder, target);

    // 3. 모든 블록의 order 재설정
    for (int i = 0; i < presets.length; i++) {
      batch.update(
        collection.doc(presets[i].id),
        {'order': i, 'updatedAt': Timestamp.now()},
      );
    }

    await batch.commit();
  }
}
