import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth 래퍼
/// 개인 앱이므로 익명 인증만 사용 (v0.1)
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// 현재 사용자
  User? get currentUser => _auth.currentUser;

  /// 현재 uid (null 가능)
  String? get uid => _auth.currentUser?.uid;

  /// 인증 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// 익명 로그인 (자동, 앱 시작 시 호출)
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  /// 로그아웃 (개인 앱이므로 거의 사용 안 함)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
