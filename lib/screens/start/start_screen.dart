import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/block_preset.dart';
import '../../models/enums.dart';
import '../../models/user_block_preset.dart';
import '../../providers/active_block_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routine_plan_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/user_block_preset_provider.dart';

/// Start 화면 - 루틴 구성 및 시작
class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  TimeOfDay _anchorTime = const TimeOfDay(hour: 9, minute: 0);
  CommuteType _commuteType = CommuteType.office;
  final Set<int> _selectedIndexes = {};
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAuth();
    });
  }

  Future<void> _ensureAuth() async {
    setState(() => _isBusy = true);
    try {
      final authService = ref.read(authServiceProvider);
      if (authService.currentUser == null) {
        await authService.signInAnonymously();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickAnchorTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _anchorTime,
    );
    if (picked != null) {
      setState(() => _anchorTime = picked);
    }
  }

  DateTime _toTodayDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _createBlock() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _BlockEditDialog(),
    );

    if (result == null) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _isBusy = true);
    try {
      final service = ref.read(userBlockPresetServiceProvider);
      await service.createPreset(
        uid: uid,
        name: result['name'] as String,
        minutes: result['minutes'] as int,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('블록이 추가되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추가 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _editBlock(UserBlockPreset preset) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BlockEditDialog(
        initialName: preset.name,
        initialMinutes: preset.minutes,
      ),
    );

    if (result == null) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _isBusy = true);
    try {
      final service = ref.read(userBlockPresetServiceProvider);
      await service.updatePreset(
        uid: uid,
        presetId: preset.id,
        name: result['name'] as String,
        minutes: result['minutes'] as int,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('블록이 수정되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteBlock(UserBlockPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('블록 삭제'),
        content: Text('"${preset.name}" 블록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _isBusy = true);
    try {
      final service = ref.read(userBlockPresetServiceProvider);
      await service.deletePreset(uid: uid, presetId: preset.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('블록이 삭제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _reorderBlock(int oldIndex, int newIndex) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final presetsAsync = ref.read(userBlockPresetsProvider);
    final presets = presetsAsync.value;
    if (presets == null || presets.isEmpty) return;

    final targetPreset = presets[oldIndex];
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;

    setState(() => _isBusy = true);
    try {
      final service = ref.read(userBlockPresetServiceProvider);
      await service.reorderPreset(
        uid: uid,
        presetId: targetPreset.id,
        newOrder: adjustedNewIndex,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('순서 변경 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _startRoutine() async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 로그인해 주세요.')),
      );
      return;
    }

    final userPresetsAsync = ref.read(userBlockPresetsProvider);
    final userPresets = userPresetsAsync.value ?? [];
    
    final selectedBlocks = <BlockPreset>[];
    for (int i = 0; i < userPresets.length; i++) {
      if (_selectedIndexes.contains(i)) {
        selectedBlocks.add(userPresets[i].toBlockPreset());
      }
    }

    if (selectedBlocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('최소 1개 블록을 선택해 주세요.')),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final engine = ref.read(blockEngineProvider);
      final anchor = _toTodayDateTime(_anchorTime);

      final session = await engine.startSession(
        uid: uid,
        anchorTime: anchor,
        commuteType: _commuteType,
        anchorSource: AnchorSource.manual,
      );

      if (!mounted) return;

      if (session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 활성 세션이 있습니다.')),
        );
        return;
      }

      final firstBlock = await engine.startBlock(
        sessionId: session.id,
        preset: selectedBlocks.first,
      );
      if (firstBlock == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('첫 블록 시작에 실패했습니다.')),
        );
        return;
      }

      ref.read(activeSessionProvider.notifier).setSession(session);
      ref.read(activeBlockProvider.notifier).setBlock(firstBlock);
      ref.read(routinePlanProvider.notifier).setPlan(selectedBlocks);

      if (!mounted) return;
      context.push('/now');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('루틴 시작 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final activeSession = ref.watch(activeSessionProvider);
    final userPresetsAsync = ref.watch(userBlockPresetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good Morning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isBusy ? null : _createBlock,
            tooltip: '블록 추가',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Anchor 시각 + 출근 형태
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 20),
                        const SizedBox(width: 8),
                        const Text('Anchor 시각:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _isBusy ? null : _pickAnchorTime,
                          child: Text(_anchorTime.format(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<CommuteType>(
                      segments: const [
                        ButtonSegment(value: CommuteType.office, label: Text('출근')),
                        ButtonSegment(value: CommuteType.home, label: Text('재택')),
                      ],
                      selected: {_commuteType},
                      onSelectionChanged: _isBusy ? null : (set) {
                        setState(() => _commuteType = set.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 블록 목록 헤더
            Row(
              children: [
                Text(
                  '오늘의 루틴',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '드래그로 순서 변경',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // 블록 목록 (드래그 가능)
            Expanded(
              child: userPresetsAsync.when(
                data: (presets) {
                  if (presets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('블록이 없습니다.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _createBlock,
                            icon: const Icon(Icons.add),
                            label: const Text('첫 블록 추가하기'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ReorderableListView.builder(
                    onReorder: _reorderBlock,
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      final isSelected = _selectedIndexes.contains(index);
                      
                      return Card(
                        key: ValueKey(preset.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isSelected ? Colors.blue.shade50 : null,
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.drag_handle, color: Colors.grey),
                              const SizedBox(width: 8),
                              Checkbox(
                                value: isSelected,
                                onChanged: _isBusy ? null : (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedIndexes.add(index);
                                    } else {
                                      _selectedIndexes.remove(index);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                          title: Text(preset.name),
                          subtitle: Text('${preset.minutes}분'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: _isBusy ? null : () => _editBlock(preset),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: _isBusy ? null : () => _deleteBlock(preset),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('에러: $e', style: const TextStyle(color: Colors.red))),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 루틴 시작 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isBusy ? null : _startRoutine,
                child: const Text('루틴 시작'),
              ),
            ),
            
            if (activeSession.value != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.push('/now'),
                child: const Text('진행 중인 루틴 보기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 블록 생성/수정 다이얼로그
class _BlockEditDialog extends StatefulWidget {
  final String? initialName;
  final int? initialMinutes;

  const _BlockEditDialog({
    this.initialName,
    this.initialMinutes,
  });

  @override
  State<_BlockEditDialog> createState() => _BlockEditDialogState();
}

class _BlockEditDialogState extends State<_BlockEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _minutesController = TextEditingController(
      text: widget.initialMinutes?.toString() ?? '10',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final minutesText = _minutesController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('블록 이름을 입력하세요.')),
      );
      return;
    }

    final minutes = int.tryParse(minutesText);
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 시간(분)을 입력하세요.')),
      );
      return;
    }

    Navigator.pop(context, {'name': name, 'minutes': minutes});
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;

    return AlertDialog(
      title: Text(isEdit ? '블록 수정' : '블록 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '블록 이름',
              hintText: '예: 명상, 샤워',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _minutesController,
            decoration: const InputDecoration(
              labelText: '시간 (분)',
              hintText: '10',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(isEdit ? '수정' : '추가'),
        ),
      ],
    );
  }
}
