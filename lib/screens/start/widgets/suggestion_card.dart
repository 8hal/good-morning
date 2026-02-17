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
  final ValueChanged<int> onBlockDelete;
  final void Function(int from, int to) onBlockReorder;
  final void Function(int index, int minutes) onBlockTimeUpdate;
  final VoidCallback onStart;
  final bool isBusy;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onAnchorTimeTap,
    required this.onCommuteTypeChanged,
    required this.onBlockDelete,
    required this.onBlockReorder,
    required this.onBlockTimeUpdate,
    required this.onStart,
    this.isBusy = false,
  });

  int get _totalMinutes => suggestion.blocks.fold(0, (sum, b) => sum + b.minutes);

  String _estimatedStartTime() {
    final parts = suggestion.anchorTime.split(':');
    if (parts.length != 2) return '--:--';
    final anchorHour = int.tryParse(parts[0]) ?? 9;
    final anchorMinute = int.tryParse(parts[1]) ?? 0;
    final anchor = DateTime(2026, 1, 1, anchorHour, anchorMinute);
    final start = anchor.subtract(Duration(minutes: _totalMinutes));
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
  }

  bool get _hasBlocks => suggestion.blocks.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        if (_hasBlocks)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text('블록 구성', style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                Text(
                  '길게 눌러 순서 변경',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

        // 블록 리스트 (드래그앤드롭)
        if (_hasBlocks)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: isBusy ? (_, __) {} : onBlockReorder,
            itemCount: suggestion.blocks.length,
            itemBuilder: (context, index) {
              final block = suggestion.blocks[index];
              return ReorderableDragStartListener(
                key: ValueKey('block-${block.presetId}-$index'),
                index: index,
                enabled: !isBusy,
                child: _BlockTile(
                  block: block,
                  index: index,
                  onDelete: isBusy ? null : () => onBlockDelete(index),
                  onTimeChange: isBusy 
                      ? null 
                      : (minutes) => onBlockTimeUpdate(index, minutes),
                  isDragEnabled: !isBusy,
                ),
              );
            },
          ),

        // 빈 프리셋 안내
        if (!_hasBlocks)
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
        if (_hasBlocks) ...[
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${suggestion.blocks.length}개 · $_totalMinutes분',
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
              onPressed: isBusy ? null : onStart,
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

class _BlockTile extends StatefulWidget {
  final SuggestedBlock block;
  final int index;
  final VoidCallback? onDelete;
  final void Function(int minutes)? onTimeChange;
  final bool isDragEnabled;

  const _BlockTile({
    required this.block,
    required this.index,
    this.onDelete,
    this.onTimeChange,
    this.isDragEnabled = true,
  });

  @override
  State<_BlockTile> createState() => _BlockTileState();
}

class _BlockTileState extends State<_BlockTile> {
  bool _isEditing = false;

  void _updateTime(int delta) {
    final newMinutes = (widget.block.minutes + delta).clamp(5, 120);
    widget.onTimeChange?.call(newMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            // 드래그 핸들 (6점 그립)
            Icon(
              Icons.drag_indicator,
              size: 20,
              color: widget.isDragEnabled
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 12),
            
            // 블록 이름
            Expanded(
              child: Text(
                widget.block.name,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            
            // 시간 편집 (인라인 스테퍼)
            if (_isEditing) ...[
              // 감소 버튼
              IconButton(
                icon: const Icon(Icons.remove, size: 18),
                onPressed: widget.onTimeChange != null 
                    ? () => _updateTime(-5) 
                    : null,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              
              // 현재 시간
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  '${widget.block.minutes}분',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              
              // 증가 버튼
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: widget.onTimeChange != null 
                    ? () => _updateTime(5) 
                    : null,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              
              // 완료 버튼
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('완료', style: TextStyle(fontSize: 12)),
              ),
            ] else ...[
              // 시간 배지 (탭하여 편집 모드)
              InkWell(
                onTap: widget.onTimeChange != null
                    ? () => setState(() => _isEditing = true)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.block.minutes}분',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            
            // 삭제 버튼
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onDelete,
              visualDensity: VisualDensity.compact,
              tooltip: '삭제',
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.error.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
