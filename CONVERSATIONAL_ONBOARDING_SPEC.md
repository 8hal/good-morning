# 대화형 온보딩 작업 지시서

> 마지막 업데이트: 2026-02-16

## 1. 현재 상태

### 1.1. 있는 것
- `MorningAssistantService`: Gemini 호출 (`generateSuggestion`, `modifySuggestion`)
- `MorningAssistantNotifier`: 상태 관리 (`AsyncValue<RoutineSuggestion>`)
- `StartScreen`: 로딩 → 즉시 `SuggestionCard` 표시
- `SuggestionCard`: 루틴 카드 (앵커, 출퇴근, 블록 체크, 시작 버튼)
- `ChatInput`: 하단 자연어 입력 (Gemini에 수정 요청)
- `RoutineSuggestion` 모델: greeting, wakeUpTime, anchorTime, commuteType, blocks, reasoning

### 1.2. 문제점
- 앱 시작 시 **즉시** Gemini 호출 → 루틴 카드가 바로 나옴
- 사용자의 **오늘 상태**(재택/출근, 시간 변경, 컨디션)를 사전 파악하지 않음
- 출퇴근 타입, 앵커 타임 등을 사용자가 **수동으로** 수정해야 하는 구조
- AI가 먼저 물어보는 "대화형 경험"이 아님

---

## 2. 목표

앱을 열면 AI가 **먼저 질문**하고, 답변을 모은 후 **맞춤형 루틴**을 제안한다.

### 대화 흐름

```
┌──────────────────────────────────────┐
│  Phase 1: 대화 (질문 2~3개)           │
│  ─────────────────────────────       │
│  AI: "좋은 아침이에요! 오늘 하루를      │
│       준비해볼까요?"                   │
│                                      │
│  Q1: 오늘은 출근인가요, 재택인가요?     │
│      [출근]  [재택]                    │
│                                      │
│  Q2: 출근 시간 10:00가 맞나요?         │
│      [맞아요]  [변경하기]              │
│                                      │
│  Q3: 오늘 컨디션은 어때요?             │
│      [좋음😊] [보통😐] [피곤😴]        │
│                                      │
│  AI: "알겠습니다! 맞춤 루틴을           │
│       준비하고 있어요..."              │
│                                      │
├──────────────────────────────────────┤
│  Phase 2: 루틴 제안 (기존과 동일)      │
│  ─────────────────────────────       │
│  [SuggestionCard 표시]                │
│  [ChatInput으로 추가 수정 가능]        │
└──────────────────────────────────────┘
```

### 핵심 원칙
1. **질문은 2~3개**로 제한 (5초 이내 완료 가능)
2. **버튼 기반**: 타이핑 없이 탭으로 응답
3. **기본값 표시**: 마지막 세션 기반 추론값을 보여주고, 맞으면 한 번에 넘기기
4. **컨디션 → 루틴 반영**: 피곤하면 가벼운 블록 위주, 좋으면 풀 루틴

---

## 3. 화면 설계

### 3.1. Phase 1: 대화 화면

화면 전체가 대화형 UI (채팅 버블 스타일이 **아님** — 카드/버튼 스타일).

```
┌──────────────────────────────────────┐
│ [Good Morning]                AppBar │
├──────────────────────────────────────┤
│                                      │
│  ┌────────────────────────────────┐  │
│  │  💬 좋은 아침이에요!            │  │
│  │     오늘 하루를 준비해볼까요?    │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  오늘은 어디서 일하시나요?       │  │
│  │                                │  │
│  │  ┌──────────┐  ┌──────────┐   │  │
│  │  │ 🏢 출근  │  │ 🏠 재택  │   │  │
│  │  └──────────┘  └──────────┘   │  │
│  └────────────────────────────────┘  │
│                                      │
│              (나머지 질문은           │
│               답변 후 순차 표시)      │
│                                      │
│                                      │
└──────────────────────────────────────┘
```

**Q1 답변 후 → Q2 표시** (애니메이션으로 나타남):

