# Good Morning

아침 루틴 실행 + 피드백 수집 앱 (실험 중립 MVP)

## 개요

근무 시작 희망 시각(Anchor)을 기준으로 아침 루틴(활동 블록)을 실행하고,
블록 종료마다 알림으로 피드백(시간 체감 + 만족도)을 수집하는 앱.

**핵심 원칙**: 실험을 오염시키지 않도록 앱은 조언/추천/해석/강조를 하지 않습니다.

## 기술 스택

- Flutter + Dart
- Firebase (Auth + Firestore)
- Riverpod (상태관리)
- flutter_local_notifications (알림)

## 시작하기

### 사전 요구사항

- Flutter SDK >= 3.16.0
- Firebase CLI
- Android Studio / Xcode

### 설치

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Firebase 설정 (FlutterFire CLI)
flutterfire configure
```

### 실행

```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── core/       # 상수, 테마, 유틸
├── models/     # 데이터 모델 (Session, Block, Enums)
├── services/   # 비즈니스 로직 (BlockEngine, Auth, Firestore, Notification)
├── providers/  # Riverpod 상태 관리
├── screens/    # UI 화면 (Start, Now, History, Settings, Feedback)
└── router/     # go_router 설정
```

## 문서

- [Project Brief](docs/PROJECT_BRIEF.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Event Flow](docs/EVENT_FLOW.md)
- [Tasks](docs/TASKS.md)
