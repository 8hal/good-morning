# Good Morning 앱 디자인 시스템 가이드

## 목적

Flutter 앱에 일관되고 완성도 높은 디자인을 적용하기 위한 체크리스트

---

## 1. 필요한 디자인 자료 (우선순위별)

### Priority 1: 필수 (지금 당장 필요)

#### 1.1 컬러 시스템
현재 상태: ✅ Deep Purple 적용됨

추가로 정의 필요:
- [ ] **Success 색상** (루틴 완료, 목표 달성)
- [ ] **Warning 색상** (지각 위험, 시간 부족)
- [ ] **Error 색상** (실패, 오류)
- [ ] **Neutral 색상** (비활성, 취소)
- [ ] **Accent 색상** (특별한 강조, 배지)

예시:
```dart
class AppColors {
  // Material 3 기본
  static const primary = Color(0xFF5E35B1);
  
  // 커스텀 시맨틱 컬러
  static const success = Color(0xFF4CAF50);  // 초록
  static const warning = Color(0xFFFF9800);  // 주황
  static const error = Color(0xFFE53935);    // 빨강
  static const neutral = Color(0xFF9E9E9E);  // 회색
  static const accent = Color(0xFFFFD700);   // 금색 (배지용)
}
```

#### 1.2 타이포그래피 스케일
현재 상태: ⚠️ 기본값만 사용 중

정의 필요:
- [ ] **Display**: 히어로 숫자 (남은 시간 등)
- [ ] **Headline**: 화면 제목
- [ ] **Title**: 카드/섹션 제목
- [ ] **Body**: 본문 텍스트
- [ ] **Label**: 버튼, 태그
- [ ] **Caption**: 보조 설명

예시:
```dart
textTheme: TextTheme(
  displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w600),  // 타이머
  headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600), // 화면 제목
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),    // 카드 제목
  bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),     // 본문
  labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),    // 버튼
)
```

#### 1.3 스페이싱 시스템
현재 상태: ❌ 하드코딩됨

정의 필요:
```dart
class Spacing {
  static const xxs = 2.0;   // 최소 간격
  static const xs = 4.0;    // 아이콘-텍스트
  static const sm = 8.0;    // 작은 요소 간
  static const md = 12.0;   // 기본 패딩
  static const lg = 16.0;   // 섹션 간
  static const xl = 24.0;   // 큰 섹션
  static const xxl = 32.0;  // 화면 여백
}
```

---

### Priority 2: 중요 (UX 개선)

#### 2.1 아이콘 시스템
현재 상태: ⚠️ Material Icons만 사용

추가 필요:
- [ ] **커스텀 아이콘** (루틴 타입별)
  - 명상: 🧘 또는 커스텀
  - 운동: 🏃 또는 커스텀
  - 식사: 🍽️ 또는 커스텀
  - 샤워: 🚿 또는 커스텀
- [ ] **일관된 크기** (16/20/24/32)
- [ ] **상태 아이콘** (완료/진행중/대기)

옵션:
1. Material Symbols (확장된 아이콘 세트)
2. Custom SVG (Figma에서 제작)
3. 이모지 + 배경 (간단하지만 덜 전문적)

#### 2.2 애니메이션 & 트랜지션
현재 상태: ❌ 없음

정의 필요:
```dart
class Durations {
  static const fast = Duration(milliseconds: 150);    // 버튼 탭
  static const normal = Duration(milliseconds: 300);  // 페이지 전환
  static const slow = Duration(milliseconds: 500);    // 강조 효과
}

class Curves {
  static const easeInOut = Curves.easeInOut;         // 기본
  static const spring = Curves.elasticOut;           // 재미있는 효과
}
```

적용 위치:
- [ ] 블록 선택/해제 시 체크박스 애니메이션
- [ ] 페이지 전환 (Hero 애니메이션)
- [ ] 타이머 진행 바 (부드러운 이동)
- [ ] 피드백 제출 후 확인 (성공 애니메이션)

#### 2.3 일러스트레이션 / 이미지
현재 상태: ❌ 없음

필요한 경우:
- [ ] **Empty State** (빈 히스토리, 빈 프리셋)
- [ ] **Success State** (루틴 완료 축하)
- [ ] **Error State** (오류 발생)
- [ ] **Onboarding** (첫 사용자 가이드)