```
│  ✅ 🏠 재택 선택됨                    │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  출근 시간이 10:00 맞나요?      │  │
│  │                                │  │
│  │  ┌──────────┐  ┌──────────┐   │  │
│  │  │ 맞아요 ✓ │  │ 변경하기 │   │  │
│  │  └──────────┘  └──────────┘   │  │
│  └────────────────────────────────┘  │
```

**Q2에서 "변경하기" 선택 시** → TimePicker 표시

**Q3 (마지막 질문)**:

```
│  ✅ 🏠 재택 · 10:00                  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │  오늘 컨디션은 어떠세요?        │  │
│  │                                │  │
│  │  ┌────┐  ┌────┐  ┌────┐      │  │
│  │  │ 😊 │  │ 😐 │  │ 😴 │      │  │
│  │  │좋음 │  │보통 │  │피곤│      │  │
│  │  └────┘  └────┘  └────┘      │  │
│  └────────────────────────────────┘  │
```

**Q3 답변 후** → 로딩 상태 → Phase 2 (SuggestionCard) 표시

### 3.2. Phase 2: 루틴 제안 (기존 유지)

대화 완료 후 기존 `SuggestionCard` + `ChatInput`이 표시됨.

**변경점**:
- SuggestionCard의 `greeting`에 컨디션 반영 (예: "피곤한 아침이네요. 가볍게 시작해볼까요?")
- SuggestionCard에서 출퇴근/앵커 수정 UI는 유지 (대화 이후에도 수정 가능)

---

## 4. 데이터 설계

### 4.1. 새 모델: `OnboardingState`

```dart
/// 대화형 온보딩의 상태를 관리하는 모델
enum OnboardingPhase {
  greeting,       // 인사 + Q1 표시
  anchorTime,     // Q2 표시
  condition,      // Q3 표시
  loading,        // Gemini 호출 중
  complete,       // 루틴 제안 표시 (Phase 2)
}

enum UserCondition {
  good,     // 좋음 😊
  normal,   // 보통 😐
  tired,    // 피곤 😴
}

class OnboardingState {
  final OnboardingPhase phase;
  final String? commuteType;     // "office" | "home" | null
  final String? anchorTime;      // "HH:mm" | null
  final UserCondition? condition; // 컨디션 | null
  final String greeting;          // AI 인사 메시지

  const OnboardingState({
    this.phase = OnboardingPhase.greeting,
    this.commuteType,
    this.anchorTime,
    this.condition,
    this.greeting = '',
  });

  OnboardingState copyWith({...});
}
```

### 4.2. Gemini 프롬프트 변경

현재 `_buildContext()`에 **컨디션 정보 추가**:

```
=== 오늘의 컨텍스트 ===
현재 시각: 07:30
날짜: 2026-02-16 (일요일)

=== 사용자 입력 ===           ← 신규
출퇴근: home
앵커 타임: 10:00
컨디션: tired                 ← 신규

=== 사용자 설정 ===
출근 소요: 60분

=== 블록 프리셋 ===
- id:xxx name:명상 minutes:15
- id:yyy name:운동 minutes:30
...

=== 마지막 세션 ===
앵커 타임: 10:00
출퇴근: home
날짜: 2026-02-15
```

**시스템 프롬프트 수정사항** (`_systemPrompt`에 추가):

```
10. 컨디션이 "tired"이면:
    - 운동 블록의 시간을 줄이거나 제외 (selected: false)
    - 명상/스트레칭 등 가벼운 블록 우선
    - greeting에 "가볍게 시작해볼까요?" 같은 위로 메시지
11. 컨디션이 "good"이면:
    - 모든 블록 선택 (selected: true)
    - greeting에 "오늘 컨디션이 좋으시네요!" 같은 응원 메시지
12. 사용자가 명시적으로 출퇴근 타입과 앵커 타임을 전달하면
    그 값을 그대로 사용해. 설정이나 마지막 세션보다 우선.
```

### 4.3. 기본값 추론 로직

대화 시작 시 기본값을 미리 계산하여 질문에 표시:

