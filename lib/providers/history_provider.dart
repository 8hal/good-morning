import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// 과거 세션 히스토리
/// 중립성 원칙: 날짜 + commuteType만 표시. 점수 평균/분석 금지.
final historyProvider =
    FutureProvider<List<Session>>((ref) async {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return [];

  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getSessionHistory(uid);
});
