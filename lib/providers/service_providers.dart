import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/block_engine.dart';
import '../services/firestore_service.dart';
import '../services/local_queue_service.dart';
import '../services/notification_service.dart';

/// Firebase 초기화 성공 여부
final firebaseReadyProvider = Provider<bool>((ref) {
  return true;
});

/// FirestoreService 싱글톤
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// NotificationService 싱글톤
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// LocalQueueService 싱글톤
final localQueueServiceProvider = Provider<LocalQueueService>((ref) {
  return LocalQueueService();
});

/// BlockEngine 싱글톤 (서비스 조합)
final blockEngineProvider = Provider<BlockEngine>((ref) {
  return BlockEngine(
    firestoreService: ref.watch(firestoreServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
    localQueueService: ref.watch(localQueueServiceProvider),
  );
});
