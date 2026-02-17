/// AI가 제안하는 오늘의 루틴 구성
class RoutineSuggestion {
  final String greeting;
  final String wakeUpTime;
  final String anchorTime;
  final String commuteType; // "office" | "home"
  final List<SuggestedBlock> blocks;
  final String reasoning;

  const RoutineSuggestion({
    required this.greeting,
    required this.wakeUpTime,
    required this.anchorTime,
    required this.commuteType,
    required this.blocks,
    required this.reasoning,
  });

  int get totalMinutes =>
      blocks.fold(0, (sum, b) => sum + b.minutes);

  /// JSON -> RoutineSuggestion
  factory RoutineSuggestion.fromJson(Map<String, dynamic> json) {
    return RoutineSuggestion(
      greeting: json['greeting'] as String? ?? '좋은 아침이에요!',
      wakeUpTime: json['wakeUpTime'] as String? ?? '',
      anchorTime: json['anchorTime'] as String? ?? '09:00',
      commuteType: json['commuteType'] as String? ?? 'office',
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((b) =>
                  SuggestedBlock.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      reasoning: json['reasoning'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'greeting': greeting,
      'wakeUpTime': wakeUpTime,
      'anchorTime': anchorTime,
      'commuteType': commuteType,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'reasoning': reasoning,
    };
  }

  RoutineSuggestion copyWith({
    String? greeting,
    String? wakeUpTime,
    String? anchorTime,
    String? commuteType,
    List<SuggestedBlock>? blocks,
    String? reasoning,
  }) {
    return RoutineSuggestion(
      greeting: greeting ?? this.greeting,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      anchorTime: anchorTime ?? this.anchorTime,
      commuteType: commuteType ?? this.commuteType,
      blocks: blocks ?? this.blocks,
      reasoning: reasoning ?? this.reasoning,
    );
  }
}

/// 제안에 포함된 개별 블록
class SuggestedBlock {
  final String? presetId;
  final String name;
  final int minutes;

  const SuggestedBlock({
    this.presetId,
    required this.name,
    required this.minutes,
  });

  factory SuggestedBlock.fromJson(Map<String, dynamic> json) {
    return SuggestedBlock(
      presetId: json['presetId'] as String?,
      name: json['name'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'presetId': presetId,
      'name': name,
      'minutes': minutes,
    };
  }

  SuggestedBlock copyWith({
    String? presetId,
    String? name,
    int? minutes,
  }) {
    return SuggestedBlock(
      presetId: presetId ?? this.presetId,
      name: name ?? this.name,
      minutes: minutes ?? this.minutes,
    );
  }
}
