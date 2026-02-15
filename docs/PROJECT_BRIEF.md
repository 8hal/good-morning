# Good Morning — Project Brief

## 배경 및 목적

출근일 아침에 버스/이동 시간 제약으로 20분 이상 손실이 발생하는 문제.
핵심은 단순 알림이 아니라 **"Anchor(근무 시작 희망 시각) 기준으로 아침 루틴을 블록 단위로 실행하고, 매 블록 종료 시 피드백을 수집"**하여 만족감 데이터를 축적하는 것.

## 핵심 개념

| 용어 | 설명 |
|------|------|
| **Anchor** | 오늘 근무 시작하고 싶은 시각 (수동 입력 또는 캘린더 후보 선택) |
| **CommuteType** | home(재택) / office(출근). 아침 구조가 다름 |
| **Block** | 아침 루틴의 활동 단위 (예: run_25, proj_20, stretch_10) |
| **Session** | 하루의 아침 루틴 전체. 여러 Block으로 구성 |
| **TimeFeel** | 블록 종료 시 체감 시간 (short/ok/long) |
| **Satisfaction** | 블록 또는 세션에 대한 만족도 (1~5) |

## 실험 중립성 원칙 (Must)

> 실험 결과를 왜곡하지 않는 **중립적 MVP**

- ❌ 추천/최적화/평균점수/랭킹/"잘했어요" 같은 유도 문구 금지
- ❌ 블록 정렬이 점수에 의해 바뀌는 로직 금지
- ❌ Anchor 자동 확정 금지 (후보 제시만)
- ❌ 축하/격려/해석/조언 문구 금지
- ✅ 블록 목록 정렬은 항상 고정(동일 순서)
- ✅ 통계 화면은 최소화 (세션 리스트만, 점수/평균 요약 노출 최소)

## v0.1 범위

### 포함

- Firebase Auth (Google Sign-in)
- Anchor 수동 입력 + CommuteType 선택
- 블록 프리셋 (home/office 별 고정 목록)
- 블록 엔진 (start/end auto+manual, 알림 예약/취소)
- 피드백 수집: 블록별 timeFeel + satisfaction
- 루틴 종료 피드백: overall + repeatIntent + energy
- 4개 화면: Start / Now / History / Settings
- Firestore CRUD + Security Rules
- Asia/Seoul 타임존 고정
- 중복 저장 방지 로직

### 제외 (v0.1.5+)

- 캘린더 통합 (Anchor 후보 자동 추출)
- 오프라인 큐 (기본 재시도 이상)
- 분석/통계 화면
- 서버 사이드 Push notification
- 다크 모드
- 온보딩 플로우
- 블록 커스터마이징 (추가/삭제/순서변경)
- 다국어 지원

## 블록 프리셋 (v0.1)

### 출근일 (office)
| 블록 | 시간 |
|------|------|
| run | 25분 |
| proj | 20분 |
| stretch | 10분 |
| buffer | 15분 |

### 재택일 (home)
| 블록 | 시간 |
|------|------|
| run | 40분 |
| run | 25분 |
| proj | 40분 |
| proj | 20분 |
| buffer | 15분 |
| free | 30분 |

> 순서 고정. 사용자는 선택/해제만 가능. "추천" 문구 없이 단순 체크박스.

## 성공 지표

1. 매일 아침 루틴 실행 후 피드백 데이터가 Firestore에 누락 없이 저장됨
2. 앱 백그라운드에서도 블록 종료 알림 + 피드백 수집이 동작함
3. 실험 오염 요소가 0건 (Bias Audit 통과)

## 기술 스택

- **프레임워크**: Flutter (Dart)
- **상태관리**: Riverpod
- **라우팅**: go_router
- **백엔드**: Firebase (Auth + Firestore)
- **알림**: flutter_local_notifications
- **타임존**: timezone + intl

## 타임라인

| 단계 | 내용 | 예상 |
|------|------|------|
| Step 0 | 프로젝트 부트스트랩 + Firebase 연결 | 1일 |
| Step 1 | 세션 시작/종료 | 1~2일 |
| Step 2 | 블록 엔진 | 2일 |
| Step 3 | 알림 기반 피드백 (핵심) | 3~4일 |
| Step 4 | 히스토리 (중립) | 1일 |
| Step 5 | 캘린더 후보 (v0.1.5) | 2일 |