```dart
// 출퇴근 타입 기본값
String defaultCommute = lastSession?.commuteType.name
    ?? settings.defaultCommuteType.name;

// 앵커 타임 기본값
String defaultAnchor = lastSession != null
    ? DateFormat('HH:mm').format(lastSession.anchorTime)
    : '09:00';

// 인사 메시지
String greeting = _greetingForTime(DateTime.now());
```

---

## 5. 파일 변경 사항

### 5.1. 새로 만들 파일

| 파일 | 내용 |
|------|------|
| `lib/models/onboarding_state.dart` | `OnboardingPhase`, `UserCondition`, `OnboardingState` 모델 |
| `lib/providers/onboarding_provider.dart` | `OnboardingNotifier`: phase 전환, 답변 수집, Gemini 호출 트리거 |
| `lib/screens/start/widgets/onboarding_flow.dart` | 대화형 온보딩 UI (질문 카드들, 애니메이션) |
| `lib/screens/start/widgets/question_card.dart` | 재사용 가능한 질문 카드 위젯 (질문 + 버튼 옵션) |

### 5.2. 수정할 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/screens/start/start_screen.dart` | Phase 1(온보딩) ↔ Phase 2(루틴 카드) 전환 로직 |
| `lib/services/morning_assistant_service.dart` | `generateSuggestion()`에 condition 파라미터 추가, 프롬프트 수정 |
| `lib/models/routine_suggestion.dart` | (선택) condition 필드 추가 |
| `lib/providers/morning_assistant_provider.dart` | `loadSuggestion()`에 온보딩 결과 전달 |

### 5.3. 변경하지 않는 파일

| 파일 | 이유 |
|------|------|
| `lib/screens/start/widgets/suggestion_card.dart` | 기존 유지 (Phase 2에서 그대로 사용) |
| `lib/screens/start/widgets/chat_input.dart` | 기존 유지 (Phase 2에서 그대로 사용) |
| `lib/services/firestore_service.dart` | 추가 메서드 필요 없음 |

---

## 6. 구현 명세

### 6.1. `OnboardingNotifier`

```dart
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref) : super(const OnboardingState()) {
    _initialize();
  }

  void _initialize() {
    // 기본값 계산
    final uid = _ref.read(currentUidProvider);
    final settings = _ref.read(settingsProvider).value ?? const UserSettings();
    // lastSession은 비동기이므로 나중에 조회
    
    final greeting = _greetingForTime(DateTime.now());
    final defaultCommute = settings.defaultCommuteType.name;
    
    state = OnboardingState(
      phase: OnboardingPhase.greeting,
      greeting: greeting,
      commuteType: null,       // 아직 선택 안 됨, 기본값은 UI에서 표시
      anchorTime: null,        // 아직 선택 안 됨
    );
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

    // morningAssistantProvider.loadSuggestion()에
    // 온보딩 결과를 전달
    await _ref.read(morningAssistantProvider.notifier).loadSuggestionWithContext(
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
}
```

### 6.2. `MorningAssistantNotifier` 변경

```dart
/// 기존 loadSuggestion()은 유지 (fallback용)

/// 온보딩 결과를 반영한 제안 생성
Future<void> loadSuggestionWithContext({
  required String commuteType,
  required String anchorTime,
  required UserCondition condition,
}) async {
  state = const AsyncValue.loading();

  try {
    final assistant = _ref.read(morningAssistantServiceProvider);
    final firestoreService = _ref.read(firestoreServiceProvider);
    final uid = _ref.read(currentUidProvider);
    final settings = _ref.read(settingsProvider).value ?? const UserSettings();
    final presets = _ref.read(userBlockPresetsProvider).value ?? [];

    final lastSession =
        uid != null ? await firestoreService.getLastSession(uid) : null;

    final suggestion = await assistant.generateSuggestion(
      now: DateTime.now(),
      lastSession: lastSession,
      presets: presets,
      settings: settings,
      // 신규 파라미터:
      commuteType: commuteType,
      anchorTime: anchorTime,
      condition: condition,
    );

    if (mounted) {
      state = AsyncValue.data(suggestion);
    }
  } catch (e, st) {
    if (mounted) {
      state = AsyncValue.error(e, st);
    }
  }
}
```

