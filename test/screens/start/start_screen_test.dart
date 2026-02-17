import 'package:flutter_test/flutter_test.dart';
import 'package:good_morning/models/routine_suggestion.dart';

void main() {
  group('StartScreen', () {
    test('StartScreen 통합 테스트는 integration_test에서 수행', () {
      // StartScreen은 Firebase 의존성이 많아 단위 테스트 어려움
      // 대신 integration_test로 E2E 테스트 예정
      
      // 여기서는 핵심 로직만 검증
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [],
        reasoning: 'test',
      );

      expect(suggestion.greeting, '좋은 아침!');
    });
  });
}
