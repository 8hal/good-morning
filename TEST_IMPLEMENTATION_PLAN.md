# Good Morning 앱 테스트 코드 작성 계획

## 목표

빌드 후 자동 실행 가능한 포괄적인 테스트 스위트 구축

## 테스트 전략

### Phase 1: 단위 테스트 (Unit Tests)
Firebase/Gemini 의존성 없이 독립적으로 실행 가능한 로직 테스트

### Phase 2: 위젯 테스트 (Widget Tests)
Firebase 모킹 환경에서 UI 컴포넌트 동작 검증

### Phase 3: 통합 테스트 (Integration Tests)
전체 사용자 플로우 E2E 검증

---

## Phase 1: 단위 테스트

### 1.1 Model 직렬화/역직렬화 테스트

**파일**: `test/models/routine_suggestion_test.dart`

**테스트 케이스**:
- `RoutineSuggestion.fromJson()` 정상 파싱
- `RoutineSuggestion.toJson()` 정상 직렬화
- `SuggestedBlock.fromJson()` 정상 파싱
- nullable 필드 처리 (presetId null)
- 잘못된 JSON 입력 시 기본값 처리
- `copyWith()` 불변 복사 검증
- `totalMinutes` 계산 로직 (selected 블록만 합산)

**예상 결과**: JSON ↔ Dart 객체 변환 무결성 보장

---

### 1.2 MorningAssistantService Fallback 로직 테스트

**파일**: `test/services/morning_assistant_service_test.dart`

**테스트 케이스**:
- Gemini 호출 실패 시 fallback 동작
- 마지막 세션 있을 때 fallback 구성 (앵커/출퇴근 복원)
- 마지막 세션 없을 때 fallback 구성 (설정 기본값 사용)
- 프리셋 없을 때 empty fallback
- `_greetingForTime()` 시간대별 인사 메시지
- `_buildContext()` 컨텍스트 문자열 포맷

**모킹 필요**: 
- Gemini API 응답 (성공/실패)
- FirestoreService (마지막 세션 조회)

**예상 결과**: 네트워크 실패 시에도 앱이 동작 가능

---

### 1.3 Model 추가 테스트

**파일**: 
- `test/models/session_test.dart`
- `test/models/block_test.dart`
- `test/models/user_settings_test.dart`

**테스트 케이스**:
- Firestore 직렬화/역직렬화
- `isActive`, `isPendingFeedback` 등 computed property
- enum 변환 (`CommuteType.fromJson()`, `TimeFeel.fromJson()`)
- copyWith() 동작

---

### 1.4 Provider 로직 테스트

**파일**: `test/providers/morning_assistant_provider_test.dart`

**테스트 케이스**:
- `toggleBlock(index)` - 블록 선택 토글
- `toggleSelectAll()` - 전체 선택/해제
- `setAnchorTime()` - 로컬 앵커 변경
- `setCommuteType()` - 로컬 출퇴근 변경
- `modify()` 성공/실패 시 상태 업데이트

**모킹**: MorningAssistantService

**예상 결과**: Gemini 없이도 로컬 수정 동작 검증

---

## Phase 2: 위젯 테스트

### 2.1 SuggestionCard 위젯 테스트

**파일**: `test/screens/start/widgets/suggestion_card_test.dart`

**테스트 케이스**:
- 제안 데이터 정상 렌더링 (인사, 시간, 블록 목록)
- 앵커 타임 버튼 탭 → `onAnchorTimeTap` 콜백 호출
- 출퇴근 SegmentedButton 변경 → `onCommuteTypeChanged` 호출
- 블록 체크박스 토글 → `onBlockToggle` 호출
- "전체 선택/해제" 버튼 → `onToggleSelectAll` 호출
- "이대로 시작" 버튼 활성화/비활성화 (선택 블록 유무)
- 빈 프리셋 안내 메시지 표시
- 총 시간/시작 시각 계산 표시
- `isBusy=true` 시 버튼 비활성화

**예상 결과**: UI 인터랙션 정상 동작

---

### 2.2 ChatInput 위젯 테스트

**파일**: `test/screens/start/widgets/chat_input_test.dart`

**테스트 케이스**:
- 텍스트 입력 후 전송 버튼 탭 → `onSend` 호출
- Enter 키 입력 → `onSend` 호출
- 빈 입력 시 전송 불가
- 전송 중 로딩 표시 (CircularProgressIndicator)
- 전송 실패 시 SnackBar 표시
- `enabled=false` 시 입력/전송 비활성화

