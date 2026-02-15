import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

/// Settings 화면
/// - officeCommuteMinutes (출근 소요 시간)
/// - 캘린더 사용 토글 (v0.1.5)
/// - 로그아웃
///
/// Step 0/4 최소 구현:
/// - officeCommuteMinutes 저장
/// - 캘린더 사용 토글 저장
/// - 로그아웃
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _commuteController = TextEditingController();
  bool _calendarEnabled = false;
  CommuteType _defaultCommuteType = CommuteType.office;
  bool _initialized = false;

  @override
  void dispose() {
    _commuteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final settingsAsync = ref.read(settingsProvider);
    final current = settingsAsync.value;
    if (current == null) return;

    final commuteMinutes = int.tryParse(_commuteController.text.trim()) ?? 60;
    final next = current.copyWith(
      officeCommuteMinutes: commuteMinutes,
      calendarEnabled: _calendarEnabled,
      defaultCommuteType: _defaultCommuteType,
    );
    await ref.read(settingsProvider.notifier).updateSettings(next);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장되었습니다.')),
    );
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그아웃되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: settingsAsync.when(
        data: (settings) {
          if (!_initialized) {
            _commuteController.text = settings.officeCommuteMinutes.toString();
            _calendarEnabled = settings.calendarEnabled;
            _defaultCommuteType = settings.defaultCommuteType;
            _initialized = true;
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 블록 관리 바로가기
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.view_module),
                    title: const Text('블록 관리'),
                    subtitle: const Text('Start 화면에서 블록 관리'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/start'),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commuteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '출근 소요 시간(분)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('캘린더 사용 (v0.1.5)'),
                  value: _calendarEnabled,
                  onChanged: (v) => setState(() => _calendarEnabled = v),
                ),
                const SizedBox(height: 12),
                SegmentedButton<CommuteType>(
                  segments: const [
                    ButtonSegment(value: CommuteType.office, label: Text('출근')),
                    ButtonSegment(value: CommuteType.home, label: Text('재택')),
                  ],
                  selected: {_defaultCommuteType},
                  onSelectionChanged: (set) {
                    setState(() => _defaultCommuteType = set.first);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: const Text('설정 저장'),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _signOut,
                  child: const Text('로그아웃'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('설정 로드 실패: $e')),
      ),
    );
  }
}
