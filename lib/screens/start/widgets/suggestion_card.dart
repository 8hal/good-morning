import 'package:flutter/material.dart';
import '../../../models/routine_suggestion.dart';

/// AI가 제안한 루틴을 스마트 카드 형태로 표시하는 위젯
///
/// 인사, 기상 시각, 앵커 타임, 출퇴근 타입, 블록 목록, 요약을 표시하며
/// 각 항목을 인라인으로 수정할 수 있다.
class SuggestionCard extends StatelessWidget {
  final RoutineSuggestion suggestion;
  final VoidCallback onAnchorTimeTap;
  final ValueChanged<String> onCommuteTypeChanged;
  final ValueChanged<int> onBlockToggle;
  final VoidCallback onToggleSelectAll;
  final VoidCallback onStart;
  final bool isBusy;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAnchorTimeTap,
    required this.onCommuteTypeChanged,
    required this.onBlockToggle,
    required this.onToggleSelectAll,
    required this.onStart,
    this.isBusy = false,
  });

  int get _totalSelectedMinutes => suggestion.totalMinutes;

  String _estimatedStartTime() {
    final parts = suggestion.anchorTime.split(':');
    if (parts.length != 2) return '--:--';
    final anchorHour = int.tryParse(parts[0]) ?? 9;
    final anchorMinute = int.tryParse(parts[1]) ?? 0;
    final anchor = DateTime(2026, 1, 1, anchorHour, anchorMinute);
    final start = anchor.subtract(Duration(minutes: _totalSelectedMinutes));
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  }

  bool get _hasSelectedBlocks =>
      suggestion.blocks.any((b) => b.selected);

  bool get _allSelected =>
      suggestion.blocks.isNotEmpty &&
      suggestion.blocks.every((b) => b.selected);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedBlocks =
        suggestion.blocks.where((b) => b.selected).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 인사 + AI 추론
        _GreetingSection(
          greeting: suggestion.greeting,
          reasoning: suggestion.reasoning,
          wakeUpTime: suggestion.wakeUpTime,
        ),
        const SizedBox(height: 16),

        // 앵커 타임 + 출퇴근 타입
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 20),
                    const SizedBox(width: 8),
                    const Text('앵커 타임',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: isBusy ? null : onAnchorTimeTap,
                      child: Text(
                        suggestion.anchorTime,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'office',
                          label: Text('출근'),
                          icon: Icon(Icons.business)),
                      ButtonSegment(
                          value: 'home',
                          label: Text('재택'),
                          icon: Icon(Icons.home)),
                    ],
                    selected: {suggestion.commuteType},
                    onSelectionChanged: isBusy
                        ? null
                        : (set) => onCommuteTypeChanged(set.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 블록 목록 헤더
        if (suggestion.blocks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text('블록 구성', style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: isBusy ? null : onToggleSelectAll,
                  child: Text(_allSelected ? '전체 해제' : '전체 선택'),
                ),
              ],
            ),
          ),

        // 블록 리스트
        ...List.generate(suggestion.blocks.length, (index) {
          final block = suggestion.blocks[index];
          return _BlockTile(
            block: block,
            onToggle: isBusy ? null : () => onBlockToggle(index),
          );
        }),

        // 빈 프리셋 안내
        if (suggestion.blocks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.view_module_outlined,
                      size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text('블록 프리셋이 없습니다',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 4),
                  Text('아래 입력창에서 "20분 명상 추가해줘"처럼 요청하세요',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
          ),

        // 요약 + 시작 버튼
        if (suggestion.blocks.isNotEmpty) ...[
          const Divider(height: 24),
          if (_hasSelectedBlocks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${selectedBlocks.length}개 · $_totalSelectedMinutes분',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${_estimatedStartTime()} → ${suggestion.anchorTime}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed:
                  (isBusy || !_hasSelectedBlocks) ? null : onStart,
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('이대로 시작',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ],
    );
  }
}

class _GreetingSection extends StatelessWidget {
  final String greeting;
  final String reasoning;
  final String wakeUpTime;

  const _GreetingSection({
    required this.greeting,
    required this.reasoning,
    required this.wakeUpTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  greeting,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Chip(
                  avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                  label: Text(wakeUpTime),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (reasoning.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reasoning,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final SuggestedBlock block;
  final VoidCallback? onToggle;

  const _BlockTile({
    required this.block,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: block.selected
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: block.selected,
                onChanged: onToggle != null ? (_) => onToggle!() : null,
              ),
              Expanded(
                child: Text(
                  block.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    decoration: block.selected
                        ? null
                        : TextDecoration.lineThrough,
                    color: block.selected
                        ? null
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${block.minutes}분',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
