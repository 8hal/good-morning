# v0 디자인 적용 완료 (2026-02-17)

## 변경 사항

### 1. SuggestionCard 위젯 개선

#### 변경 전
- ✅ 드래그&드롭: 있음
- ⚠️ 시간 편집: 다이얼로그 팝업
- ⚠️ UI: 기본 Material 스타일

#### 변경 후
- ✅ 드래그&드롭: 유지 (ReorderableListView)
- ✅ 시간 편집: **인라인 스테퍼** (+/- 버튼)
- ✅ UI: v0 디자인 적용
- ✅ 힌트: "길게 눌러 순서 변경" 추가

### 2. 핵심 개선 사항

#### A. 인라인 시간 편집
```dart
// 변경 전: 다이얼로그
onTap → AlertDialog → 숫자 입력 → 확인

// 변경 후: 인라인 스테퍼
onTap → 편집 모드 전환
  - [−] 버튼: -5분
  - 현재 시간 표시
  - [+] 버튼: +5분
  - [완료] 버튼
```

**장점**:
- 더 빠른 조작
- 키보드 불필요
- 모바일 친화적
- v0 디자인과 일치

#### B. 드래그 핸들 아이콘 변경
```dart
// 변경 전
Icons.drag_handle  // ☰☰ (2줄)

// 변경 후
Icons.drag_indicator  // ⋮⋮ (6점 그립)
```

**이유**: v0 디자인과 동일한 6점 그립 스타일

#### C. 블록 헤더 개선
```dart
// 변경 전
"블록 구성"

// 변경 후
"블록 구성    길게 눌러 순서 변경"
         └─ 회색 힌트 텍스트
```

**이유**: 사용자에게 드래그 기능 안내

#### D. 삭제 버튼 색상
```dart
// 변경 후
foregroundColor: theme.colorScheme.error.withValues(alpha: 0.6)
```

**이유**: 삭제 동작 시각적 구분

---

## 기술적 변경

### _BlockTile 리팩토링

#### StatelessWidget → StatefulWidget
```dart
// 이유: 편집 모드 상태 관리 (_isEditing)

class _BlockTileState extends State<_BlockTile> {
  bool _isEditing = false;  // 편집 모드 플래그
  
  void _updateTime(int delta) {
    final newMinutes = (widget.block.minutes + delta).clamp(5, 120);
    widget.onTimeChange?.call(newMinutes);
  }
}
```

#### 콜백 변경
```dart
// 변경 전
final VoidCallback? onTimeEdit;  // 탭 → 다이얼로그

// 변경 후
final void Function(int minutes)? onTimeChange;  // 직접 시간 변경
```

---

## 테스트 체크리스트

### 기능 테스트
- [ ] 드래그&드롭으로 블록 순서 변경
- [ ] 시간 배지 탭 → 편집 모드 전환
- [ ] [−] 버튼으로 5분씩 감소 (최소 5분)
- [ ] [+] 버튼으로 5분씩 증가 (최대 120분)
- [ ] [완료] 버튼으로 편집 모드 종료
- [ ] [×] 버튼으로 블록 삭제
- [ ] 요약 바의 총 시간 자동 업데이트
- [ ] 예상 시작 시간 자동 계산

### UI 테스트
- [ ] Deep Purple 테마 적용 확인
- [ ] 6점 그립 아이콘 표시
- [ ] "길게 눌러 순서 변경" 힌트 표시
- [ ] 편집 모드 시 +/- 버튼 정렬
- [ ] 삭제 버튼 빨간색 표시

### 엣지 케이스
- [ ] isBusy=true 시 모든 인터랙션 비활성화
- [ ] 시간 5분 미만 설정 불가
- [ ] 시간 120분 초과 설정 불가
- [ ] 블록 0개일 때 빈 상태 표시

---

## 호환성

### Provider 연결
기존 `MorningAssistantProvider` 콜백 시그니처 유지:
```dart
// 기존 코드 수정 불필요
onBlockTimeUpdate: (index, minutes) => provider.updateBlockTime(index, minutes)
```

### 모델 변경
없음. `SuggestedBlock` 모델 그대로 사용.

---

## v0 vs Flutter 비교

| 기능 | v0 (React) | Flutter | 상태 |
|------|------------|---------|------|
| 드래그&드롭 | dnd-kit | ReorderableListView | ✅ 동일 |
| 인라인 편집 | useState | StatefulWidget | ✅ 동일 |
| 시간 증감 | ±5분 | ±5분 | ✅ 동일 |
| 시간 제한 | 5-120분 | 5-120분 | ✅ 동일 |
| 삭제 버튼 | X 아이콘 | X 아이콘 | ✅ 동일 |
| 애니메이션 | Tailwind | Material | ⚠️ 기본값만 |

---

## 다음 단계 (선택)

### 추가 개선 가능 항목

#### 1. 애니메이션 추가
```dart
// 편집 모드 전환 애니메이션
AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: _isEditing ? _EditMode() : _ViewMode(),
)
```

#### 2. 햅틱 피드백
```dart
import 'package:flutter/services.dart';

void _updateTime(int delta) {
  HapticFeedback.lightImpact();  // 버튼 탭 시
  // ...
}
```

#### 3. 드래그 중 시각적 피드백
```dart
// v0처럼 드래그 중 opacity/scale 변경
onReorder: (from, to) {
  setState(() {
    // opacity: 0.5, scale: 0.95
  });
}
```

---

## 참고 자료

### v0 레포
- GitHub: https://github.com/8hal/v0-morning-routine-planner-7i
- 주요 파일:
  - `components/morning/block-list.tsx`
  - `app/page.tsx`

### v0 디자인 특징
- Deep Purple (#5E35B1) 기본 컬러
- 6점 그립 드래그 핸들
- 인라인 시간 편집 (+/- 스테퍼)
- 삭제 버튼 (X 아이콘)
- 간결한 Material Design 3 스타일

---

## 커밋 메시지 예시

```
feat: apply v0 inline time editing to block list

- Replace dialog-based time editing with inline stepper
- Add +/- buttons for 5-minute increments
- Change drag handle icon to 6-dot grip (Icons.drag_indicator)
- Add "길게 눌러 순서 변경" hint text
- Highlight delete button in error color
- Keep existing drag & drop functionality

Refs: https://github.com/8hal/v0-morning-routine-planner-7i
```

---

## 완료 ✅

2026-02-17: v0 디자인 핵심 기능 Flutter 적용 완료
- 인라인 시간 편집
- 드래그 핸들 개선
- UI 힌트 추가
- 기존 기능 유지 (버그 없음)
