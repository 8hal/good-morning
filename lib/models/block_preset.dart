import 'enums.dart';

/// 블록 프리셋: 타입 + 기본 시간(분)
/// 순서는 고정이며 변경 불가 (실험 중립성)
class BlockPreset {
  final String blockType;
  final int defaultMinutes;
  final String label;

  const BlockPreset({
    required this.blockType,
    required this.defaultMinutes,
    required this.label,
  });

  /// 표시용 문자열 (예: "run 25분")
  String get displayText => '$label $defaultMinutes분';
}

/// v0.1 블록 프리셋 정의
/// 순서 고정 — 정렬/추천/강조 금지
class BlockPresets {
  BlockPresets._();

  static const List<BlockPreset> office = [
    BlockPreset(blockType: 'run', defaultMinutes: 25, label: 'Run'),
    BlockPreset(blockType: 'proj', defaultMinutes: 20, label: 'Project'),
    BlockPreset(blockType: 'stretch', defaultMinutes: 10, label: 'Stretch'),
    BlockPreset(blockType: 'buffer', defaultMinutes: 15, label: 'Buffer'),
  ];

  static const List<BlockPreset> home = [
    BlockPreset(blockType: 'run', defaultMinutes: 40, label: 'Run'),
    BlockPreset(blockType: 'run', defaultMinutes: 25, label: 'Run'),
    BlockPreset(blockType: 'proj', defaultMinutes: 40, label: 'Project'),
    BlockPreset(blockType: 'proj', defaultMinutes: 20, label: 'Project'),
    BlockPreset(blockType: 'buffer', defaultMinutes: 15, label: 'Buffer'),
    BlockPreset(blockType: 'free', defaultMinutes: 30, label: 'Free'),
  ];

  /// commuteType에 따른 프리셋 반환
  static List<BlockPreset> forCommuteType(CommuteType type) {
    switch (type) {
      case CommuteType.home:
        return home;
      case CommuteType.office:
        return office;
    }
  }
}