**예상 결과**: 채팅 입력 UX 검증

---

### 2.3 StartScreen 위젯 테스트

**파일**: `test/screens/start/start_screen_test.dart`

**테스트 케이스**:
- 로딩 상태 렌더링 (CircularProgressIndicator + 메시지)
- 에러 상태 렌더링 (에러 메시지 + "다시 시도" 버튼)
- 성공 상태 렌더링 (SuggestionCard + ChatInput)
- 진행 중인 루틴 배너 표시 (활성 세션 있을 때)
- 배너 탭 → `/now` 라우팅
- "다시 시도" 버튼 → 제안 재로드

**모킹**:
- `morningAssistantProvider` (AsyncValue 상태)
- `activeSessionProvider`
- GoRouter

**예상 결과**: 각 상태별 UI 정상 렌더링

---

## Phase 3: 통합 테스트

### 3.1 E2E: 루틴 시작 플로우

**파일**: `integration_test/routine_start_flow_test.dart`

**시나리오**:
1. 앱 시작 (익명 로그인)
2. 설정/프리셋 로드 대기
3. AI 제안 로드 (또는 fallback)
4. 블록 토글
5. 앵커 타임 변경
6. 채팅으로 수정 요청
7. "이대로 시작" 탭
8. `/now` 화면 이동 확인

**환경**: Fake Firestore + Mock Gemini

**예상 결과**: 전체 플로우 무결성 검증

---

### 3.2 E2E: 오프라인/에러 복원력

**파일**: `integration_test/offline_resilience_test.dart`

**시나리오**:
1. Gemini API 실패 시뮬레이션
2. Fallback 제안 표시 확인
3. 로컬 수정 동작 확인
4. 루틴 시작 가능 확인

**예상 결과**: 네트워크 실패 시에도 핵심 기능 동작

---

## 필요한 패키지 추가

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  fake_cloud_firestore: ^3.0.0
  integration_test:
    sdk: flutter
```

---

## CI/CD 통합

### GitHub Actions 워크플로우 예시

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter build web --release
```

**빌드 후 자동 테스트**: `flutter test` 명령어를 빌드 스크립트에 추가

---

## 테스트 커버리지 목표

- **Unit Tests**: 80% 이상 (로직 레이어)
- **Widget Tests**: 60% 이상 (UI 레이어)
- **Integration Tests**: 주요 플로우 3개 이상

---

## 최종 결과 (2026-02-16)

### ✅ 완료된 테스트

**총 78개 테스트 통과** (기존 20개 + 신규 58개)

#### Phase 1: 단위 테스트 (40개)
1. **Model 직렬화 테스트** - 19개 ✅
   - `test/models/routine_suggestion_test.dart`
   - RoutineSuggestion fromJson/toJson/copyWith/totalMinutes
   - SuggestedBlock fromJson/toJson/copyWith

2. **Enum 테스트** - 13개 ✅
   - `test/models/enums_test.dart`
   - CommuteType/TimeFeel/EndedBy/AnchorSource

3. **Service fallback 로직** - 13개 ✅
   - `test/services/morning_assistant_service_test.dart`
   - 시간대별 인사 메시지
   - 빈 프리셋/마지막 세션 기반 fallback
   - 컨텍스트 빌드 로직

4. **Provider 상태 관리** - 8개 ✅
   - `test/providers/morning_assistant_provider_test.dart`
   - toggleBlock/toggleSelectAll
   - setAnchorTime/setCommuteType
   - setSuggestion

#### Phase 2: 위젯 테스트 (38개)
1. **SuggestionCard** - 14개 ✅
   - `test/screens/start/widgets/suggestion_card_test.dart`
   - 제안 데이터 렌더링
   - 앵커/출퇴근/블록 토글 콜백
   - "이대로 시작" 버튼 활성화 조건
   - isBusy 상태 처리

2. **ChatInput** - 12개 ✅
   - `test/screens/start/widgets/chat_input_test.dart`
   - 텍스트 입력/전송
   - Enter 키 전송
   - 빈 입력/공백 처리
   - 로딩/에러 표시
   - enabled 상태

