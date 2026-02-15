# Good Morning — Event Flow (알림/블록 이벤트 흐름)

이 문서는 **블록 엔진과 알림 시스템의 정확한 이벤트 흐름**을 정의합니다.
Agent 2(앱), Agent 3(알림), Agent 4(Firebase)가 이 흐름을 기준으로 구현합니다.

---

## 1. 전체 세션 라이프사이클

```
[앱 실행]
  │
  ├── 활성 세션 있음? ──Yes──→ [Now 화면] (진행 중 블록으로 복귀)
  │                              │
  │                              ├── 미수집 피드백 있음? ──Yes──→ [Block Feedback Sheet]
  │                              │
  │                              └── 없음 → 현재 블록 타이머 표시
  │
  └── 활성 세션 없음? ──→ [Start 화면]
                            │
                            ├── 1) Anchor Time 설정 (수동 입력)
                            ├── 2) CommuteType 선택 (home/office)
                            ├── 3) 블록 선택 (고정 순서 체크리스트)
                            └── 4) "시작" 버튼 탭
                                  │
                                  ▼
                         [Session 생성 → 첫 Block 시작]
```

---

## 2. 블록 시작 (startBlock)

```
BlockEngine.startBlock(blockPreset)
  │
  ├── 1. Block 문서 생성 (Firestore)
  │     - blockType, plannedMinutes
  │     - startAt = DateTime.now()
  │     - plannedEndAt = startAt + plannedMinutes
  │     - endAt = null, endedBy = null
  │     - timeFeel = null, satisfaction = null
  │
  ├── 2. 알림 예약 (NotificationService)
  │     - scheduleBlockEndNotification(
  │         id: blockId.hashCode,
  │         scheduledAt: plannedEndAt,
  │         payload: { "blockId": blockId, "sessionId": sessionId }
  │       )
  │
  └── 3. Now 화면 업데이트
        - activeBlockProvider 상태 갱신
        - 카운트다운 타이머 시작 (UI용, Dart Timer)
```

---

## 3. 블록 종료 — 자동 (타이머 만료)

```
[plannedEndAt 도달]
  │
  ├── 시스템 로컬 알림 표시
  │     Title: "블록 종료"
  │     Body: "{blockType} {plannedMinutes}분 완료"
  │     ┌─────────────────────────────────────────┐
  │     │ Android: 액션 버튼 3개 (짧았다/적당/길었다) │
  │     │ iOS: 탭하여 앱 열기                       │
  │     └─────────────────────────────────────────┘
  │
  ├── [Case A] 앱이 포그라운드
  │     │
  │     ├── 알림 대신 인앱 Block Feedback BottomSheet 바로 표시
  │     ├── 1단계: timeFeel 선택 (short / ok / long) — 3버튼
  │     ├── 2단계: satisfaction 선택 (1 ~ 5) — 5버튼
  │     └── Block 문서 업데이트:
  │           endAt = plannedEndAt
  │           endedBy = "auto"
  │           actualMinutes = plannedMinutes
  │           timeFeel = 선택값
  │           satisfaction = 선택값
  │
  ├── [Case B] 앱이 백그라운드/종료
  │     │
  │     ├── 사용자가 알림 탭
  │     │     │
  │     │     ├── [Android 액션 버튼 선택한 경우]
  │     │     │     ├── timeFeel 바로 기록
  │     │     │     ├── 앱 실행 → satisfaction BottomSheet 표시
  │     │     │     └── Block 문서 업데이트
  │     │     │
  │     │     └── [알림 본문 탭한 경우 (iOS 포함)]
  │     │           ├── 앱 실행 → Block Feedback BottomSheet 표시
  │     │           ├── timeFeel + satisfaction 순차 수집
  │     │           └── Block 문서 업데이트
  │     │
  │     └── 사용자가 알림 무시
  │           └── 미수집 상태로 남음 (다음 앱 실행 시 수집)
  │
  └── [공통] 피드백 수집 완료 후
        │
        └── BlockEngine.advanceToNextBlock()
              │
              ├── 다음 블록 있음 → startBlock(nextPreset)
              └── 다음 블록 없음 → endSession() 트리거
```

---

## 4. 블록 종료 — 수동 (사용자가 "종료" 탭)

