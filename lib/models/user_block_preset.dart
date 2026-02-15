import 'package:cloud_firestore/cloud_firestore.dart';
import 'block_preset.dart';

/// 사용자 정의 블록 프리셋
/// Firestore: users/{uid}/blockPresets/{id}
class UserBlockPreset {
  final String id; // Firestore 문서 ID
  final String name; // 블록 이름 (예: "명상", "샤워")
  final int minutes; // 기본 시간 (분)
  final int order; // 정렬 순서 (0부터 시작, 작을수록 위)
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBlockPreset({
    required this.id,
    required this.name,
    required this.minutes,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  /// BlockPreset으로 변환 (실행 시 사용)
  BlockPreset toBlockPreset() {
    return BlockPreset(
      blockType: 'free', // 사용자 정의는 모두 free
      defaultMinutes: minutes,
      label: name,
    );
  }

  /// Firestore → Dart
  factory UserBlockPreset.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBlockPreset(
      id: doc.id,
      name: data['name'] as String,
      minutes: data['minutes'] as int,
      order: data['order'] as int,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Dart → Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'minutes': minutes,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// copyWith
  UserBlockPreset copyWith({
    String? id,
    String? name,
    int? minutes,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserBlockPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      minutes: minutes ?? this.minutes,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
