import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/onboarding_state.dart';
import '../models/routine_suggestion.dart';
import '../models/session.dart';
import '../models/user_block_preset.dart';
import '../models/user_settings.dart';

/// Gemini 기반 아침 루틴 어시스턴트
///
/// 컨텍스트(마지막 세션, 프리셋, 설정)를 수집하여
/// 오늘의 루틴을 자동 제안하고, 자연어 수정 요청을 처리한다.
class MorningAssistantService {
  GenerativeModel? _model;
  ChatSession? _chat;

  static const _modelName = 'gemini-2.5-flash';

  static final _suggestionSchema = Schema.object(
    properties: {
      'greeting': Schema.string(description: '한국어 인사 메시지 (1문장)'),
      'wakeUpTime': Schema.string(description: 'HH:mm 형식 기상 시각'),
      'anchorTime': Schema.string(description: 'HH:mm 형식 앵커 타임'),
      'commuteType':
          Schema.enumString(enumValues: ['office', 'home'], description: '출퇴근 타입'),
      'blocks': Schema.array(
        items: Schema.object(
          properties: {
            'presetId': Schema.string(
                description: '프리셋 ID (없으면 빈 문자열)', nullable: true),
            'name': Schema.string(description: '블록 이름'),
            'minutes': Schema.integer(description: '분 단위 소요 시간'),
            'selected': Schema.boolean(description: '선택 여부'),
          },
          optionalProperties: ['presetId'],
        ),
        description: '추천 블록 목록',
      ),
      'reasoning': Schema.string(description: '추천 이유 (한국어, 1~2문장)'),
    },
  );

