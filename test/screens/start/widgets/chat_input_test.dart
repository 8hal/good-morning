import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_morning/screens/start/widgets/chat_input.dart';

void main() {
  group('ChatInput', () {
    testWidgets('텍스트 입력 후 전송 버튼 탭 → onSend 호출', (tester) async {
      // Given
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                sentMessage = message;
                return true; // 성공
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 텍스트 입력
      await tester.enterText(find.byType(TextField), '앵커를 10시로 바꿔줘');
      await tester.pumpAndSettle();

      // 전송 버튼 탭
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Then
      expect(sentMessage, '앵커를 10시로 바꿔줘');
    });

    testWidgets('Enter 키 입력 → onSend 호출', (tester) async {
      // Given
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                sentMessage = message;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 텍스트 입력 후 Enter
      await tester.enterText(find.byType(TextField), '명상 20분 추가');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Then
      expect(sentMessage, '명상 20분 추가');
    });

    testWidgets('빈 입력 시 전송 불가', (tester) async {
      // Given
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                sentMessage = message;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 빈 텍스트로 전송 시도
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Then - 전송되지 않음
      expect(sentMessage, null);
    });

    testWidgets('공백만 입력 시 전송 불가', (tester) async {
      // Given
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                sentMessage = message;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 공백만 입력
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Then
      expect(sentMessage, null);
    });

    testWidgets('전송 중 로딩 표시', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                await Future.delayed(const Duration(milliseconds: 100));
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 텍스트 입력 후 전송
      await tester.enterText(find.byType(TextField), '테스트 메시지');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(); // 첫 프레임만

      // Then - 로딩 표시
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 전송 완료 대기
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('전송 실패 시 SnackBar 표시', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                return false; // 실패
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 전송
      await tester.enterText(find.byType(TextField), '테스트');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Then - SnackBar 표시
      expect(
        find.text('요청을 처리하지 못했습니다. 다시 시도해 주세요.'),
        findsOneWidget,
      );
    });

    testWidgets('전송 성공 시 입력창 비우기', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                return true; // 성공
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 텍스트 입력 후 전송
      await tester.enterText(find.byType(TextField), '테스트 메시지');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Then - 입력창 비워짐
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('enabled=false 시 입력/전송 비활성화', (tester) async {
      // Given
      String? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              enabled: false, // 비활성화
              onSend: (message) async {
                sentMessage = message;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 텍스트 입력 시도
      await tester.enterText(find.byType(TextField), '입력 시도');

      // Then - TextField가 비활성화 상태
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);

      // 전송 버튼 찾기
      final sendButton = find.ancestor(
        of: find.byIcon(Icons.send_rounded),
        matching: find.byType(IconButton),
      );

      // 전송 버튼 비활성화
      final button = tester.widget<IconButton>(sendButton);
      expect(button.onPressed, null);
    });

    testWidgets('전송 중에는 중복 전송 불가', (tester) async {
      // Given
      int sendCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                sendCount++;
                await Future.delayed(const Duration(milliseconds: 200));
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 텍스트 입력 후 전송
      await tester.enterText(find.byType(TextField), '첫 번째');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump(const Duration(milliseconds: 10));

      // 전송 중임을 확인 (로딩 표시)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 완료 대기
      await tester.pumpAndSettle();

      // Then - 한 번만 전송됨
      expect(sendCount, 1);
    });

    testWidgets('힌트 텍스트 표시', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async => true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then - 힌트 텍스트 확인
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.decoration?.hintText,
        '"앵커를 10시로" "명상 20분 추가" ...',
      );
    });

    testWidgets('전송 후 포커스 유지', (tester) async {
      // Given
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInput(
              onSend: (message) async {
                await Future.delayed(const Duration(milliseconds: 50));
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When - 텍스트 입력 후 전송
      final textField = find.byType(TextField);
      await tester.tap(textField); // 포커스
      await tester.pumpAndSettle();

      await tester.enterText(textField, '테스트');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Then - TextField는 여전히 존재하고 사용 가능
      expect(find.byType(TextField), findsOneWidget);
      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.enabled, true);
    });
  });
}
