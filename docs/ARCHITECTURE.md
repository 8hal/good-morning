# Good Morning — Architecture

## 기술 선택 근거

| 영역 | 선택 | 근거 |
|------|------|------|
| 상태관리 | **Riverpod** | Context 비의존, 테스트 용이, 비동기 상태 처리 강점 |
| 라우팅 | **go_router** | Flutter 공식 추천, 딥링크 지원 (알림 탭 → 화면 이동) |
| 알림 | **flutter_local_notifications** | 가장 성숙한 로컬 알림 라이브러리, 액션 버튼 지원 |
| 인증 | **firebase_auth + google_sign_in** | 간편 로그인, Firestore uid 기반 보안 |
| DB | **cloud_firestore** | 실시간 동기화, 오프라인 캐시 내장 |
| 타임존 | **timezone + intl** | Asia/Seoul 고정 처리 |

---

## 폴더 구조

```
good-morning/
├── lib/
│   ├── main.dart                          # 앱 엔트리포인트
│   ├── app.dart                           # MaterialApp + Router 설정
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── block_presets.dart          # 블록 세트 정의 (고정 순서, 변경 불가)
│   │   │   └── app_constants.dart          # 앱 상수 (타임존 등)
│   │   ├── theme/
│   │   │   └── app_theme.dart             # 중립적 테마 (강조색/축하색 금지)
│   │   └── utils/
│   │       └── datetime_utils.dart        # Asia/Seoul 변환 유틸
│   │
│   ├── models/
│   │   ├── session.dart                   # Session 데이터 모델
│   │   ├── block.dart                     # Block 데이터 모델
│   │   ├── block_preset.dart              # BlockPreset (타입 + 기본 분)
│   │   ├── user_settings.dart             # 사용자 설정
│   │   └── enums.dart                     # CommuteType, TimeFeel, EndedBy, AnchorSource
│   │
│   ├── services/
│   │   ├── auth_service.dart              # Firebase Auth 래퍼
│   │   ├── firestore_service.dart         # Firestore CRUD (sessions, blocks)
│   │   ├── notification_service.dart      # 알림 예약/취소/액션 처리
│   │   ├── block_engine.dart              # 블록 시작/종료/전환 오케스트레이터
│   │   └── local_queue_service.dart       # 실패 시 로컬 큐 (v0.1 최소)
│   │
│   ├── providers/
│   │   ├── auth_provider.dart             # 인증 상태
│   │   ├── session_provider.dart          # 현재 세션 + CRUD
│   │   ├── active_block_provider.dart     # 현재 진행 중인 블록
│   │   ├── history_provider.dart          # 과거 세션 목록
│   │   └── settings_provider.dart         # 사용자 설정
│   │
│   ├── screens/
│   │   ├── start/
│   │   │   ├── start_screen.dart          # Anchor/CommuteType/블록 선택
│   │   │   └── widgets/
│   │   │       ├── anchor_time_picker.dart
│   │   │       ├── commute_type_selector.dart
│   │   │       └── block_checklist.dart   # 고정 순서 체크리스트
│   │   │
│   │   ├── now/
│   │   │   ├── now_screen.dart            # 현재 블록 진행 화면
│   │   │   └── widgets/
│   │   │       ├── block_timer_display.dart
│   │   │       └── manual_end_button.dart
│   │   │
│   │   ├── history/
│   │   │   ├── history_screen.dart        # 세션 리스트 (중립)
│   │   │   └── widgets/
│   │   │       └── session_list_tile.dart  # 날짜 + commuteType만 표시
│   │   │
│   │   ├── settings/
│   │   │   └── settings_screen.dart       # officeCommuteMinutes, 캘린더 토글
│   │   │
│   │   └── feedback/
│   │       ├── block_feedback_sheet.dart   # timeFeel(3) + satisfaction(1~5)
│   │       └── session_feedback_sheet.dart # overall(1~5) + repeatIntent + energy(1~5)
│   │
│   └── router/
│       └── app_router.dart                # go_router 설정 + 알림 딥링크
│
├── test/
│   ├── models/
│   ├── services/
│   │   └── block_engine_test.dart         # 블록 엔진 단위 테스트
│   └── providers/
│
├── firebase/
│   └── firestore.rules                    # Firestore 보안 규칙
│
├── docs/
│   ├── PROJECT_BRIEF.md
│   ├── ARCHITECTURE.md                    # (이 파일)
│   ├── EVENT_FLOW.md                      # 알림/블록 이벤트 흐름
│   └── TASKS.md                           # 구현 태스크 분해
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 핵심 클래스 설계

### 1. Models (데이터 계층)

#### Session
```dart
class Session {
  final String id;
  final String uid;
  final String dateKey;           // "2026-02-11"
  final DateTime anchorTime;
  final CommuteType commuteType;
  final DateTime startAt;
  final DateTime? endAt;
  final int? overallSatisfaction; // 1~5
  final bool? repeatIntent;
  final int? energyAtStart;       // 1~5
  final AnchorSource anchorSource;
}
```

#### Block
```dart
class Block {
  final String id;
  final String sessionId;
  final String blockType;         // "run", "proj", "stretch", "buffer", "free"
  final int plannedMinutes;
  final DateTime startAt;
  final DateTime plannedEndAt;
  final DateTime? endAt;
  final EndedBy? endedBy;         // auto / manual
  final int? actualMinutes;
  final TimeFeel? timeFeel;       // short / ok / long
  final int? satisfaction;        // 1~5
}
```

#### Enums
```dart
enum CommuteType { home, office }
enum TimeFeel { short_, ok, long_ }
enum EndedBy { auto_, manual }
enum AnchorSource { manual, calendarSelected }
```

### 2. Services (비즈니스 로직 계층)

#### BlockEngine — 핵심 오케스트레이터
```
책임:
- startSession(): 세션 문서 생성
- startBlock(preset): 블록 문서 생성 + 알림 예약
- endBlockAuto(blockId): 자동 종료 → 피드백 수집 트리거
- endBlockManual(blockId): 수동 종료 → 알림 취소 → 피드백 수집 트리거
- endSession(): 루틴 종료 → 종합 피드백 수집 트리거
- advanceToNextBlock(): 다음 블록으로 전환 (또는 세션 종료)

