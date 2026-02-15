import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

/// 사용자 설정
class UserSettings {
  final int officeCommuteMinutes; // 출근 소요 시간 (기본 60분)
  final CommuteType defaultCommuteType;
  final bool calendarEnabled; // v0.1.5
  final DateTime? createdAt;

  const UserSettings({
    this.officeCommuteMinutes = 60,
    this.defaultCommuteType = CommuteType.office,
    this.calendarEnabled = false,
    this.createdAt,
  });

  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const UserSettings();

    final settings = data['settings'] as Map<String, dynamic>? ?? {};
    return UserSettings(
      officeCommuteMinutes: settings['officeCommuteMinutes'] as int? ?? 60,
      defaultCommuteType: settings['defaultCommuteType'] != null
          ? CommuteType.fromJson(settings['defaultCommuteType'] as String)
          : CommuteType.office,
      calendarEnabled: settings['calendarEnabled'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'settings': {
        'officeCommuteMinutes': officeCommuteMinutes,
        'defaultCommuteType': defaultCommuteType.toJson(),
        'calendarEnabled': calendarEnabled,
      },
    };
  }

  UserSettings copyWith({
    int? officeCommuteMinutes,
    CommuteType? defaultCommuteType,
    bool? calendarEnabled,
  }) {
    return UserSettings(
      officeCommuteMinutes:
          officeCommuteMinutes ?? this.officeCommuteMinutes,
      defaultCommuteType: defaultCommuteType ?? this.defaultCommuteType,
      calendarEnabled: calendarEnabled ?? this.calendarEnabled,
      createdAt: createdAt,
    );
  }
}
