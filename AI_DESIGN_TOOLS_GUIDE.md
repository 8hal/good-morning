# AI 디자인 도구 활용 가이드

Good Morning 앱의 디자인을 AI 도구로 생성하는 실전 가이드

---

## 1. 추천 AI 디자인 도구 비교

| 도구 | 용도 | 가격 | 장점 | 단점 |
|------|------|------|------|------|
| **v0.dev** | 전체 화면 생성 | 무료 (제한) / $20/월 | React/Next.js 코드 생성, 실시간 프리뷰 | Flutter 직접 지원 X |
| **Galileo AI** | UI 디자인 생성 | 무료 (제한) / $19/월 | Figma 연동, 고품질 디자인 | 프롬프트 제한 |
| **Uizard** | 프로토타입 | 무료 / $12/월 | 빠른 프로토타이핑, 협업 | 디테일 부족 |
| **Locofy** | 코드 변환 | 무료 / $39/월 | Figma → Flutter 변환 | 수동 수정 필요 |
| **Claude + Artifacts** | 컴포넌트 | 무료 | 즉시 사용 가능, 대화형 | React만 지원 |

---

## 2. 워크플로우: v0.dev (추천)

### 왜 v0.dev인가?
- ✅ 가장 빠른 프로토타이핑
- ✅ 실시간 프리뷰
- ✅ React 코드 → Flutter 변환 용이
- ✅ Vercel 팀 개발 (고품질)

### Step 1: 화면별 프롬프트 작성

아래 프롬프트를 v0.dev에 입력하면 됩니다.

#### 📱 Start Screen (루틴 제안)

```
Create a mobile app screen for a morning routine planner:

Design System:
- Primary color: Deep Purple (#5E35B1)
- Secondary color: Light Purple (#D1C4E9)
- Theme: Professional, focused, calm
- Style: Material Design 3, clean, minimal

Layout:
1. Top Card (Greeting Section):
   - Large greeting text "좋은 아침이에요!" (can use placeholder)
   - Small wake up time chip with sun icon "7:30 기상"
   - Light purple background with subtle shadow
   - AI reasoning text below in smaller font

2. Anchor Time Card:
   - Icon (flag) + "앵커 타임" label
   - Large tappable time button "09:00"
   - Segmented button for commute type: "출근" / "재택" with icons
   - White background card with border radius 12px

3. Block List Section:
   - Header "블록 구성" with "전체 선택" button
   - List of checkbox items (selected state shown):
     ✓ 명상 20분 (selected, light purple background)
     ✓ 샤워 15분 (selected)
     □ 아침식사 30분 (unselected, gray)
   - Each item: checkbox + name + duration badge

4. Bottom Summary:
   - Left: "3개 · 65분"
   - Right: "07:55 → 09:00"
   - Full-width purple button "이대로 시작"

5. Chat Input (bottom):
   - Text field with placeholder "예: 20분 명상 추가해줘"
   - Send icon button

Make it feel premium, focused, and easy to use. Use purple accent color consistently.
```

#### 📱 Now Screen (진행 중)

```
Create a mobile app screen showing an active morning routine timer:

Design System:
- Primary: Deep Purple (#5E35B1)
- Theme: Focused, minimal, no distractions

Layout:
1. Top Status Bar:
   - Small text "3개 블록 중 2번째"
   - Progress bar (66% filled in purple)

2. Center Hero Section:
   - Large circular progress indicator (purple)
   - Current block name "샤워" in the center
   - Huge timer below "12:34"
   - Small total elapsed time "진행 23분"

3. Block List (scrollable):
   - Completed blocks (checkmark, gray text):
     ✓ 명상 20분
   - Current block (highlighted, purple):
     → 샤워 15분 (in progress)
   - Upcoming blocks (gray):
     · 아침식사 30분

4. Bottom Action Buttons:
   - Icon button: Skip (forward icon)
   - Large center button: Pause/Play (purple filled)
   - Icon button: Complete (checkmark icon)

5. Estimated finish time:
   - Small text at bottom "예상 완료: 09:00"

Make it feel like a premium meditation/focus app.
```

#### 📱 History Screen

