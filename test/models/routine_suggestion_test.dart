import 'package:flutter_test/flutter_test.dart';
import 'package:good_morning/models/routine_suggestion.dart';

void main() {
  group('RoutineSuggestion', () {
    group('fromJson', () {
      test('정상 JSON 파싱 성공', () {
        // Given
        final json = {
          'greeting': '좋은 아침입니다!',
          'wakeUpTime': '06:30',
          'anchorTime': '09:00',
          'commuteType': 'office',
          'blocks': [
            {
              'presetId': 'preset-1',
              'name': '아침 운동',
              'minutes': 30,
              'selected': true,
            },
            {
              'presetId': 'preset-2',
              'name': '샤워',
              'minutes': 15,
              'selected': false,
            },
          ],
          'reasoning': '운동 후 출근 준비 시간을 고려했습니다.',
        };

        // When
        final suggestion = RoutineSuggestion.fromJson(json);

        // Then
        expect(suggestion.greeting, '좋은 아침입니다!');
        expect(suggestion.wakeUpTime, '06:30');
        expect(suggestion.anchorTime, '09:00');
        expect(suggestion.commuteType, 'office');
        expect(suggestion.blocks.length, 2);
        expect(suggestion.blocks[0].name, '아침 운동');
        expect(suggestion.blocks[0].minutes, 30);
        expect(suggestion.blocks[0].selected, true);
        expect(suggestion.blocks[1].selected, false);
        expect(suggestion.reasoning, '운동 후 출근 준비 시간을 고려했습니다.');
      });

      test('필드 누락 시 기본값 사용', () {
        // Given - 빈 JSON
        final json = <String, dynamic>{};

        // When
        final suggestion = RoutineSuggestion.fromJson(json);

        // Then - 기본값 확인
        expect(suggestion.greeting, '좋은 아침이에요!');
        expect(suggestion.wakeUpTime, '');
        expect(suggestion.anchorTime, '09:00');
        expect(suggestion.commuteType, 'office');
        expect(suggestion.blocks, isEmpty);
        expect(suggestion.reasoning, '');
      });

      test('blocks가 null일 때 빈 리스트 반환', () {
        // Given
        final json = {
          'greeting': '안녕하세요',
          'blocks': null,
        };

        // When
        final suggestion = RoutineSuggestion.fromJson(json);

        // Then
        expect(suggestion.blocks, isEmpty);
      });

      test('blocks 내부 객체 파싱', () {
        // Given
        final json = {
          'greeting': '테스트',
          'blocks': [
            {
              'name': '독서',
              'minutes': 20,
            }
          ],
        };

        // When
        final suggestion = RoutineSuggestion.fromJson(json);

        // Then
        expect(suggestion.blocks.length, 1);
        expect(suggestion.blocks[0].name, '독서');
        expect(suggestion.blocks[0].minutes, 20);
        expect(suggestion.blocks[0].selected, true); // 기본값
        expect(suggestion.blocks[0].presetId, null); // nullable
      });
    });

    group('toJson', () {
      test('Dart 객체를 JSON으로 직렬화', () {
        // Given
        final suggestion = RoutineSuggestion(
          greeting: '좋은 아침!',
          wakeUpTime: '07:00',
          anchorTime: '09:30',
          commuteType: 'home',
          blocks: [
            SuggestedBlock(
              presetId: 'p1',
              name: '명상',
              minutes: 10,
              selected: true,
            ),
          ],
          reasoning: '재택근무 스케줄',
        );

        // When
        final json = suggestion.toJson();

        // Then
        expect(json['greeting'], '좋은 아침!');
        expect(json['wakeUpTime'], '07:00');
        expect(json['anchorTime'], '09:30');
        expect(json['commuteType'], 'home');
        expect(json['blocks'], isList);
        expect((json['blocks'] as List).length, 1);
        expect((json['blocks'] as List)[0]['name'], '명상');
        expect(json['reasoning'], '재택근무 스케줄');
      });

      test('JSON 직렬화 후 역직렬화 시 동일한 객체 생성', () {
        // Given
        final original = RoutineSuggestion(
          greeting: '테스트',
          wakeUpTime: '06:00',
          anchorTime: '08:00',
          commuteType: 'office',
          blocks: [
            SuggestedBlock(name: '운동', minutes: 30),
          ],
          reasoning: 'test',
        );

        // When
        final json = original.toJson();
        final restored = RoutineSuggestion.fromJson(json);

        // Then
        expect(restored.greeting, original.greeting);
        expect(restored.wakeUpTime, original.wakeUpTime);
        expect(restored.anchorTime, original.anchorTime);
        expect(restored.commuteType, original.commuteType);
        expect(restored.blocks.length, original.blocks.length);
        expect(restored.blocks[0].name, original.blocks[0].name);
        expect(restored.reasoning, original.reasoning);
      });
    });

    group('copyWith', () {
      test('일부 필드만 변경', () {
        // Given
        final original = RoutineSuggestion(
          greeting: '원래 인사',
          wakeUpTime: '06:00',
          anchorTime: '09:00',
          commuteType: 'office',
          blocks: [],
          reasoning: '원래 이유',
        );

        // When
        final modified = original.copyWith(
          greeting: '수정된 인사',
          commuteType: 'home',
        );

        // Then
        expect(modified.greeting, '수정된 인사');
        expect(modified.commuteType, 'home');
        // 변경하지 않은 필드는 유지
        expect(modified.wakeUpTime, '06:00');
        expect(modified.anchorTime, '09:00');
        expect(modified.reasoning, '원래 이유');
      });

      test('원본 객체는 변경되지 않음 (불변성)', () {
        // Given
        final original = RoutineSuggestion(
          greeting: '원래',
          wakeUpTime: '06:00',
          anchorTime: '09:00',
          commuteType: 'office',
          blocks: [],
          reasoning: 'test',
        );

        // When
        original.copyWith(greeting: '수정');

        // Then - 원본은 그대로
        expect(original.greeting, '원래');
      });
    });

    group('totalMinutes', () {
      test('선택된 블록의 시간만 합산', () {
        // Given
        final suggestion = RoutineSuggestion(
          greeting: 'test',
          wakeUpTime: '06:00',
          anchorTime: '09:00',
          commuteType: 'office',
          blocks: [
            SuggestedBlock(name: '운동', minutes: 30, selected: true),
            SuggestedBlock(name: '샤워', minutes: 15, selected: true),
            SuggestedBlock(name: '독서', minutes: 20, selected: false), // 미선택
          ],
          reasoning: '',
        );

        // When
        final total = suggestion.totalMinutes;

        // Then - 30 + 15 = 45 (독서 20분은 제외)
        expect(total, 45);
      });

      test('선택된 블록이 없으면 0 반환', () {
        // Given
        final suggestion = RoutineSuggestion(
          greeting: 'test',
          wakeUpTime: '06:00',
          anchorTime: '09:00',
          commuteType: 'office',
          blocks: [
            SuggestedBlock(name: '운동', minutes: 30, selected: false),
          ],
          reasoning: '',
        );

        // When
        final total = suggestion.totalMinutes;

        // Then
        expect(total, 0);
      });

      test('블록이 비어있으면 0 반환', () {
        // Given
        final suggestion = RoutineSuggestion(
          greeting: 'test',
          wakeUpTime: '06:00',
          anchorTime: '09:00',
          commuteType: 'office',
          blocks: [],
          reasoning: '',
        );

        // When
        final total = suggestion.totalMinutes;

        // Then
        expect(total, 0);
      });
    });
  });

  group('SuggestedBlock', () {
    group('fromJson', () {
      test('정상 JSON 파싱 성공', () {
        // Given
        final json = {
          'presetId': 'preset-123',
          'name': '아침 식사',
          'minutes': 25,
          'selected': false,
        };

        // When
        final block = SuggestedBlock.fromJson(json);

        // Then
        expect(block.presetId, 'preset-123');
        expect(block.name, '아침 식사');
        expect(block.minutes, 25);
        expect(block.selected, false);
      });

      test('필드 누락 시 기본값 사용', () {
        // Given
        final json = <String, dynamic>{};

        // When
        final block = SuggestedBlock.fromJson(json);

        // Then
        expect(block.presetId, null); // nullable
        expect(block.name, ''); // 기본값
        expect(block.minutes, 15); // 기본값
        expect(block.selected, true); // 기본값
      });

      test('presetId가 null일 때 처리', () {
        // Given
        final json = {
          'presetId': null,
          'name': '사용자 정의',
          'minutes': 10,
        };

        // When
        final block = SuggestedBlock.fromJson(json);

        // Then
        expect(block.presetId, null);
        expect(block.name, '사용자 정의');
      });

      test('minutes를 double로 받아도 int로 변환', () {
        // Given
        final json = {
          'name': '스트레칭',
          'minutes': 10.5, // double
        };

        // When
        final block = SuggestedBlock.fromJson(json);

        // Then
        expect(block.minutes, 10); // int로 변환
      });
    });

    group('toJson', () {
      test('Dart 객체를 JSON으로 직렬화', () {
        // Given
        final block = SuggestedBlock(
          presetId: 'p-1',
          name: '요가',
          minutes: 20,
          selected: false,
        );

        // When
        final json = block.toJson();

        // Then
        expect(json['presetId'], 'p-1');
        expect(json['name'], '요가');
        expect(json['minutes'], 20);
        expect(json['selected'], false);
      });

      test('presetId가 null일 때 JSON에 null 포함', () {
        // Given
        final block = SuggestedBlock(
          presetId: null,
          name: '커스텀',
          minutes: 15,
        );

        // When
        final json = block.toJson();

        // Then
        expect(json['presetId'], null);
        expect(json.containsKey('presetId'), true); // 키는 존재
      });
    });

    group('copyWith', () {
      test('일부 필드만 변경', () {
        // Given
        final original = SuggestedBlock(
          presetId: 'p1',
          name: '원래 이름',
          minutes: 10,
          selected: true,
        );

        // When
        final modified = original.copyWith(
          name: '수정된 이름',
          selected: false,
        );

        // Then
        expect(modified.name, '수정된 이름');
        expect(modified.selected, false);
        expect(modified.presetId, 'p1'); // 유지
        expect(modified.minutes, 10); // 유지
      });

      test('원본 객체는 변경되지 않음 (불변성)', () {
        // Given
        final original = SuggestedBlock(
          name: '원래',
          minutes: 10,
        );

        // When
        original.copyWith(name: '수정');

        // Then
        expect(original.name, '원래');
      });
    });
  });
}
