import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/block.dart';
import '../models/session.dart';
import 'service_providers.dart';

/// 세션 상세 데이터 (세션 + 블록 목록)
class SessionDetail {
  final Session session;
  final List<Block> blocks;
  const SessionDetail({required this.session, required this.blocks});
}

/// 세션 ID로 상세 정보 조회 (세션 + 블록)
final sessionDetailProvider =
    FutureProvider.family<SessionDetail, String>((ref, sessionId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);

  final session = await firestoreService.getSession(sessionId);
  final blocks = await firestoreService.getBlocks(sessionId);

  return SessionDetail(session: session, blocks: blocks);
});