  GenerativeModel _getModel() {
    // #region agent log
    debugPrint('[DEBUG-B] _getModel() called, _model is null: ${_model == null}');
    // #endregion
    
    _model ??= FirebaseAI.googleAI().generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _suggestionSchema,
      ),
      systemInstruction: Content.system(_systemPrompt),
    );
    
    // #region agent log
    debugPrint('[DEBUG-B] Model created: $_modelName');
    // #endregion
    
    return _model!;
  }

  static const _systemPrompt = '''
너는 아침 루틴 어시스턴트야. 사용자의 컨텍스트를 기반으로 오늘의 루틴을 제안해.

규칙:
1. 블록은 반드시 사용자의 프리셋 목록에서만 선택해. 프리셋에 없는 블록은 추가하지 마.
2. 마지막 세션 데이터가 있으면 그 패턴을 참고해.
3. "사용자 입력 (오늘)" 섹션이 있으면 그 값을 최우선으로 사용. 설정/마지막 세션보다 우선한다.
4. 기상 시각은 제공된 현재 시각을 사용해.
5. greeting은 시간대+컨디션에 맞는 자연스러운 한국어로 작성해.
6. reasoning은 왜 이 구성을 추천하는지 간단히 설명해.
7. 컨디션 반영:
   - "good": 모든 블록 활성화 (selected: true), 에너지 넘치는 메시지
   - "normal": 기본 구성, 보통의 메시지
   - "tired": 무거운 블록(운동 등) 축소/비활성화 (selected: false), 가벼운 블록(명상/스트레칭) 우선, 위로 메시지
8. 수정 요청이 오면 현재 제안을 기반으로 변경사항만 반영해:
   - "앵커를 X시로" → anchorTime 변경
   - "재택이야" / "출근이야" → commuteType 변경
   - "X 추가해줘" → 프리셋에서 찾아서 blocks에 추가 (selected: true)
   - "X 빼줘" → 해당 블록의 selected를 false로
   - "X를 Y분으로" → 해당 블록의 minutes 변경
   - "전부 선택" / "전부 해제" → 모든 블록의 selected 변경
9. 블록 추가 요청 시 프리셋 목록에 없으면 name과 minutes를 사용자 요청대로 설정하고 presetId는 빈 문자열로.
''';

  /// 컨텍스트를 기반으로 초기 루틴 제안 생성
  Future<RoutineSuggestion> generateSuggestion({
    required DateTime now,
    Session? lastSession,
    required List<UserBlockPreset> presets,
    required UserSettings settings,
    String? commuteType,
    String? anchorTime,
    UserCondition? condition,
  }) async {
    // #region agent log
    debugPrint('[DEBUG-A] generateSuggestion called: presets=${presets.length}, lastSession=${lastSession != null}, condition=${condition?.name}');
    // #endregion
    
    if (presets.isEmpty) {
      return _emptyPresetsFallback(now);
    }

    final contextText = _buildContext(
      now: now,
      lastSession: lastSession,
      presets: presets,
      settings: settings,
      commuteType: commuteType,
      anchorTime: anchorTime,
      condition: condition,
    );

    try {
      // #region agent log
      debugPrint('[DEBUG-B] About to call _getModel()');
      // #endregion
      
      final model = _getModel();
      
      // #region agent log
      debugPrint('[DEBUG-C] Model obtained, starting chat');
      // #endregion
      
      _chat = model.startChat();
      
      // #region agent log
      debugPrint('[DEBUG-D] Sending message to Gemini, context length: ${contextText.length}');
      // #endregion
      
      final response = await _chat!.sendMessage(Content.text(contextText));
      
      // #region agent log
      debugPrint('[DEBUG-E] Gemini response received, text length: ${response.text?.length ?? 0}');
      // #endregion
      
      final text = response.text;

      if (text == null || text.isEmpty) {
        // #region agent log
        debugPrint('[DEBUG-E-fallback] Empty response, using fallback');
        // #endregion
        
        return _fallbackSuggestion(
          now: now,
          lastSession: lastSession,
          presets: presets,
          settings: settings,
        );
      }

      final json = jsonDecode(text) as Map<String, dynamic>;
      return RoutineSuggestion.fromJson(json);
    } catch (e) {
      // #region agent log
      debugPrint('[DEBUG-ERROR] Gemini 호출 실패: $e');
      debugPrint('[DEBUG-ERROR] Error type: ${e.runtimeType}');
      // #endregion
      
      debugPrint('Gemini 호출 실패: $e');
      return _fallbackSuggestion(
        now: now,
        lastSession: lastSession,
        presets: presets,
        settings: settings,
      );
    }
  }

  /// 자연어 수정 요청 처리 (멀티턴 채팅)
  Future<RoutineSuggestion?> modifySuggestion({
    required String userMessage,
    required RoutineSuggestion currentSuggestion,
    required List<UserBlockPreset> presets,
  }) async {
    // #region agent log
    debugPrint('[DEBUG-MODIFY-A] modifySuggestion called: message="$userMessage"');
    // #endregion
    
    try {
      if (_chat == null) {
        // #region agent log
        debugPrint('[DEBUG-MODIFY-B] Chat is null, creating new chat with history');
        // #endregion
        
        final model = _getModel();
        _chat = model.startChat(history: [
          Content.text('현재 제안: ${jsonEncode(currentSuggestion.toJson())}'),
          Content.model([
            TextPart(jsonEncode(currentSuggestion.toJson())),
          ]),
        ]);
      }

      final presetInfo = presets
          .map((p) => '${p.id}:${p.name}(${p.minutes}분)')
          .join(', ');

      final prompt =
          '사용자 요청: "$userMessage"\n\n사용 가능한 프리셋: [$presetInfo]\n\n현재 제안을 위 요청에 맞게 수정해서 전체 JSON을 다시 반환해.';

      // #region agent log
      debugPrint('[DEBUG-MODIFY-C] Sending modification request to Gemini');
      // #endregion

      final response = await _chat!.sendMessage(Content.text(prompt));
      
      // #region agent log
      debugPrint('[DEBUG-MODIFY-D] Modification response received: ${response.text?.substring(0, 100) ?? "null"}...');
      // #endregion
      
      final text = response.text;

      if (text == null || text.isEmpty) return null;

      final json = jsonDecode(text) as Map<String, dynamic>;
      return RoutineSuggestion.fromJson(json);
    } catch (e) {
      // #region agent log
      debugPrint('[DEBUG-MODIFY-ERROR] Gemini 수정 호출 실패: $e');
      debugPrint('[DEBUG-MODIFY-ERROR] Error type: ${e.runtimeType}');
      // #endregion
      
      debugPrint('Gemini 수정 호출 실패: $e');
      return null;
    }
  }

  /// 채팅 세션 리셋
  void resetChat() {
    _chat = null;
  }

  // ──────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────

  String _buildContext({
    required DateTime now,
    Session? lastSession,
    required List<UserBlockPreset> presets,
    required UserSettings settings,
    String? commuteType,
    String? anchorTime,
    UserCondition? condition,
  }) {
    final timeStr = DateFormat('HH:mm').format(now);
    final dayOfWeek = DateFormat('EEEE', 'ko').format(now);
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    final buffer = StringBuffer();
    buffer.writeln('=== 오늘의 컨텍스트 ===');
    buffer.writeln('현재 시각: $timeStr');
    buffer.writeln('날짜: $dateStr ($dayOfWeek)');
    buffer.writeln('');

    // 사용자 입력이 있으면 추가 (온보딩 결과)
    if (commuteType != null || anchorTime != null || condition != null) {
      buffer.writeln('=== 사용자 입력 (오늘) ===');
      if (commuteType != null) buffer.writeln('출퇴근: $commuteType');
      if (anchorTime != null) buffer.writeln('앵커 타임: $anchorTime');
      if (condition != null) buffer.writeln('컨디션: ${condition.name}');
      buffer.writeln('');
      buffer.writeln('⚠️ 위 사용자 입력은 설정/마지막 세션보다 우선한다.');
      buffer.writeln('');
    }

    buffer.writeln('=== 사용자 설정 ===');
    buffer.writeln('기본 출퇴근: ${settings.defaultCommuteType.name}');
    buffer.writeln('출근 소요: ${settings.officeCommuteMinutes}분');
    buffer.writeln('');

    buffer.writeln('=== 블록 프리셋 ===');
    for (final p in presets) {
      buffer.writeln('- id:${p.id} name:${p.name} minutes:${p.minutes}');
    }
    buffer.writeln('');

    if (lastSession != null) {
      final anchorStr = DateFormat('HH:mm').format(lastSession.anchorTime);
      buffer.writeln('=== 마지막 세션 ===');
      buffer.writeln('앵커 타임: $anchorStr');
      buffer.writeln('출퇴근: ${lastSession.commuteType.name}');
      buffer.writeln('날짜: ${lastSession.dateKey}');
    } else {
      buffer.writeln('=== 마지막 세션 ===');
      buffer.writeln('없음 (첫 사용)');
    }

    buffer.writeln('');
    buffer.writeln('위 컨텍스트를 기반으로 오늘의 루틴을 제안해줘.');

    return buffer.toString();
  }

  /// Gemini 실패 시 규칙 기반 fallback
  RoutineSuggestion _fallbackSuggestion({
    required DateTime now,
    Session? lastSession,
    required List<UserBlockPreset> presets,
    required UserSettings settings,
  }) {
    final timeStr = DateFormat('HH:mm').format(now);
    final commuteType =
        lastSession?.commuteType.name ?? settings.defaultCommuteType.name;
    final anchorTime = lastSession != null
        ? DateFormat('HH:mm').format(lastSession.anchorTime)
        : '09:00';

    final blocks = presets
        .map((p) => SuggestedBlock(
              presetId: p.id,
              name: p.name,
              minutes: p.minutes,
              selected: true,
            ))
        .toList();

    final greeting = _greetingForTime(now);

    return RoutineSuggestion(
      greeting: greeting,
      wakeUpTime: timeStr,
      anchorTime: anchorTime,
      commuteType: commuteType,
      blocks: blocks,
      reasoning: '오프라인 모드: ${lastSession != null ? "마지막 루틴 기반 제안" : "기본 설정 기반 제안"}',
    );
  }

  RoutineSuggestion _emptyPresetsFallback(DateTime now) {
    final timeStr = DateFormat('HH:mm').format(now);
    return RoutineSuggestion(
      greeting: _greetingForTime(now),
      wakeUpTime: timeStr,
      anchorTime: '09:00',
      commuteType: 'office',
      blocks: [],
      reasoning: '블록 프리셋이 없습니다. 설정에서 블록을 추가해 주세요.',
    );
  }

  String _greetingForTime(DateTime now) {
    final hour = now.hour;
    if (hour < 6) return '이른 새벽이네요. 오늘도 파이팅!';
    if (hour < 9) return '좋은 아침이에요!';
    if (hour < 11) return '늦은 아침이지만 괜찮아요!';
    return '좋은 하루 보내세요!';
  }
}
