import 'package:intl/intl.dart';

/// Asia/Seoul 타임존 고정 유틸리티
class DateTimeUtils {
  DateTimeUtils._();

  /// 오늘 날짜 키 (예: "2026-02-11")
  static String todayDateKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// DateTime → dateKey 문자열
  static String toDateKey(DateTime dt) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  /// 시:분 포맷 (예: "08:30")
  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  /// 날짜 포맷 (예: "2월 11일 (화)")
  static String formatDate(DateTime dt) {
    return DateFormat('M월 d일 (E)', 'ko_KR').format(dt);
  }

  /// 남은 시간을 mm:ss 형식으로
  static String formatRemainingTime(Duration remaining) {
    if (remaining.isNegative) return '00:00';
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 분 → Duration
  static Duration minutesToDuration(int minutes) {
    return Duration(minutes: minutes);
  }

  /// 두 DateTime 사이의 분 차이 (반올림)
  static int minutesBetween(DateTime start, DateTime end) {
    return end.difference(start).inMinutes;
  }
}