```
Create a mobile app screen showing past morning routine history:

Design System:
- Primary: Deep Purple (#5E35B1)
- Theme: Data-focused, clean, organized

Layout:
1. Top Stats Cards (horizontal scroll):
   - Card 1: "이번 주" 
     - Large number "5회"
     - Small text "완료율 71%"
   - Card 2: "평균 시간"
     - Large number "62분"
   - Card 3: "연속 기록"
     - Large number "3일"
   - Purple accent on numbers

2. Calendar View (optional):
   - Week view with dates
   - Purple dots on days with completed routines

3. History List:
   - Each item card showing:
     - Date header "2026년 2월 17일 (월)"
     - Start time → End time "07:30 → 09:05"
     - Block list with durations
     - Overall mood emoji or rating
     - Subtle divider between items

4. Empty State (if no history):
   - Illustration of sunrise/morning
   - Text "아직 기록이 없어요"
   - Small text "첫 루틴을 시작해보세요!"

Make it feel insightful and motivating.
```

### Step 2: v0.dev에서 생성

1. https://v0.dev 접속
2. 무료 계정 생성 (Vercel 로그인)
3. 위 프롬프트 복사 → 붙여넣기
4. "Generate" 클릭
5. 결과 프리뷰 확인

### Step 3: 결과물 활용

v0.dev는 React/Tailwind 코드를 생성합니다. Flutter로 변환하는 방법:

#### 옵션 A: 수동 변환 (추천)
```
React → Flutter 매핑:

div → Container / Column / Row
className → styled widgets
onClick → onTap / onPressed
style={{ }} → decoration / TextStyle
map → List.generate / ListView.builder
```

#### 옵션 B: AI 변환 도구
Claude/ChatGPT에게:
```
Convert this React component to Flutter:

[v0.dev 생성 코드 복사]

Use Material 3 widgets, preserve the layout structure, 
use Deep Purple (#5E35B1) as primary color.
```

---

## 3. 워크플로우: Galileo AI

### 장점
- Figma 파일로 직접 출력
- 더 세련된 디자인
- 여러 스타일 옵션 제공

### 사용법

1. https://www.usegalileo.ai/ 접속
2. 무료 계정 생성
3. 프롬프트 입력 (v0.dev와 동일하게 사용 가능)
4. 생성된 디자인 → "Export to Figma"
5. Figma에서 Asset 추출

### 프롬프트 예시

```
Design a mobile app screen for morning routine planning.

Features:
- Greeting card with AI suggestion
- Anchor time selector
- Checklist of routine blocks
- Time summary
- Start button

Style:
- Deep purple primary color
- Clean, minimal, Material Design 3
- Professional and focused tone
- Similar to productivity apps like Notion, Todoist
```

---

## 4. 워크플로우: Locofy (Figma → Flutter)

Figma 디자인을 Flutter 코드로 변환하는 도구입니다.

### 사용 시나리오

1. v0.dev → Figma 복사 (수동)
2. Galileo AI → Figma 내보내기
3. Figma에서 직접 디자인

### 사용법

1. Figma에서 Locofy 플러그인 설치
2. 디자인 선택
3. "Export to Flutter" 클릭
4. 생성된 코드 다운로드
5. `lib/` 폴더에 추가

### 주의사항
- ⚠️ 생성된 코드는 90% 완성도
- 🔧 Provider, Navigation 등 수동 연결 필요
- 📦 pubspec.yaml 의존성 추가 필요

---

## 5. 워크플로우: Claude Artifacts (간단한 컴포넌트)

지금 대화 중인 Claude를 활용하는 방법입니다.

### 적합한 용도
- 개별 컴포넌트 (버튼, 카드 등)
- 애니메이션 프로토타입
- 인터랙션 테스트

### 사용법

저에게 이렇게 요청하세요:
```
"Start Screen의 SuggestionCard를 
React로 프로토타입 만들어줘. 
인터랙션 테스트할 수 있게."
```

그러면 Artifacts로 실시간 프리뷰를 제공합니다.
→ 마음에 들면 Flutter로 변환 요청

---

## 6. 실전 액션 플랜

### 🎯 목표
5개 주요 화면의 고품질 디자인 프로토타입 생성

