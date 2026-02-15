import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

/// AuthService 싱글톤 프로바이더
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Firebase Auth 상태 스트림
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// 현재 uid (로그인 안 됐으면 null)
/// Google Sign-In 초기화를 피하기 위해 FirebaseAuth만 사용
final currentUidProvider = Provider<String?>((ref) {
  return FirebaseAuth.instance.currentUser?.uid;
});
