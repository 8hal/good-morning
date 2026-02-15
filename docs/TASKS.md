# Good Morning — 구현 태스크 분해

Agent별 구현 순서와 각 태스크의 Done 기준을 정의합니다.

---

## 구현 순서

```
Agent 1 (설계 확정) ✅
    ↓
Agent 4 (Firebase 뼈대) → Step 0
    ↓
Agent 2 (화면/흐름) → Step 1, 2, 4
    ↓
Agent 3 (알림 액션) → Step 3
    ↓
Agent 5 (Bias QA) → 전체 점검
    ↓
Agent 6 (캘린더) → Step 5 (v0.1.5)
```

---

## Step 0: 프로젝트 부트스트랩 [Agent 4]

### 0.1 Flutter 프로젝트 생성
- [ ] `flutter create good_morning` 실행
- [ ] `pubspec.yaml` 의존성 설치 (`flutter pub get`)
- [ ] 코드 생성 (`build_runner`)
- **Done**: 프로젝트가 에뮬레이터에서 빌드/실행됨

### 0.2 Firebase 연결
- [ ] Firebase 프로젝트 생성 (Firebase Console 또는 CLI)
- [ ] `flutterfire configure` 실행
- [ ] `firebase_core` 초기화 확인 (`main.dart`)
- **Done**: 앱 실행 시 Firebase 초기화 로그 출력

### 0.3 Firebase Auth 구현
- [ ] Google Sign-in 플로우 구현 (`auth_service.dart` 완성)
- [ ] 로그인/로그아웃 UI (임시 버튼)
- [ ] `authStateProvider` 동작 확인
- **Done**: Google 로그인 후 uid가 콘솔에 출력됨

### 0.4 Firestore 기본 CRUD
- [ ] `firestore_service.dart`의 CRUD 함수 테스트
- [ ] 빈 세션 생성 → Firestore 콘솔에서 확인
- [ ] Firestore rules 배포
- **Done**: 로그인 후 빈 세션 문서가 Firestore에 저장됨

### 0.5 기본 라우팅
- [ ] `go_router` 4개 화면 라우팅 확인
- [ ] 하단 탭 네비게이션 구성 (Start, History, Settings)
- **Done**: 탭 전환으로 3개 화면 이동 가능

---

## Step 1: 세션 시작/종료 [Agent 2]

### 1.1 Start 화면 UI
- [ ] Anchor Time 피커 (시:분 선택, 수동 입력)
- [ ] CommuteType 토글 (home/office)
- [ ] 블록 체크리스트 (commuteType에 따른 프리셋, 고정 순서)
- [ ] "시작" 버튼
- **중립성**: "추천" 문구 없음. 체크박스만. 정렬 고정.
- **Done**: 사용자가 Anchor/CommuteType/블록을 선택하고 "시작" 탭 가능

### 1.2 세션 생성 연동
- [ ] "시작" 탭 → `BlockEngine.startSession()` 호출
- [ ] 세션 문서 Firestore에 생성됨
- [ ] 중복 방지: 같은 날 활성 세션 있으면 경고
- **Done**: sessions 컬렉션에 문서 1개 생성됨 (startAt 채워짐, endAt null)

### 1.3 세션 종료 + 피드백
- [ ] "루틴 종료" 버튼 (Now 화면)
- [ ] SessionFeedbackSheet 표시 (overall/repeat/energy)
- [ ] 세션 문서 업데이트 (endAt + 평가값)
- **Done**: sessions 문서에 endAt, overallSatisfaction, repeatIntent, energyAtStart 채워짐

---

## Step 2: 블록 엔진 [Agent 2]

### 2.1 블록 시작
- [ ] 세션 시작 후 첫 번째 선택 블록 자동 시작
- [ ] `BlockEngine.startBlock()` → blocks subcollection에 문서 생성
- [ ] Now 화면에 현재 블록 타입 + 타이머 표시
- **Done**: blocks 문서 생성됨 (startAt, plannedEndAt 채워짐)

