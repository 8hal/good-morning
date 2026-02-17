import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/onboarding_state.dart';
import '../models/user_settings.dart';
import 'auth_provider.dart';
import 'morning_assistant_provider.dart';
import 'service_providers.dart';
import 'settings_provider.dart';

/// 대화형 온보딩 상태 관리
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref);
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState()) {
    _initialize();
  }

  void _initialize() {
    final greeting = _greetingForTime(DateTime.now());
    state = OnboardingState(
      phase: OnboardingPhase.greeting,
      greeting: greeting,
    );
  }

  /// 마지막 세션 기반 기본 출퇴근 타입
  String get defaultCommuteType {
    final settings =
        _ref.read(settingsProvider).value ?? const UserSettings();
    return settings.defaultCommuteType.name;
  }

  /// 마지막 세션 기반 기본 앵커 타임 (비동기 조회가 필요하므로 Future)
  Future<String> getDefaultAnchorTime() async {
    final uid = _ref.read(currentUidProvider);
    if (uid != null) {
      try {
        final firestoreService = _ref.read(firestoreServiceProvider);
        final lastSession = await firestoreService.getLastSession(uid);
        if (lastSession != null) {
          return DateFormat('HH:mm').format(lastSession.anchorTime);
        }
      } catch (_) {}
    }
    return '09:00';
  }

  /// Q1: 출퇴근 타입 선택
  void selectCommuteType(String type) {
    state = state.copyWith(
      commuteType: type,
      phase: OnboardingPhase.anchorTime,
    );
  }

  /// Q2: 앵커 타임 확인 또는 변경
  void confirmAnchorTime(String time) {
    state = state.copyWith(
      anchorTime: time,
      phase: OnboardingPhase.condition,
    );
  }

  /// Q3: 컨디션 선택 → Gemini 호출 트리거
  Future<void> selectCondition(UserCondition condition) async {
    state = state.copyWith(
      condition: condition,
      phase: OnboardingPhase.loading,
    );

    await _ref
        .read(morningAssistantProvider.notifier)
        .loadSuggestionWithContext(
          commuteType: state.commuteType!,
          anchorTime: state.anchorTime!,
          condition: condition,
        );

    if (mounted) {
      state = state.copyWith(phase: OnboardingPhase.complete);
    }
  }

  /// 온보딩 리셋 (새로운 세션 시작 시)
  void reset() {
    _initialize();
  }

  String _greetingForTime(DateTime now) {
    final hour = now.hour;
    if (hour < 6) return '이른 새벽이네요!\n오늘 하루를 준비해볼까요?';
    if (hour < 9) return '좋은 아침이에요!\n오늘 하루를 준비해볼까요?';
    if (hour < 11) return '늦은 아침이지만 괜찮아요!\n오늘 하루를 준비해볼까요?';
    return '좋은 하루 보내세요!\n오늘의 루틴을 준비해볼까요?';
  }
}
