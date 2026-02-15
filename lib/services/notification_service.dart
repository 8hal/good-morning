import 'dart:convert';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';

class NotificationActionEvent {
  final String? actionId;
  final String? payload;
  final bool isTap;

  const NotificationActionEvent({
    required this.actionId,
    required this.payload,
    required this.isTap,
  });
}

/// 알림 서비스
/// 블록 종료 알림 예약/취소/액션 처리
///
/// 알림 전략:
/// - 포그라운드: 알림 대신 인앱 BottomSheet 사용
/// - 백그라운드: 시스템 알림 → 탭 시 앱 실행 → 인앱 피드백
/// - Android: 알림에 timeFeel 액션 버튼 3개 표시
/// - iOS: 알림 탭 → 앱 열림 → 인앱 피드백 시트
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  static final StreamController<NotificationActionEvent> _eventController =
      StreamController<NotificationActionEvent>.broadcast();
  static NotificationActionEvent? _pendingLaunchEvent;

  static Stream<NotificationActionEvent> get actionEvents =>
      _eventController.stream;

  /// 알림 액션 콜백 (외부에서 주입)
  void Function(String? payload)? onNotificationTapped;
  void Function(String actionId, String? payload)? onActionSelected;

  NotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// 초기화
  Future<void> initialize() async {
    // Android 설정
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // iOS 설정
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          AppConstants.blockEndCategoryId,
          actions: [
            DarwinNotificationAction.plain('timefeel_short', '짧았다'),
            DarwinNotificationAction.plain('timefeel_ok', '적당'),
            DarwinNotificationAction.plain('timefeel_long', '길었다'),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _handleBackgroundNotificationResponse,
    );

    // 알림 탭으로 앱이 시작된 경우 처리
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchResponse != null) {
      _handleNotificationResponse(launchResponse);
    }
  }

  NotificationActionEvent? takePendingLaunchEvent() {
    final event = _pendingLaunchEvent;
    _pendingLaunchEvent = null;
    return event;
  }

  /// 알림 권한 요청
  Future<bool> requestPermission() async {
    // Android 13+ 권한 요청
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS 권한 요청
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// 블록 종료 알림 예약
  Future<void> scheduleBlockEndNotification({
    required String blockId,
    required String sessionId,
    required String blockType,
    required int plannedMinutes,
    required DateTime scheduledAt,
  }) async {
    final notificationId = blockId.hashCode.abs();
    final payload = jsonEncode({
      'blockId': blockId,
      'sessionId': sessionId,
      'type': 'block_end',
    });

    // Android 알림 상세
    const androidDetails = AndroidNotificationDetails(
      AppConstants.blockEndChannelId,
      AppConstants.blockEndChannelName,
      channelDescription: AppConstants.blockEndChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('timefeel_short', '짧았다'),
        AndroidNotificationAction('timefeel_ok', '적당'),
        AndroidNotificationAction('timefeel_long', '길었다'),
      ],
    );

    // iOS 알림 상세
    const iosDetails = DarwinNotificationDetails(
      categoryIdentifier: AppConstants.blockEndCategoryId,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);

    await _plugin.zonedSchedule(
      notificationId,
      '블록 종료',
      '$blockType ${plannedMinutes}분 완료',
      tzScheduledAt,
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// 블록 종료 알림 취소
  Future<void> cancelBlockEndNotification(String blockId) async {
    await _plugin.cancel(blockId.hashCode.abs());
  }

  /// 모든 알림 취소
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// 알림 응답 처리 (포그라운드/백그라운드)
  void _handleNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId != null && actionId.isNotEmpty) {
      // 액션 버튼 클릭 (Android timeFeel)
      onActionSelected?.call(actionId, payload);
      final event = NotificationActionEvent(
        actionId: actionId,
        payload: payload,
        isTap: false,
      );
      _pendingLaunchEvent = event;
      _eventController.add(event);
    } else {
      // 알림 본문 탭
      onNotificationTapped?.call(payload);
      final event = NotificationActionEvent(
        actionId: null,
        payload: payload,
        isTap: true,
      );
      _pendingLaunchEvent = event;
      _eventController.add(event);
    }
  }
}

/// 백그라운드 알림 핸들러 (top-level function 필수)
@pragma('vm:entry-point')
void _handleBackgroundNotificationResponse(NotificationResponse response) {
  // 백그라운드에서는 로컬 큐에 저장 후 앱 실행 시 처리
  // v0.1: 최소 구현 — 앱 실행 시 pendingFeedbackCheck에서 처리
}
