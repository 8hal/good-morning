import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'firebase_options.dart';
import 'providers/service_providers.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseReady = true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase 초기화 실패: $e');
    firebaseReady = false;
  }

  // 타임존 초기화 (Asia/Seoul)
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  // 알림 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermission();

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
        firebaseReadyProvider.overrideWithValue(firebaseReady),
      ],
      child: const GoodMorningApp(),
    ),
  );
}