### 2.2 Now 화면 UI
- [ ] 현재 블록 정보 (타입, 시간)
- [ ] 카운트다운 타이머 (남은 mm:ss)
- [ ] 종료 예정 시각 표시
- [ ] "종료" 버튼 (수동 종료)
- [ ] "루틴 종료" 버튼 (전체 세션 종료)
- **Done**: 타이머가 실시간으로 카운트다운, "종료" 탭으로 블록 종료 가능

### 2.3 수동 종료
- [ ] "종료" 탭 → `BlockEngine.endBlockManual()` 호출
- [ ] endAt, actualMinutes, endedBy="manual" 저장
- [ ] 피드백 시트 표시 → 피드백 저장
- **Done**: blocks 문서에 endAt, endedBy, actualMinutes, timeFeel, satisfaction 채워짐

### 2.4 다음 블록 전환
- [ ] 피드백 완료 후 → `advanceToNextBlock()`
- [ ] 다음 블록 있으면 → startBlock()
- [ ] 없으면 → endSession() 트리거
- **Done**: 블록 → 피드백 → 다음 블록 순환이 동작

---

## Step 3: 알림 기반 피드백 [Agent 3] ⭐ 핵심

### 3.1 알림 초기화
- [ ] `notification_service.dart` 초기화 완성
- [ ] Android 알림 채널 생성
- [ ] iOS 알림 카테고리/액션 등록
- [ ] 권한 요청 플로우
- **Done**: 앱 실행 시 알림 권한 허용, 테스트 알림 표시됨

### 3.2 블록 종료 알림 예약
- [ ] 블록 시작 시 `scheduleBlockEndNotification()` 호출
- [ ] plannedEndAt에 알림 표시 확인
- [ ] 수동 종료 시 `cancelBlockEndNotification()` 호출
- **Done**: 블록 타이머 만료 시 시스템 알림 표시, 수동 종료 시 알림 취소됨

### 3.3 알림 액션 처리 (Android)
- [ ] timeFeel 3버튼 액션 (짧았다/적당/길었다)
- [ ] 액션 선택 → timeFeel 기록
- [ ] 앱 실행 → satisfaction BottomSheet 표시
- **Done**: Android에서 알림 액션 → timeFeel 기록 → satisfaction 수집 동작

### 3.4 알림 탭 처리 (iOS + fallback)
- [ ] 알림 본문 탭 → 앱 실행
- [ ] payload에서 blockId 추출 → BlockFeedbackSheet 표시
- [ ] timeFeel + satisfaction 순차 수집
- **Done**: iOS에서 알림 탭 → 앱 열림 → 피드백 수집 완료

### 3.5 포그라운드 처리
- [ ] 앱이 포그라운드일 때는 알림 대신 인앱 BottomSheet 표시
- [ ] timeFeel → satisfaction 순차 수집
- **Done**: 포그라운드에서 블록 만료 시 BottomSheet 자동 표시

### 3.6 미수집 피드백 복구
- [ ] `pendingFeedbackCheck()` 구현
- [ ] 앱 실행 시 미수집 블록 감지 → 피드백 시트 표시
- [ ] 만료된 활성 블록 자동 종료 처리
- **Done**: 앱 재실행 후 미수집 피드백이 정상 수집됨

### 3.7 백그라운드 핸들러
- [ ] `_handleBackgroundNotificationResponse` 구현
- [ ] 앱 kill 상태에서 알림 액션 → 로컬 큐 저장
- [ ] 앱 재실행 시 큐 처리
- **Done**: 앱이 죽은 상태에서도 알림 탭 → 앱 실행 → 피드백 수집됨

---

## Step 4: 히스토리 [Agent 2]

