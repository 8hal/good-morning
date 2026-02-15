/// 앱 전역 상수
class AppConstants {
  AppConstants._();

  /// 타임존: Asia/Seoul 고정
  static const String timeZone = 'Asia/Seoul';

  /// Firestore 컬렉션명
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String blocksSubcollection = 'blocks';

  /// 알림 채널 (Android)
  static const String blockEndChannelId = 'block_end';
  static const String blockEndChannelName = '블록 종료';
  static const String blockEndChannelDesc = '블록 종료 알림';

  /// 알림 카테고리 (iOS)
  static const String blockEndCategoryId = 'blockEndCategory';

  /// 만족도 범위
  static const int satisfactionMin = 1;
  static const int satisfactionMax = 5;

  /// 에너지 범위
  static const int energyMin = 1;
  static const int energyMax = 5;

  /// overall 범위
  static const int overallMin = 1;
  static const int overallMax = 5;
}