옵션:
1. Lottie 애니메이션 (무료: LottieFiles)
2. SVG 일러스트 (무료: unDraw, Storyset)
3. 3D 아이콘 (무료: Shapefest)

---

### Priority 3: 선택 (브랜딩)

#### 3.1 로고 & 앱 아이콘
현재 상태: ⚠️ Flutter 기본값

필요:
- [ ] **앱 아이콘** (512x512, 적응형)
- [ ] **스플래시 스크린** (로고 + 배경)
- [ ] **네비게이션 로고** (작은 버전)

고려사항:
- 아침/해 모티프
- 체크박스/루틴 모티프
- 심플하고 인식 가능한 디자인

#### 3.2 커스텀 폰트
현재 상태: ✅ 시스템 폰트

선택 사항:
```dart
// 예: Pretendard (한글 최적화)
fontFamily: 'Pretendard',

// 또는: Google Fonts
GoogleFonts.notoSans(),
```

주의: 폰트 파일 크기 → 앱 용량 증가

---

## 2. 디자인 도구 선택

### 옵션 A: Figma 디자인 시스템 (권장)

**장점**:
- 컴포넌트 라이브러리 구축
- 실제 디자이너와 협업 가능
- 프로토타이핑 가능

**필요한 작업**:
1. Figma 파일 생성
2. 컬러/타이포/컴포넌트 정의
3. 주요 화면 5개 디자인
   - Start Screen (루틴 제안)
   - Now Screen (진행 중)
   - History Screen (기록)
   - Settings Screen (설정)
   - Feedback Screen (피드백)

**산출물**:
- `good-morning-design-system.fig`
- 스타일 가이드 PDF
- Asset 추출 (아이콘, 이미지)

---

### 옵션 B: 코드 기반 디자인 시스템 (빠름)

**장점**:
- 디자이너 없이 진행 가능
- Material Design 3 가이드라인 활용
- 즉시 적용 가능

**필요한 작업**:
1. `design_tokens.dart` 파일 생성
2. 컬러/스페이싱/타이포 상수 정의
3. 위젯 스타일 통일

**산출물**:
```
lib/core/
  ├── theme/
  │   ├── app_theme.dart (✅ 이미 있음)
  │   ├── design_tokens.dart (컬러, 스페이싱 등)
  │   └── text_styles.dart (타이포그래피)
  ├── widgets/
  │   ├── app_button.dart (통일된 버튼)
  │   ├── app_card.dart (통일된 카드)
  │   └── app_chip.dart (통일된 칩)
```

---

## 3. 현재 상태 진단

### 잘 되고 있는 것 ✅
- Material 3 사용
- Card, Button 등 기본 컴포넌트 활용
- 일관된 borderRadius (12px)
- ColorScheme.fromSeed 동적 컬러

### 개선 필요 ⚠️
- 하드코딩된 스페이싱 (8, 12, 16, 24 등)
- 중복된 스타일 정의 (각 위젯마다)
- 타이포그래피 일관성 부족
- 애니메이션 없음
- Empty State 처리 미흡

---

## 4. 추천 액션 플랜

### Phase 1: 기초 다지기 (1-2시간)
```bash
1. design_tokens.dart 생성
   - AppColors, Spacing, BorderRadius 정의
   
2. text_styles.dart 생성
   - AppTextStyles.display, .headline, .body 등
   
3. 기존 위젯들 리팩토링
   - 하드코딩된 값들을 토큰으로 교체
```

### Phase 2: 컴포넌트 통일 (2-3시간)
```bash
1. lib/core/widgets/ 생성
   - AppButton (primary, secondary, text)
   - AppCard (standard, elevated, outlined)
   - AppChip (filter, action, suggestion)
   
2. 기존 화면들에 적용
   - SuggestionCard → AppCard 사용
   - 버튼들 → AppButton 사용
```

### Phase 3: 폴리싱 (2-3시간)
```bash
1. 애니메이션 추가
   - 체크박스 토글
   - 페이지 전환
   - 성공 피드백
   
2. Empty State 일러스트
   - LottieFiles에서 무료 애니메이션 다운로드
   
3. 앱 아이콘 제작
   - Canva 또는 Figma로 간단히 제작
```

