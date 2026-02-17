import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_morning/models/routine_suggestion.dart';
import 'package:good_morning/screens/start/widgets/suggestion_card.dart';

void main() {
  group('SuggestionCard', () {
    late RoutineSuggestion testSuggestion;

    setUp(() {
      testSuggestion = RoutineSuggestion(
        greeting: '좋은 아침이에요!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [
          SuggestedBlock(
            presetId: 'p1',
            name: '명상',
            minutes: 10,
            selected: true,
          ),
          SuggestedBlock(
            presetId: 'p2',
            name: '운동',
            minutes: 30,
            selected: true,
          ),
          SuggestedBlock(
            presetId: 'p3',
            name: '샤워',
            minutes: 15,
            selected: false,
          ),
        ],
        reasoning: '오늘은 여유롭게 시작하는 것이 좋겠습니다.',
      );
    });

    testWidgets('제안 데이터 정상 렌더링', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      // When - UI 렌더링 대기
      await tester.pumpAndSettle();

      // Then - 인사 메시지 표시
      expect(find.text('좋은 아침이에요!'), findsOneWidget);

      // 기상 시각 표시
      expect(find.text('07:00'), findsOneWidget);

      // 앵커 타임 표시
      expect(find.text('09:00'), findsOneWidget);

      // 추론 메시지 표시
      expect(find.text('오늘은 여유롭게 시작하는 것이 좋겠습니다.'), findsOneWidget);

      // 블록 목록 표시
      expect(find.text('명상'), findsOneWidget);
      expect(find.text('운동'), findsOneWidget);
      expect(find.text('샤워'), findsOneWidget);

      // 블록 시간 표시
      expect(find.text('10분'), findsOneWidget);
      expect(find.text('30분'), findsOneWidget);
      expect(find.text('15분'), findsOneWidget);
    });

    testWidgets('앵커 타임 버튼 탭 → 콜백 호출', (tester) async {
      // Given
      bool anchorTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () => anchorTapped = true,
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 앵커 타임 버튼 탭
      await tester.tap(find.text('09:00'));
      await tester.pumpAndSettle();

      // Then
      expect(anchorTapped, true);
    });

    testWidgets('출퇴근 타입 변경 → 콜백 호출', (tester) async {
      // Given
      String? changedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (type) => changedType = type,
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - '재택' 버튼 탭
      await tester.tap(find.text('재택'));
      await tester.pumpAndSettle();

      // Then
      expect(changedType, 'home');
    });

    testWidgets('블록 체크박스 토글 → 콜백 호출', (tester) async {
      // Given
      int? toggledIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (index) => toggledIndex = index,
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 첫 번째 블록 체크박스 탭
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Then
      expect(toggledIndex, 0);
    });

    testWidgets('전체 선택/해제 버튼 동작', (tester) async {
      // Given
      bool toggleAllCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - '전체 해제' 버튼 탭 (2개 선택됨, 1개 미선택 → 전체 해제 표시)
      await tester.tap(find.text('전체 선택'));
      await tester.pumpAndSettle();

      // Then
      expect(toggleAllCalled, true);
    });

    testWidgets('"이대로 시작" 버튼 - 선택된 블록 있을 때 활성화', (tester) async {
      // Given
      bool startCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () => startCalled = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - "이대로 시작" 버튼 탭
      await tester.tap(find.text('이대로 시작'));
      await tester.pumpAndSettle();

      // Then
      expect(startCalled, true);
    });

    testWidgets('"이대로 시작" 버튼 - 선택된 블록 없을 때 비활성화', (tester) async {
      // Given - 모든 블록 미선택
      final noSelectionSuggestion = testSuggestion.copyWith(
        blocks: [
          SuggestedBlock(name: '명상', minutes: 10, selected: false),
          SuggestedBlock(name: '운동', minutes: 30, selected: false),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: noSelectionSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 버튼 찾기
      final startButton = find.ancestor(
        of: find.text('이대로 시작'),
        matching: find.byType(FilledButton),
      );

      // Then - 버튼이 비활성화 상태
      final button = tester.widget<FilledButton>(startButton);
      expect(button.onPressed, null);
    });

    testWidgets('빈 프리셋 안내 메시지 표시', (tester) async {
      // Given - 블록 없는 제안
      final emptySuggestion = RoutineSuggestion(
        greeting: '좋은 아침!',
        wakeUpTime: '07:00',
        anchorTime: '09:00',
        commuteType: 'office',
        blocks: [],
        reasoning: '블록 프리셋이 없습니다.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: emptySuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then - 안내 메시지 표시
      expect(find.text('블록 프리셋이 없습니다'), findsOneWidget);
      expect(
        find.textContaining('"20분 명상 추가해줘"처럼 요청하세요'),
        findsOneWidget,
      );

      // "이대로 시작" 버튼 없음
      expect(find.text('이대로 시작'), findsNothing);
    });

    testWidgets('총 시간 및 시작 시각 표시', (tester) async {
      // Given - 명상(10분, 선택) + 운동(30분, 선택) = 40분
      // 앵커 09:00 - 40분 = 08:20 시작

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then - 선택된 블록 수와 총 시간
      expect(find.text('2개 · 40분'), findsOneWidget);

      // 시작 시각 → 앵커 타임
      expect(find.text('08:20 → 09:00'), findsOneWidget);
    });

    testWidgets('isBusy=true 시 모든 버튼 비활성화', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              isBusy: true, // 바쁜 상태
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pump(); // pumpAndSettle 대신 pump 사용 (CircularProgressIndicator 무한 애니메이션)

      // When - 앵커 타임 버튼 찾기
      final anchorButton = find.ancestor(
        of: find.text('09:00'),
        matching: find.byType(FilledButton),
      );

      // Then - 앵커 버튼 비활성화
      final button = tester.widget<FilledButton>(anchorButton);
      expect(button.onPressed, null);

      // "전체 선택" 버튼 비활성화
      final toggleAllButton = find.ancestor(
        of: find.text('전체 선택'),
        matching: find.byType(TextButton),
      );
      final textButton = tester.widget<TextButton>(toggleAllButton);
      expect(textButton.onPressed, null);

      // "이대로 시작" 버튼에 로딩 표시
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('블록 선택 상태에 따라 UI 변경', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuggestionCard(
              suggestion: testSuggestion,
              onAnchorTimeTap: () {},
              onCommuteTypeChanged: (_) {},
              onBlockDelete: (_) {},
              onBlockReorder: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onBlockTimeUpdate: (_, __) {},
              onStart: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 체크박스 상태 확인
      final checkboxes = find.byType(Checkbox);
      final firstCheckbox = tester.widget<Checkbox>(checkboxes.at(0));
      final thirdCheckbox = tester.widget<Checkbox>(checkboxes.at(2));

      // Then - 첫 번째는 선택됨, 세 번째는 미선택
      expect(firstCheckbox.value, true); // 명상 선택됨
      expect(thirdCheckbox.value, false); // 샤워 미선택
    });
  });
}
