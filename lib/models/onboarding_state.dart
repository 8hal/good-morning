/// 대화형 온보딩의 진행 단계
enum OnboardingPhase {
  greeting, // 인사 + Q1 (출퇴근) 표시
  anchorTime, // Q2 (앵커 타임) 표시
  condition, // Q3 (컨디션) 표시
  loading, // Gemini 호출 중
  complete, // 루틴 제안 표시 (Phase 2)
}

/// 사용자 컨디션
enum UserCondition {
  good, // 좋음 😊
  normal, // 보통 😐
  tired; // 피곤 😴

  String get label {
    switch (this) {
      case UserCondition.good:
        return '😊 좋음';
      case UserCondition.normal:
        return '😐 보통';
      case UserCondition.tired:
        return '😴 피곤';
    }
  }

  String get emoji {
    switch (this) {
      case UserCondition.good:
        return '😊';
      case UserCondition.normal:
        return '😐';
      case UserCondition.tired:
        return '😴';
    }
  }
}

/// 대화형 온보딩의 상태를 관리하는 모델
class OnboardingState {
  final OnboardingPhase phase;
  final String? commuteType; // "office" | "home" | null
  final String? anchorTime; // "HH:mm" | null
  final UserCondition? condition;
  final String greeting;

  const OnboardingState({
    this.phase = OnboardingPhase.greeting,
    this.commuteType,
    this.anchorTime,
    this.condition,
    this.greeting = '',
  });

  OnboardingState copyWith({
    OnboardingPhase? phase,
    String? commuteType,
    String? anchorTime,
    UserCondition? condition,
    String? greeting,
  }) {
    return OnboardingState(
      phase: phase ?? this.phase,
      commuteType: commuteType ?? this.commuteType,
      anchorTime: anchorTime ?? this.anchorTime,
      condition: condition ?? this.condition,
      greeting: greeting ?? this.greeting,
    );
  }
}