### 📅 타임라인 (3-5시간)

#### Day 1: 생성 (2시간)
```
1. v0.dev 계정 생성 (5분)
2. Start Screen 프롬프트 입력 → 생성 (20분)
   - 결과 확인
   - 필요시 "Make it more minimal" 등으로 수정
3. Now Screen 생성 (20분)
4. History Screen 생성 (20분)
5. Settings Screen 생성 (20분)
6. Feedback Screen 생성 (20분)
```

#### Day 2: 변환 (3시간)
```
1. v0.dev React 코드 → Flutter 변환 (1.5시간)
   - 주요 위젯 매핑
   - 레이아웃 구조 이식
   
2. Material 3 위젯으로 교체 (1시간)
   - Card → Card
   - button → FilledButton / OutlinedButton
   - input → TextField
   
3. Provider 연결 (30분)
   - 더미 데이터로 테스트
   - 상태 관리 연결
```

---

## 7. 프롬프트 작성 팁

### ✅ 좋은 프롬프트
```
Create a mobile app screen for [목적]:

Design System:
- Primary color: #5E35B1
- Style: Material Design 3, minimal
- Theme: Professional, focused

Layout:
1. [섹션 1 이름]:
   - [요소 1] with [스타일]
   - [요소 2] showing [내용]
   
2. [섹션 2 이름]:
   - ...

Interactions:
- [버튼] should be [상태]
- [입력] placeholder: [텍스트]

Reference apps: Notion, Todoist, Calm
```

### ❌ 나쁜 프롬프트
```
Make a morning routine app screen
```
→ 너무 모호함, 원하는 결과 안 나옴

---

## 8. 생성 후 체크리스트

v0.dev/Galileo에서 생성 후 확인할 것:

- [ ] 레이아웃이 의도한 대로 나왔는가?
- [ ] 컬러가 Deep Purple 계열인가?
- [ ] 텍스트 크기가 적절한가? (너무 크거나 작지 않은가)
- [ ] 버튼이 눌릴 것처럼 보이는가?
- [ ] 모바일 화면에 잘 맞는가? (너무 빡빡하거나 여백이 많지 않은가)
- [ ] Material Design 느낌이 나는가?

만족스럽지 않다면:
```
Prompt: "Make it more minimal and spacious"
Prompt: "Increase text size for better readability"
Prompt: "Add more purple accent colors"
```

---

## 9. 비용 최적화 팁

### 무료로 최대한 활용하기

#### v0.dev 무료 플랜
- 월 10회 생성 제한
- 전략: 5개 화면 × 2회 수정 = 10회 사용

#### Galileo AI 무료 플랜
- 월 3회 프로젝트 제한
- 전략: 가장 중요한 3개 화면에만 사용

#### Claude (무료)
- 제한 없음 (일일 메시지 제한은 있음)
- 전략: 간단한 컴포넌트는 Claude로

### 권장 조합
```
1. v0.dev: Start, Now, History (핵심 3개)
2. Galileo: Settings, Feedback (부가 2개)
3. Claude: 개별 컴포넌트, 수정사항
```

총 비용: **무료**

---

## 10. 다음 단계

### 즉시 시작
1. v0.dev 접속
2. 첫 번째 프롬프트 (Start Screen) 복사
3. 생성 버튼 클릭
4. 결과 확인 후 스크린샷 공유

### 결과물 정리
생성된 디자인을 다음과 같이 정리:
```
designs/
  ├── v0-dev/
  │   ├── start-screen.png
  │   ├── start-screen-code.tsx
  │   ├── now-screen.png
  │   └── ...
  ├── figma/
  │   └── good-morning-designs.fig
  └── assets/
      ├── icons/
      └── illustrations/
```

---

## 마무리

**추천 워크플로우**:
1. ✅ v0.dev로 빠르게 프로토타입 (2시간)
2. ✅ 마음에 드는 디자인 → Flutter 변환 (3시간)
3. ✅ 세부 수정 및 폴리싱 (2시간)

**총 예상 시간**: 5-7시간
**총 비용**: 무료 (무료 플랜 활용)

지금 v0.dev로 첫 화면 생성해볼까요?