```
[Now 화면: "종료" 버튼 탭]
  │
  ├── 1. 예약된 알림 취소
  │     NotificationService.cancelBlockEndNotification(blockId)
  │
  ├── 2. Block 문서 즉시 업데이트 (부분)
  │     endAt = DateTime.now()
  │     endedBy = "manual"
  │     actualMinutes = endAt - startAt (분 단위)
  │
  ├── 3. 인앱 Block Feedback BottomSheet 표시
  │     (수동 종료는 항상 앱 포그라운드이므로 인앱 UI 사용)
  │     1단계: timeFeel 선택
  │     2단계: satisfaction 선택
  │
  ├── 4. Block 문서 업데이트 (피드백)
  │     timeFeel = 선택값
  │     satisfaction = 선택값
  │
  └── 5. BlockEngine.advanceToNextBlock()
```

---

## 5. 세션 종료 (endSession)

### 5a. 자동 종료 (마지막 블록 완료 후)

```
BlockEngine.advanceToNextBlock()
  └── 다음 블록 없음
        │
        ├── Session Feedback BottomSheet 표시
        │     - overallSatisfaction (1~5)
        │     - repeatIntent (예/아니오)
        │     - energyAtStart (1~5)
        │
        └── Session 문서 업데이트
              endAt = DateTime.now()
              overallSatisfaction = 선택값
              repeatIntent = 선택값
              energyAtStart = 선택값
```

### 5b. 수동 종료 (세션 도중 "루틴 종료" 탭)

```
[Now 화면: "루틴 종료" 버튼 탭]
  │
  ├── 1. 현재 블록 수동 종료 (4번 흐름과 동일)
  │     알림 취소 → 블록 문서 업데이트 → 피드백 수집
  │
  ├── 2. 남은 블록들은 생성하지 않음 (skip)
  │
  ├── 3. Session Feedback BottomSheet 표시
  │
  └── 4. Session 문서 업데이트 (endAt + 평가값)
```

---

## 6. 미수집 피드백 복구

```
[앱 실행 (cold start 또는 resume)]
  │
  ├── pendingFeedbackCheck()
  │     │
  │     ├── 현재 세션의 블록 중 endAt != null && timeFeel == null인 블록 검색
  │     │
  │     ├── 발견됨 → Block Feedback BottomSheet 표시 (각 미수집 블록마다)
  │     │
  │     └── 발견 안됨 → 정상 진행
  │
  └── 활성 블록의 plannedEndAt < now?
        │
        ├── Yes → 블록이 이미 만료됨. 자동 종료 처리 + 피드백 수집
        │
        └── No → 타이머 계속 (남은 시간 = plannedEndAt - now)
```

---

## 7. 알림 ID 체계

```
블록 종료 알림 ID: blockId.hashCode (정수)
  - 예약 시: notificationId = blockId.hashCode
  - 취소 시: 동일 ID로 cancel

알림 채널 (Android):
  - "block_end": 블록 종료 알림 (중요도: HIGH)
  - "feedback": 피드백 요청 알림 (중요도: DEFAULT)

알림 카테고리 (iOS):
  - "blockEndCategory": actions = [short, ok, long]
```

---

## 8. 데이터 흐름 다이어그램

```
┌─────────┐     ┌──────────────┐     ┌──────────────────┐
│ UI Layer │ ──→ │ BlockEngine   │ ──→ │ FirestoreService  │
│ (Screen) │     │ (Orchestrator)│     │ (CRUD)            │
└─────────┘     └──────────────┘     └──────────────────┘
                       │
                       ├──→ NotificationService
                       │      (예약/취소/액션)
                       │
                       └──→ Providers (Riverpod)
                              (상태 갱신 → UI 리빌드)
```

---

## 9. 중복 저장 방지

```
세션 중복 방지:
  - 같은 dateKey + uid로 활성 세션(endAt == null)이 있으면 새 세션 생성 금지
  - 체크: Firestore query → where("uid", ==, uid).where("dateKey", ==, today).where("endAt", ==, null)

블록 중복 방지:
  - 같은 세션 내에서 활성 블록(endAt == null)이 있으면 새 블록 시작 금지
  - 체크: blocks subcollection query → where("endAt", ==, null)

피드백 중복 방지:
  - timeFeel/satisfaction이 이미 non-null이면 업데이트 skip
```

---

## 10. 에러 처리

| 상황 | 처리 |
|------|------|
| Firestore 저장 실패 | 로컬 큐에 적재, 다음 앱 실행 시 재시도 (v0.1 최소) |
| 알림 권한 거부 | 설정 화면에서 권한 요청 안내 표시 |
| 세션 중 앱 크래시 | 앱 재실행 시 활성 세션/블록 복구 (Firestore 상태 기준) |
| 블록 피드백 미수집 | pendingFeedbackCheck로 복구 |
