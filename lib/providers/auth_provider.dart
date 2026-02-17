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
/// authStateProvider를 watch해서 로그인/로그아웃 시 자동 재계산
final currentUidProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user?.uid).value;
});