### 4.1 History 화면 UI
- [ ] 세션 리스트 (날짜 + commuteType)
- [ ] 리스트 아이템 탭 → 세션 상세 (블록 목록)
- [ ] 페이지네이션 (스크롤 로딩)
- **중립성**: 점수 평균/분석/추천/축하 문구 없음
- **Done**: 과거 세션 목록이 표시되며 점수 유도가 없음

---

## Step 5: 캘린더 후보 [Agent 6] (v0.1.5)

### 5.1 캘린더 권한/선택
- [ ] `device_calendar` 패키지 추가
- [ ] 캘린더 접근 권한 요청
- [ ] 사용 가능한 캘린더 목록 → 선택 UI
- **Done**: 사용자가 특정 캘린더를 선택할 수 있음

### 5.2 Anchor 후보 추출
- [ ] 선택한 캘린더에서 오늘 오전(07:00~12:00) 일정 조회
- [ ] 종일 일정 제외
- [ ] 후보 리스트 생성 (일정 시작 시각 목록)
- **Done**: 오늘 오전 일정이 후보로 표시됨

### 5.3 후보 선택 → Anchor 반영
- [ ] Start 화면에 후보 리스트 표시
- [ ] 탭 → anchorTime에 반영 (자동 확정 아님!)
- [ ] anchorSource = "calendar_selected" 기록
- **중립성**: "추천" 문구 없음. "캘린더 일정"으로만 표시.
- **Done**: 후보 탭 시 anchorTime 반영, anchorSource 정확 기록

---

## QA 점검 [Agent 5]

### 실험 중립성 체크리스트
- [ ] 추천/랭킹/강조 색상/축하 문구 없음
- [ ] 블록 정렬이 점수에 의해 바뀌지 않음
- [ ] Anchor 자동 확정 없음
- [ ] History 화면에 점수 평균/분석 없음
- [ ] "잘했어요"/"훌륭합니다" 같은 유도 문구 없음

### 로깅 품질 체크리스트
- [ ] block end 이벤트 누락 없음
- [ ] block end 이벤트 중복 없음
- [ ] endedBy가 auto/manual 정확히 기록됨
- [ ] timeFeel과 satisfaction이 항상 기록됨 (또는 명시적 null)
- [ ] 루틴 종료 평가가 누락 없이 기록됨
- [ ] 세션 중복 방지 로직 동작 확인
- [ ] 블록 중복 방지 로직 동작 확인

---

## 의존 관계 다이어그램

```
Step 0 (부트스트랩)
  ├── 0.1 Flutter 생성
  ├── 0.2 Firebase 연결 ← 0.1
  ├── 0.3 Auth 구현 ← 0.2
  ├── 0.4 Firestore CRUD ← 0.2
  └── 0.5 라우팅 ← 0.1

Step 1 (세션) ← Step 0 전체
  ├── 1.1 Start UI
  ├── 1.2 세션 생성 ← 1.1
  └── 1.3 세션 종료 ← 1.2

Step 2 (블록) ← Step 1
  ├── 2.1 블록 시작 ← 1.2
  ├── 2.2 Now UI ← 2.1
  ├── 2.3 수동 종료 ← 2.2
  └── 2.4 다음 블록 ← 2.3

Step 3 (알림) ← Step 2
  ├── 3.1 알림 초기화
  ├── 3.2 알림 예약 ← 3.1, 2.1
  ├── 3.3 Android 액션 ← 3.2
  ├── 3.4 iOS 탭 ← 3.2
  ├── 3.5 포그라운드 ← 3.2
  ├── 3.6 미수집 복구 ← 3.5
  └── 3.7 백그라운드 ← 3.3

Step 4 (히스토리) ← Step 1
  └── 4.1 History UI

Step 5 (캘린더) ← Step 1
  ├── 5.1 권한/선택
  ├── 5.2 후보 추출 ← 5.1
  └── 5.3 후보 선택 ← 5.2

QA ← Step 0~4 전체
```