---

## 5. 필요한 외부 자료

### 즉시 사용 가능한 무료 리소스

#### 컬러 팔레트
- [Material Theme Builder](https://material-foundation.github.io/material-theme-builder/)
  → 현재 Deep Purple 기반 전체 팔레트 생성
  
#### 아이콘
- [Material Symbols](https://fonts.google.com/icons)
- [Heroicons](https://heroicons.com/) (Tailwind 팀)
- [Lucide Icons](https://lucide.dev/)

#### 일러스트
- [LottieFiles](https://lottiefiles.com/) - 무료 애니메이션
  - "empty state"
  - "success checkmark"
  - "morning sunrise"
  
- [unDraw](https://undraw.co/) - SVG 일러스트
  - 컬러 커스터마이징 가능
  
#### 폰트
- [Google Fonts](https://fonts.google.com/)
  - Noto Sans KR (한글)
  - Inter (영문, 현대적)
  - Pretendard (한글 최적화)

#### 앱 아이콘 제작
- [App Icon Generator](https://www.appicon.co/)
- Canva (간단한 로고 제작)

---

## 6. 디자이너와 협업 시 전달할 자료

만약 디자이너와 협업한다면 이 정보를 전달하세요:

### 앱 개요
```
앱 이름: Good Morning
목적: AI 기반 아침 루틴 관리
타겟: 생산성을 중요시하는 20-30대
톤앤매너: 전문적, 차분함, 집중력
```

### 기술 제약
```
플랫폼: Flutter (iOS + Android)
디자인 시스템: Material Design 3
지원 화면: 모바일 (360dp ~ 428dp)
다크모드: 추후 지원 예정
```

### 제공할 화면 목록
```
1. Start Screen - 루틴 제안 받기
2. Now Screen - 진행 중인 루틴
3. History Screen - 과거 기록
4. Settings Screen - 설정 및 프리셋 관리
5. Feedback Screen - 블록/세션 피드백
```

### Figma 파일 구조 요청
```
📁 Design System
  ├── 🎨 Colors (Primary, Secondary, Semantic)
  ├── 📝 Typography (Display, Headline, Body...)
  ├── 🔲 Components (Button, Card, Chip...)
  └── 📏 Spacing & Layout
  
📁 Screens
  ├── Start Screen
  ├── Now Screen
  ├── History Screen
  ├── Settings Screen
  └── Feedback Screen
```

---

## 7. 다음 단계

### 옵션 1: 직접 작업 (추천)
```bash
1. design_tokens.dart 파일 생성부터 시작
2. 기존 위젯들 점진적 개선
3. 무료 리소스 활용 (Lottie, unDraw)
4. Material Design 3 가이드라인 참고
```

**예상 시간**: 5-8시간
**비용**: 무료
**장점**: 즉시 시작 가능, 완전한 통제

### 옵션 2: 디자이너 협업
```bash
1. 디자이너에게 위 자료 전달
2. Figma 파일 받기
3. Flutter 위젯으로 구현
4. 피드백 반영
```

**예상 시간**: 2-3주 (디자이너 일정 포함)
**비용**: 외주 시 50-100만원
**장점**: 전문적인 결과물

### 옵션 3: AI 디자인 도구
```bash
1. v0.dev, Galileo AI 등 활용
2. 프롬프트로 화면 생성
3. Figma로 내보내기
4. Flutter 구현
```

**예상 시간**: 3-5시간
**비용**: 무료 (제한적) 또는 월 $20-40
**장점**: 빠른 프로토타이핑

---

## 결론

**지금 당장 시작할 수 있는 것**:
1. ✅ 컬러 변경 (완료 - Deep Purple)
2. 🔄 Design Tokens 파일 생성 (30분)
3. 🔄 Typography 정의 (30분)
4. 🔄 무료 Lottie 애니메이션 추가 (1시간)

**준비되면 진행할 것**:
- Figma 디자인 시스템 구축
- 커스텀 아이콘 제작
- 앱 아이콘 디자인

어떤 방향으로 진행하시겠어요?