의존:
- FirestoreService (저장)
- NotificationService (알림 예약/취소)
```

#### NotificationService
```
책임:
- scheduleBlockEndNotification(blockId, plannedEndAt)
- cancelBlockEndNotification(blockId)
- handleNotificationAction(actionId, payload)
- showFeedbackNotification(blockId, stage) // timeFeel or satisfaction

의존:
- flutter_local_notifications 플러그인
```

#### FirestoreService
```
책임:
- CRUD: sessions, blocks
- 중복 저장 방지 (dateKey 기준 세션 중복 체크)
- uid 기반 쿼리 필터

규칙:
- 트랜잭션 불필요 (개인 앱)
- 중복 방지는 클라이언트 레벨 체크
```

### 3. Providers (상태 관리 계층 — Riverpod)

| Provider | 타입 | 역할 |
|----------|------|------|
| `authProvider` | `StreamProvider<User?>` | Firebase Auth 상태 |
| `currentSessionProvider` | `StateNotifierProvider<SessionNotifier, Session?>` | 진행 중 세션 |
| `activeBlockProvider` | `StateNotifierProvider<BlockNotifier, Block?>` | 현재 블록 |
| `historyProvider` | `FutureProvider<List<Session>>` | 과거 세션 목록 |
| `settingsProvider` | `StateNotifierProvider<SettingsNotifier, UserSettings>` | 사용자 설정 |

---

## Firestore 스키마

```
users/{uid}
├── createdAt: Timestamp
├── settings
│   ├── officeCommuteMinutes: int (기본 60)
│   ├── defaultCommuteType: string ("home" | "office")
│   └── calendarEnabled: bool (v0.1.5)

