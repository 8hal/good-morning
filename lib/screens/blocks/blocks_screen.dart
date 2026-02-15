import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_block_preset.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_block_preset_provider.dart';

/// 블록 관리 화면 (생성/수정/삭제/순서 변경)
class BlocksScreen extends ConsumerStatefulWidget {
  const BlocksScreen({super.key});

  @override
  ConsumerState<BlocksScreen> createState() => _BlocksScreenState();
}

class _BlocksScreenState extends ConsumerState<BlocksScreen> {
  bool _isBusy = false;

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
        const SnackBar(content: Text('블록이 생성되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
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

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(userBlockPresetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('블록 관리'),
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _createBlock,
            icon: const Icon(Icons.add),
            tooltip: '블록 추가',
          ),
        ],
      ),
      body: presetsAsync.when(
        data: (presets) {
          if (presets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('블록이 없습니다.', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    '우측 상단 + 버튼으로 블록을 추가하세요.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            onReorder: _reorderBlock,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              return Card(
                key: ValueKey(preset.id),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle),
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
        error: (error, stack) => Center(
          child: Text('에러: $error', style: const TextStyle(color: Colors.red)),
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