### 6.3. `MorningAssistantService.generateSuggestion()` 변경

```dart
Future<RoutineSuggestion> generateSuggestion({
  required DateTime now,
  Session? lastSession,
  required List<UserBlockPreset> presets,
  required UserSettings settings,
  // 신규 (nullable - 온보딩 없이 호출 시 기존 동작)
  String? commuteType,
  String? anchorTime,
  UserCondition? condition,
}) async {
  // ...
  final contextText = _buildContext(
    now: now,
    lastSession: lastSession,
    presets: presets,
    settings: settings,
    commuteType: commuteType,      // 전달
    anchorTime: anchorTime,        // 전달
    condition: condition,          // 전달
  );
  // ...
}
```

`_buildContext()` 변경:

```dart
String _buildContext({
  // ... 기존 파라미터
  String? commuteType,
  String? anchorTime,
  UserCondition? condition,
}) {
  // ... 기존 코드

  // 사용자 입력이 있으면 추가 (온보딩 결과)
  if (commuteType != null || anchorTime != null || condition != null) {
    buffer.writeln('=== 사용자 입력 (오늘) ===');
    if (commuteType != null) buffer.writeln('출퇴근: $commuteType');
    if (anchorTime != null) buffer.writeln('앵커 타임: $anchorTime');
    if (condition != null) buffer.writeln('컨디션: ${condition.name}');
    buffer.writeln('');
    buffer.writeln('⚠️ 위 사용자 입력은 설정/마지막 세션보다 우선한다.');
  }

  // ... 기존 코드
}
```

### 6.4. `start_screen.dart` 변경

```dart
@override
Widget build(BuildContext context) {
  final onboarding = ref.watch(onboardingProvider);
  final suggestionAsync = ref.watch(morningAssistantProvider);
  // ...

  return Scaffold(
    appBar: AppBar(title: const Text('Good Morning')),
    body: Column(
      children: [
        // 진행 중인 루틴 배너 (기존 유지)
        if (hasActiveSession) ...,

        // 메인 콘텐츠
        Expanded(
          child: onboarding.phase == OnboardingPhase.complete
              // Phase 2: 기존 루틴 카드 (변경 없음)
              ? suggestionAsync.when(
                  data: (suggestion) => SingleChildScrollView(
                    child: SuggestionCard(...),
                  ),
                  loading: () => _buildLoadingState(theme),
                  error: (e, _) => _buildErrorState(theme, e),
                )
              // Phase 1: 대화형 온보딩
              : OnboardingFlow(
                  state: onboarding,
                  defaultAnchorTime: _defaultAnchorTime,
                  defaultCommuteType: _defaultCommuteType,
                  onCommuteSelected: (type) =>
                      ref.read(onboardingProvider.notifier).selectCommuteType(type),
                  onAnchorConfirmed: (time) =>
                      ref.read(onboardingProvider.notifier).confirmAnchorTime(time),
                  onConditionSelected: (c) =>
                      ref.read(onboardingProvider.notifier).selectCondition(c),
                ),
        ),

        // Phase 2에서만 ChatInput 표시
        if (onboarding.phase == OnboardingPhase.complete && suggestionAsync.hasValue)
          ChatInput(onSend: _handleChatMessage, enabled: !_isBusy),
      ],
    ),
  );
}
```

### 6.5. `OnboardingFlow` 위젯