sessions/{sessionId}
├── uid: string
├── dateKey: string ("2026-02-11")
├── anchorTime: Timestamp
├── commuteType: string ("home" | "office")
├── startAt: Timestamp
├── endAt: Timestamp?
├── overallSatisfaction: int? (1~5)
├── repeatIntent: bool?
├── energyAtStart: int? (1~5)
├── anchorSource: string ("manual" | "calendar_selected")
│
└── blocks/{blockId} (subcollection)
    ├── blockType: string
    ├── plannedMinutes: int
    ├── startAt: Timestamp
    ├── plannedEndAt: Timestamp
    ├── endAt: Timestamp?
    ├── endedBy: string? ("auto" | "manual")
    ├── actualMinutes: int?
    ├── timeFeel: string? ("short" | "ok" | "long")
    └── satisfaction: int? (1~5)
```

---

## 기술 리스크 및 대응

### 리스크 1: 알림 액션 버튼의 플랫폼 차이

**문제**: iOS는 알림 액션 버튼 개수/UX에 제약이 있고, 2단계 알림(timeFeel → satisfaction)을 순수 알림으로만 처리하기 어려움.

**대응 (v0.1 전략)**:
- **앱이 포그라운드**: 인앱 BottomSheet로 피드백 수집 (가장 확실)
- **앱이 백그라운드**: 알림 표시 → 사용자 탭 → 앱 실행 → 인앱 피드백 시트
- **알림 액션 버튼**: Android에서는 timeFeel 3버튼을 알림에 표시. iOS에서는 알림 탭 → 앱 열림 → 인앱 처리
- **satisfaction**: 항상 인앱 BottomSheet (5개 버튼은 알림에 넣기 비현실적)

**정리**: 알림은 "블록이 끝났다"는 트리거 역할. 실제 피드백 수집은 인앱 UI.

### 리스크 2: 백그라운드 실행 제약

**문제**: iOS에서 앱이 kill되면 백그라운드 핸들러 실행이 제한적.

**대응**:
- 로컬 알림은 시스템 레벨이므로 앱 상태와 무관하게 표시됨 ✅
- 알림 탭 시 앱이 cold start → `onDidReceiveNotificationResponse`에서 payload 읽어 피드백 화면으로 라우팅
- 피드백 미수집 블록은 다음 앱 실행 시 감지하여 수집 (pending feedback check)

### 리스크 3: 타이머 정확도

**문제**: 앱이 백그라운드로 가면 Dart Timer가 부정확.

**대응**:
- Dart Timer는 UI 업데이트용으로만 사용 (카운트다운 표시)
- 실제 블록 종료는 **시스템 로컬 알림 예약**으로 처리 (정확)
- 앱이 포그라운드로 돌아올 때 `plannedEndAt`과 현재 시각 비교하여 UI 동기화

### 리스크 4: 미수집 피드백

**문제**: 알림을 무시하거나 피드백 수집 전 앱을 닫을 수 있음.

**대응**:
- 블록 문서에 `timeFeel`, `satisfaction`이 null인 경우 = 미수집
- 앱 실행 시 `pendingFeedbackCheck()`: 현재 세션의 미수집 블록이 있으면 피드백 시트 표시
- 세션 종료 시에도 미수집 블록 확인 후 일괄 수집 또는 null 허용 (데이터 품질 vs UX 트레이드오프)

---

## 화면 흐름

```
[로그인] → [Start 화면] → [Now 화면] → [블록 피드백] → ... → [세션 피드백] → [Start 화면]
                                ↑                                    |
                                └────────────────────────────────────┘
                                        (다음 블록 시작)

[Start 화면] ←→ [History 화면]
[Start 화면] ←→ [Settings 화면]
```

### 화면별 책임

| 화면 | 진입 조건 | 핵심 기능 |
|------|-----------|-----------|
| **Start** | 로그인 완료 + 활성 세션 없음 | Anchor/CommuteType 설정, 블록 선택, 루틴 시작 |
| **Now** | 활성 세션 + 활성 블록 존재 | 현재 블록 타이머, 수동 종료 버튼, 다음 블록 정보 |
| **Block Feedback** | 블록 종료 직후 (모달) | timeFeel 3버튼 → satisfaction 1~5 |
| **Session Feedback** | 모든 블록 완료 또는 수동 세션 종료 (모달) | overall + repeatIntent + energy |
| **History** | 탭 네비게이션 | 세션 리스트 (날짜, commuteType만. 점수 비노출) |
| **Settings** | 탭 네비게이션 | officeCommuteMinutes, 캘린더 토글 (v0.1.5) |
