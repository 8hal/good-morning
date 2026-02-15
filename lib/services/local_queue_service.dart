import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 로컬 큐 서비스 (v0.1 최소 구현)
///
/// Firestore 저장 실패 시 큐에 적재하고 앱 실행 시 재시도합니다.
/// SharedPreferences에 저장하여 앱 재시작 후에도 유지됩니다.
class LocalQueueService {
  static const String _storageKey = 'good_morning.local_queue.v1';
  final List<QueueItem> _queue = [];
  late final Future<void> _initFuture;

  LocalQueueService() {
    _initFuture = _loadFromStorage();
  }

  Future<void> _ensureReady() async {
    await _initFuture;
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _queue
        ..clear()
        ..addAll(decoded.map((e) => QueueItem.fromJson(e as Map<String, dynamic>)));
    } catch (_) {
      _queue.clear();
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_queue.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  /// 큐에 작업 추가
  Future<void> enqueue({
    required String operation, // 'updateBlock', 'updateSession' 등
    required Map<String, dynamic> data,
  }) async {
    await _ensureReady();
    _queue.add(
      QueueItem(
        operation: operation,
        data: data,
        createdAtIso: DateTime.now().toIso8601String(),
        retryCount: 0,
      ),
    );
    await _saveToStorage();
  }

  /// 큐에 대기 중인 작업 수
  Future<int> pendingCount() async {
    await _ensureReady();
    return _queue.length;
  }

  /// 큐가 비어있는지
  Future<bool> isEmpty() async {
    await _ensureReady();
    return _queue.isEmpty;
  }

  /// 대기 중인 작업 반환 (FIFO)
  Future<List<QueueItem>> pendingItems() async {
    await _ensureReady();
    return List.unmodifiable(_queue);
  }

  /// 모든 대기 작업 재시도
  /// 반환: 실패한 작업 수
  Future<int> retryAll(
    Future<bool> Function(String operation, Map<String, dynamic> data)
        executor,
  ) async {
    await _ensureReady();
    final items = List<QueueItem>.from(_queue);
    int failCount = 0;

    for (final item in items) {
      try {
        final success = await executor(item.operation, item.data);
        if (success) {
          _queue.remove(item);
        } else {
          item.retryCount++;
          failCount++;
        }
      } catch (_) {
        item.retryCount++;
        failCount++;
      }
    }

    await _saveToStorage();
    return failCount;
  }

  /// 큐 초기화
  Future<void> clear() async {
    await _ensureReady();
    _queue.clear();
    await _saveToStorage();
  }
}

class QueueItem {
  final String operation;
  final Map<String, dynamic> data;
  final String createdAtIso;
  int retryCount;

  QueueItem({
    required this.operation,
    required this.data,
    required this.createdAtIso,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'data': data,
      'createdAtIso': createdAtIso,
      'retryCount': retryCount,
    };
  }

  factory QueueItem.fromJson(Map<String, dynamic> json) {
    return QueueItem(
      operation: json['operation'] as String,
      data: Map<String, dynamic>.from(json['data'] as Map),
      createdAtIso: json['createdAtIso'] as String,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}