```dart
class OnboardingFlow extends StatelessWidget {
  final OnboardingState state;
  final String defaultAnchorTime;     // 마지막 세션 기반
  final String defaultCommuteType;    // 마지막 세션 기반
  final ValueChanged<String> onCommuteSelected;
  final ValueChanged<String> onAnchorConfirmed;
  final ValueChanged<UserCondition> onConditionSelected;

  // 내부적으로 AnimatedSwitcher 또는 AnimatedList 사용
  // 각 질문이 답변 후 접히고 다음 질문이 나타나는 애니메이션

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 인사 카드 (항상 표시)
          _GreetingBubble(greeting: state.greeting),
          const SizedBox(height: 16),

          // Q1: 출퇴근 (항상 표시)
          if (state.commuteType == null)
            QuestionCard(
              question: '오늘은 어디서 일하시나요?',
              options: [
                QuestionOption(
                  icon: Icons.business,
                  label: '출근',
                  value: 'office',
                  isDefault: defaultCommuteType == 'office',
                ),
                QuestionOption(
                  icon: Icons.home,
                  label: '재택',
                  value: 'home',
                  isDefault: defaultCommuteType == 'home',
                ),
              ],
              onSelected: onCommuteSelected,
            )
          else
            _AnsweredChip(
              icon: state.commuteType == 'office' ? Icons.business : Icons.home,
              label: state.commuteType == 'office' ? '출근' : '재택',
            ),

          // Q2: 앵커 타임 (Q1 답변 후 표시)
          if (state.commuteType != null && state.anchorTime == null) ...[
            const SizedBox(height: 16),
            _AnchorTimeQuestion(
              defaultTime: defaultAnchorTime,
              onConfirmed: onAnchorConfirmed,
            ),
          ] else if (state.anchorTime != null)
            _AnsweredChip(
              icon: Icons.flag_outlined,
              label: '${state.anchorTime}까지',
            ),

          // Q3: 컨디션 (Q2 답변 후 표시)
          if (state.anchorTime != null && state.condition == null) ...[
            const SizedBox(height: 16),
            QuestionCard(
              question: '오늘 컨디션은 어떠세요?',
              options: [
                QuestionOption(icon: null, label: '😊 좋음', value: 'good'),
                QuestionOption(icon: null, label: '😐 보통', value: 'normal'),
                QuestionOption(icon: null, label: '😴 피곤', value: 'tired'),
              ],
              onSelected: (v) => onConditionSelected(UserCondition.values
                  .firstWhere((c) => c.name == v)),
            ),
          ] else if (state.condition != null)
            _AnsweredChip(
              icon: null,
              label: _conditionLabel(state.condition!),
            ),

          // 로딩 상태
          if (state.phase == OnboardingPhase.loading) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text('맞춤 루틴을 준비하고 있어요...'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### 6.6. `QuestionCard` 위젯 (재사용 가능)

```dart
class QuestionOption {
  final IconData? icon;
  final String label;
  final String value;
  final bool isDefault;

  const QuestionOption({
    this.icon,
    required this.label,
    required this.value,
    this.isDefault = false,
  });
}

class QuestionCard extends StatelessWidget {
  final String question;
  final List<QuestionOption> options;
  final ValueChanged<String> onSelected;

