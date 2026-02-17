# AI 디자인 도구 활용 가이드

Good Morning 앱의 디자인을 AI 도구로 생성하는 실전 가이드

---

## 1. v0.dev - AI 기반 UI 생성 도구 ⭐

### 개요
- **개발사**: Vercel
- **가격**: 무료 (월 10회 생성) / $20/월 (무제한)
- **출력**: React/Next.js 코드 + 실시간 프리뷰
- **강점**: 빠른 프로토타이핑, 고품질 코드, Flutter 변환 용이

### 실전 검증
✅ Good Morning 앱 블록 리스트 성공적 생성 (2026-02-17)
- 드래그&드롭, 인라인 편집, 삭제 기능 모두 구현
- 총 소요 시간: 30분
- Flutter 변환: 버그 없이 완료

---

## 2. 워크플로우: v0.dev (추천) ⭐ 실전 검증됨

### 왜 v0.dev인가?
- ✅ 가장 빠른 프로토타이핑
- ✅ 실시간 프리뷰 + 즉시 수정 가능
- ✅ React 코드 → Flutter 변환 용이
- ✅ Vercel 팀 개발 (고품질)
- ✅ **실제 프로젝트 경험**: Good Morning 앱 블록 리스트 성공적 생성

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
   - Header "블록 구성" with hint text "길게 눌러 순서 변경"
   - Draggable list items with 6-dot grip handle
   - Each item layout:
     • Left: 6-dot drag handle (⋮⋮)
     • Center: Block name (e.g., "명상", "샤워")
     • Right: Duration badge "20분" (tap to edit with +/- stepper)
     • Far right: Delete button (X icon)
   - Inline time editing:
     • Tap duration → show [-] [20분] [+] [완료] buttons
     • +/- adjust in 5-minute increments (5-120 min range)

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

#### 옵션 A: GitHub Public 레포로 공유 (추천) ⭐ 검증됨
```
1. v0에서 생성 → "Deploy to GitHub" 클릭
2. GitHub 레포를 Public으로 변경
3. Claude에게 레포 URL 공유
4. Claude가 자동으로 코드 읽고 Flutter 변환

예시:
https://github.com/8hal/v0-morning-routine-planner-7i

결과: 
- 드래그&드롭 블록 리스트
- 인라인 시간 편집 (+/- 스테퍼)
- 삭제 버튼
→ 모두 Flutter로 성공적 변환됨
```

#### 옵션 B: 수동 변환
```
React → Flutter 매핑:

div → Container / Column / Row
className → styled widgets
onClick → onTap / onPressed
style={{ }} → decoration / TextStyle
map → List.generate / ListView.builder
useState → StatefulWidget
```

#### 옵션 C: AI 변환 도구
Claude/ChatGPT에게:
```
Convert this React component to Flutter:

[v0.dev 생성 코드 복사]

Use Material 3 widgets, preserve the layout structure, 
use Deep Purple (#5E35B1) as primary color.
```

---

## 3. 프롬프트 작성 팁

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

## 4. 생성 후 체크리스트

v0.dev에서 생성 후 확인할 것:

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

---

## 5. 실전 경험 & 다음 단계

### ✅ 실제 적용 사례 (2026-02-17)

Good Morning 앱 블록 리스트를 v0로 생성하고 Flutter 변환 완료:

#### 생성 과정
```
1. v0.dev 프롬프트 입력 (블록 리스트 스펙)
2. React 컴포넌트 생성 (1분 56초)
3. 피드백: "체크박스 대신 삭제 + 드래그 + 시간 편집"
4. 재생성 (1분 6초)
5. GitHub에 deploy → Public으로 변경
6. Claude가 레포 읽고 Flutter 변환
```

#### 결과물
- ✅ 드래그&드롭 (ReorderableListView)
- ✅ 인라인 시간 편집 (+/- 스테퍼)
- ✅ 삭제 버튼
- ✅ 6점 그립 핸들
- ✅ Deep Purple 테마
- ⏱️ 총 소요 시간: 약 30분

#### 배운 점
1. **GitHub 공유가 가장 효율적**: 전체 컨텍스트 공유 가능
2. **반복 수정 가능**: v0에서 프롬프트로 즉시 조정
3. **Flutter 변환 용이**: 기존 코드 개선 방식이 안전
4. **무료로 충분**: 무료 플랜 10회 생성으로 충분

### 즉시 시작하기

#### Step 1: v0.dev 생성
1. https://v0.dev 접속
2. 프롬프트 입력
3. 생성 → 수정 → Deploy to GitHub

#### Step 2: GitHub Public 변경
```bash
GitHub → Settings → Danger Zone 
→ Change visibility → Make public
```

#### Step 3: Claude에게 변환 요청
```
"이 v0 레포를 읽고 Flutter로 변환해줘:
https://github.com/your-username/your-repo"
```

### 결과물 정리
생성된 디자인을 다음과 같이 정리:
```
designs/
  ├── v0-dev/
  │   ├── github-links.md (레포 URL 목록)
  │   ├── start-screen.png
  │   └── screenshots/
  ├── flutter-converted/
  │   ├── suggestion_card.dart (변환 완료)
  │   └── block_list.dart
  └── docs/
      └── V0_DESIGN_APPLIED.md (변환 기록)
```

---

## 마무리

### 추천 워크플로우 (실전 검증)

**Phase 1: v0 생성** (30분-1시간)
```
1. 프롬프트 작성 (5분)
2. v0에서 생성 (2분)
3. 수정 요청 (필요시 1-2회)
4. GitHub에 Deploy
5. Public으로 변경
```

**Phase 2: Flutter 변환** (30분-1시간)
```
1. Claude에게 GitHub URL 공유
2. 자동으로 코드 분석
3. Flutter 위젯 생성
4. 기존 Provider 연결
5. 테스트 및 미세 조정
```

**Phase 3: 통합** (30분)
```
1. 기존 코드에 병합
2. Hot Reload로 즉시 확인
3. 필요시 스타일 조정
```

### 실제 성과
- ✅ 블록 리스트 생성: **30분**
- ✅ 품질: **프로덕션 수준**
- ✅ 비용: **무료**
- ✅ 버그: **최소화** (기존 코드 개선 방식)

### 다음 화면 생성 시

1. v0 프롬프트 재사용
2. GitHub 레포 누적 (한 레포에 여러 화면)
3. Claude가 전체 컨텍스트 파악
4. 일관된 디자인 시스템 유지

**총 예상 시간**: 
- 화면당: 1-1.5시간
- 5개 화면: 5-7시간

**총 비용**: 무료 (무료 플랜 활용)

**성공 요인**: 
- v0의 빠른 프로토타이핑
- Claude의 정확한 변환
- GitHub 공유로 전체 컨텍스트 전달

---

## 참고 자료

### 실제 프로젝트 예시
- v0 레포: https://github.com/8hal/v0-morning-routine-planner-7i
- Flutter 변환 기록: `V0_DESIGN_APPLIED.md`
- v0 가이드: `V0_GITHUB_INTEGRATION_GUIDE.md`

지금 v0.dev로 다음 화면 생성해볼까요?