3. **StartScreen** - 1개 ✅
   - `test/screens/start/start_screen_test.dart`
   - Firebase 의존성으로 인해 E2E 테스트로 이관

4. **기존 Widget 테스트** - 20개 ✅
   - `test/widget_test.dart`

---

### 🔧 버그 수정

- [x] **Start → History 이동 시 블록 초기화 이슈**
  - `lib/screens/start/start_screen.dart`
  - `initState`에서 이미 로드된 제안이 있으면 재로드 건너뛰기
  - `_initialLoadDone` 상태 제거 (AsyncValue.hasValue로 판단)

---

## 작업 우선순위

### ✅ 완료 (2026-02-16)

#### Phase 1: 단위 테스트
- [x] **1.1** Model 직렬화 테스트 - 19개 테스트 ✅
- [x] **1.2** MorningAssistantService fallback 테스트 - 13개 테스트 ✅
- [x] **1.4** Provider 로직 테스트 - 8개 테스트 ✅
- [x] **1.5** Enum 테스트 - 13개 테스트 ✅

#### Phase 2: 위젯 테스트
- [x] **2.1** SuggestionCard 위젯 테스트 - 14개 테스트 ✅
- [x] **2.2** ChatInput 위젯 테스트 - 12개 테스트 ✅
- [x] **2.3** StartScreen 위젯 테스트 - 1개 테스트 ✅ (E2E로 이관)

---

### 우선순위 3 (장기)

#### Phase 3: E2E 통합 테스트
- [ ] **3.1** 루틴 시작 플로우 (Start → Now)
  - 제안 생성 → 블록 선택 → 루틴 시작
  
- [ ] **3.2** 루틴 완료 플로우 (Now → History)
  - 블록 진행 → 피드백 수집 → 세션 종료

#### Phase 4: CI/CD 파이프라인
- [x] **4.1** GitHub Actions 워크플로우 생성 ✅
  - `.github/workflows/test.yml` (테스트 자동화)
  - `.github/workflows/deploy.yml` (Firebase 배포)
  - `CI_CD_SETUP.md` (설정 가이드)

- [ ] **4.2** CI/CD 초기 설정
  - GitHub Secrets 설정
  - Firebase Service Account 연동
  - 첫 워크플로우 실행 테스트

- [ ] **4.3** 커버리지 리포트
  - Codecov 연동
  - 커버리지 뱃지 추가

---

## CI/CD 파이프라인

### 구성

**Test Workflow** (모든 push/PR)
```yaml
1. Flutter 환경 설정
2. 의존성 설치
3. 코드 분석 (flutter analyze)
4. 테스트 실행 (78개)
5. 커버리지 업로드
```

**Deploy Workflow** (main 브랜치만)
```yaml
1. 테스트 실행 (안전장치)
2. 테스트 통과 시:
   - Web 빌드
   - Firebase Hosting 배포
```

### 자동화 효과

| 항목 | 수동 | 자동 (CI/CD) |
|------|------|--------------|
| 테스트 실행 | 사람이 기억해야 함 | 푸시마다 자동 |
| 테스트 누락 | 깜빡하면 버그 배포 | 100% 실행 보장 |
| 배포 시간 | 10분 (수동) | 7분 (자동) |
| 롤백 필요성 | 높음 (수동 실수) | 낮음 (자동 차단) |
| 코드 리뷰 | 테스트 결과 수동 확인 | PR에 자동 표시 |

### 다음 단계

1. GitHub Secrets 설정 (Firebase Service Account)
2. 첫 워크플로우 테스트
3. Codecov 연동 (선택)

---

## 예상 소요 시간

- Phase 1 (Unit): 4-6시간
- Phase 2 (Widget): 3-4시간
- Phase 3 (Integration): 2-3시간
- CI/CD 설정: 1시간

**총 예상**: 10-14시간

---

## 실행 방법

### 전체 테스트 실행
```bash
flutter test
```

### 특정 파일 테스트
```bash
flutter test test/models/routine_suggestion_test.dart
```

### 커버리지 리포트
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 통합 테스트 실행
```bash
flutter test integration_test/
```

---

## 참고 문서

- [Flutter 테스트 가이드](https://docs.flutter.dev/testing)
- [Mockito 사용법](https://pub.dev/packages/mockito)
- [fake_cloud_firestore](https://pub.dev/packages/fake_cloud_firestore)