  // Card 안에 질문 텍스트 + 옵션 버튼들
  // 기본값이 있는 옵션은 테두리 강조
  // 탭하면 onSelected 호출

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: options.map((opt) => _buildOptionButton(opt)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6.7. `_AnsweredChip` (답변 완료 표시)

```dart
/// 답변 완료된 질문을 작은 칩으로 표시
class _AnsweredChip extends StatelessWidget {
  final IconData? icon;
  final String label;

  // 작은 Chip 형태로 이전 답변을 요약 표시
  // 예: [🏠 재택]  [🚩 10:00까지]  [😊 좋음]
}
```

---

## 7. 시스템 프롬프트 전체 수정본

```
너는 아침 루틴 어시스턴트야. 사용자의 컨텍스트를 기반으로 오늘의 루틴을 제안해.

규칙:
1. 블록은 반드시 사용자의 프리셋 목록에서만 선택해.
2. 마지막 세션 데이터가 있으면 그 패턴을 참고해.
3. "사용자 입력 (오늘)" 섹션이 있으면 그 값을 최우선으로 사용.
   설정/마지막 세션보다 우선한다.
4. 기상 시각은 현재 시각을 사용해.
5. greeting은 시간대+컨디션에 맞는 자연스러운 한국어로 작성.
6. reasoning은 왜 이 구성을 추천하는지 간단히 설명.
7. 컨디션 반영:
   - "good": 모든 블록 활성화, 에너지 넘치는 메시지
   - "normal": 기본 구성, 보통의 메시지
   - "tired": 무거운 블록(운동 등) 축소/비활성화, 가벼운 블록 우선, 위로 메시지
8. 수정 요청 시 현재 제안을 기반으로 변경사항만 반영.
9. 블록 추가 요청 시 프리셋에 없으면 presetId 빈 문자열로.
```

---

## 8. 주의사항

### 8.1. 성능
- 온보딩 Phase 1에서는 **Gemini 호출 없음** (로컬 로직만)
- Gemini 호출은 Q3 답변 후 **한 번만**
- 기존 대비 Gemini 호출 횟수 변화 없음 (1회)

### 8.2. 기본값이 없는 경우 (첫 사용자)
- 출퇴근: 기본값 강조 없이 둘 다 동등하게 표시
- 앵커 타임: `09:00`을 기본값으로 표시
- 컨디션: 기본값 없음

### 8.3. 이미 활성 세션이 있는 경우
- 온보딩을 건너뛰고, 상단 배너로 "진행 중인 루틴 있음" 표시 (기존 동작)
- 배너 탭 → `/now` 이동

### 8.4. 앱 복귀 시
- 이미 Phase 2(루틴 카드 표시)인 상태에서 탭 이동 후 복귀하면 온보딩 재시작 안 함
- `onboardingProvider`의 상태가 `complete`이면 바로 Phase 2 표시

### 8.5. 애니메이션
- 질문 전환 시 `AnimatedSize` + `FadeTransition` 사용
- 답변 완료 시 카드 → 칩으로 축소 애니메이션
- 과하지 않게, 200~300ms duration

---

## 9. 작업 순서 (권장)

| 단계 | 작업 | 예상 시간 |
|------|------|----------|
| 1 | `onboarding_state.dart` 모델 생성 | 10분 |
| 2 | `onboarding_provider.dart` 생성 | 20분 |
| 3 | `question_card.dart` 위젯 생성 | 15분 |
| 4 | `onboarding_flow.dart` 위젯 생성 (Q1~Q3 + 답변 칩 + 로딩) | 30분 |
| 5 | `start_screen.dart` 수정 (Phase 1 ↔ Phase 2 전환) | 20분 |
| 6 | `morning_assistant_service.dart` 수정 (condition 파라미터, 프롬프트) | 15분 |
| 7 | `morning_assistant_provider.dart` 수정 (`loadSuggestionWithContext`) | 10분 |
| 8 | 앵커 타임 질문 위젯 (TimePicker 연동) | 15분 |
| 9 | 애니메이션 적용 | 15분 |
| 10 | `flutter analyze` + `flutter build web` 검증 | 5분 |
| 11 | Firebase Hosting 배포 | 3분 |
| **합계** | | **~158분** |

---

## 10. 검증 체크리스트

- [ ] 앱 시작 시 인사 메시지 + Q1(출퇴근) 질문이 표시됨
- [ ] Q1 답변 후 Q2(앵커 타임) 질문이 애니메이션으로 나타남
- [ ] Q2에서 "맞아요" 선택 시 기본값으로 확정
- [ ] Q2에서 "변경하기" 선택 시 TimePicker 표시
- [ ] Q2 답변 후 Q3(컨디션) 질문이 나타남
- [ ] Q3 답변 후 로딩 → SuggestionCard 표시
- [ ] 컨디션 "tired" 선택 시 무거운 블록이 비활성화됨
- [ ] 컨디션 "good" 선택 시 모든 블록 활성화됨
- [ ] 기존 ChatInput으로 추가 수정 가능
- [ ] "이대로 시작" 버튼 → 세션 생성 → /now 이동
- [ ] 기본값이 마지막 세션 기반으로 정확히 표시됨
- [ ] 첫 사용자(마지막 세션 없음)도 정상 동작
- [ ] 이미 활성 세션이 있으면 배너 표시 (온보딩 건너뛰지 않음)
- [ ] 탭 이동 후 복귀 시 Phase 2 유지 (온보딩 재시작 안 함)
- [ ] `flutter analyze` 에러 없음
- [ ] `flutter build web` 성공
