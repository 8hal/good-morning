import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:good_morning/models/routine_suggestion.dart';
import 'package:good_morning/providers/morning_assistant_provider.dart';

void main() {
  group('MorningAssistantNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('toggleBlock - 블록 선택 토글', () {
      // Given
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [
          SuggestedBlock(name: '명상', minutes: 10, selected: true),
          SuggestedBlock(name: '운동', minutes: 30, selected: false),
        ],
        reasoning: 'test',
      );

      container
          .read(morningAssistantProvider.notifier)
          .setSuggestion(suggestion);

      // When - 첫 번째 블록 토글
      container.read(morningAssistantProvider.notifier).toggleBlock(0);

      // Then
      final result = container.read(morningAssistantProvider).value!;
      expect(result.blocks[0].selected, false); // true -> false
      expect(result.blocks[1].selected, false); // 변경 없음
    });

    test('toggleSelectAll - 모두 선택', () {
      // Given - 일부만 선택된 상태
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [
          SuggestedBlock(name: '명상', minutes: 10, selected: true),
          SuggestedBlock(name: '운동', minutes: 30, selected: false),
        ],
        reasoning: 'test',
      );

      container
          .read(morningAssistantProvider.notifier)
          .setSuggestion(suggestion);

      // When - 전체 선택 토글
      container.read(morningAssistantProvider.notifier).toggleSelectAll();

      // Then - 모두 선택됨
      final result = container.read(morningAssistantProvider).value!;
      expect(result.blocks[0].selected, true);
      expect(result.blocks[1].selected, true);
    });

    test('toggleSelectAll - 모두 해제', () {
      // Given - 모두 선택된 상태
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [
          SuggestedBlock(name: '명상', minutes: 10, selected: true),
          SuggestedBlock(name: '운동', minutes: 30, selected: true),
        ],
        reasoning: 'test',
      );

      container
          .read(morningAssistantProvider.notifier)
          .setSuggestion(suggestion);

      // When - 전체 선택 토글
      container.read(morningAssistantProvider.notifier).toggleSelectAll();

      // Then - 모두 해제됨
      final result = container.read(morningAssistantProvider).value!;
      expect(result.blocks[0].selected, false);
      expect(result.blocks[1].selected, false);
    });

    test('setAnchorTime - 앵커 타임 변경', () {
      // Given
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [],
        reasoning: 'test',
      );

      container
          .read(morningAssistantProvider.notifier)
          .setSuggestion(suggestion);

      // When
      container.read(morningAssistantProvider.notifier).setAnchorTime('10:30');

      // Then
      final result = container.read(morningAssistantProvider).value!;
      expect(result.anchorTime, '10:30');
    });

    test('setCommuteType - 출퇴근 타입 변경', () {
      // Given
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [],
        reasoning: 'test',
      );

      container
          .read(morningAssistantProvider.notifier)
          .setSuggestion(suggestion);

      // When
      container.read(morningAssistantProvider.notifier).setCommuteType('home');

      // Then
      final result = container.read(morningAssistantProvider).value!;
      expect(result.commuteType, 'home');
    });

    test('setSuggestion - 제안 직접 설정', () {
      // Given
      final suggestion = RoutineSuggestion(
        greeting: '직접 설정',
        wakeUpTime: '06:00',
        anchorTime: '08:00',
        commuteType: 'home',
        blocks: [
          SuggestedBlock(name: '독서', minutes: 20),
        ],
        reasoning: 'custom',
      );

      // When
      container.read(morningAssistantProvider.notifier).setSuggestion(suggestion);

      // Then
      final result = container.read(morningAssistantProvider).value!;
      expect(result.greeting, '직접 설정');
      expect(result.wakeUpTime, '06:00');
      expect(result.blocks.length, 1);
      expect(result.blocks[0].name, '독서');
    });

    test('toggleBlock - 범위 밖 인덱스는 무시', () {
      // Given
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [
          SuggestedBlock(name: '명상', minutes: 10, selected: true),
        ],
        reasoning: 'test',
      );

      container
          .read(morningAssistantProvider.notifier)
          .setSuggestion(suggestion);

      // When - 범위 밖 인덱스
      container.read(morningAssistantProvider.notifier).toggleBlock(5);

      // Then - 변경 없음
      final result = container.read(morningAssistantProvider).value!;
      expect(result.blocks[0].selected, true);
    });

    test('toggleSelectAll - 빈 블록 리스트는 무시', () {
      // Given
      final suggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [], // 빈 리스트
        reasoning: 'test',
      );

      container
          .read(morningAssistantProvider.notifier)
          .setSuggestion(suggestion);

      // When
      container.read(morningAssistantProvider.notifier).toggleSelectAll();

      // Then - 에러 없이 동작, 변경 없음
      final result = container.read(morningAssistantProvider).value!;
      expect(result.blocks, isEmpty);
    });
  });
}
