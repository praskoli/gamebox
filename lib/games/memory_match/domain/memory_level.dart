// lib/features/memory_match/domain/memory_level.dart
import '../../../games/memory_match/domain/memory_theme_pack.dart';

class MemoryLevel {
  const MemoryLevel({
    required this.levelNumber,
    required this.worldIndex,
    required this.theme,
    required this.gridColumns,
    required this.gridRows,
    required this.previewDurationMs,
    required this.flipBackDelayMs,
    required this.rewardCoins,
    required this.isRewardLevel,
    required this.isSpeedLevel,
    required this.isMemoryProLevel,
  });

  final int levelNumber;
  final int worldIndex;
  final MemoryThemePack theme;
  final int gridColumns;
  final int gridRows;
  final int previewDurationMs;
  final int flipBackDelayMs;
  final int rewardCoins;
  final bool isRewardLevel;
  final bool isSpeedLevel;
  final bool isMemoryProLevel;

  int get columns => gridColumns;
  int get rows => gridRows;
  String get worldId => theme.id;

  int get totalCards => gridColumns * gridRows;
  int get totalPairs => totalCards ~/ 2;

  bool get isEvenGrid => totalCards.isEven;

  String get levelTitle => 'Level $levelNumber';

  String get stageBadge {
    if (isSpeedLevel) return 'Speed';
    if (isMemoryProLevel) return 'Memory Pro';
    if (isRewardLevel) return 'Reward';
    return 'Classic';
  }

  String get worldLabel => '${theme.emoji} ${theme.worldTitle}';

  MemoryLevel copyWith({
    int? levelNumber,
    int? worldIndex,
    MemoryThemePack? theme,
    int? gridColumns,
    int? gridRows,
    int? previewDurationMs,
    int? flipBackDelayMs,
    int? rewardCoins,
    bool? isRewardLevel,
    bool? isSpeedLevel,
    bool? isMemoryProLevel,
  }) {
    return MemoryLevel(
      levelNumber: levelNumber ?? this.levelNumber,
      worldIndex: worldIndex ?? this.worldIndex,
      theme: theme ?? this.theme,
      gridColumns: gridColumns ?? this.gridColumns,
      gridRows: gridRows ?? this.gridRows,
      previewDurationMs: previewDurationMs ?? this.previewDurationMs,
      flipBackDelayMs: flipBackDelayMs ?? this.flipBackDelayMs,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      isRewardLevel: isRewardLevel ?? this.isRewardLevel,
      isSpeedLevel: isSpeedLevel ?? this.isSpeedLevel,
      isMemoryProLevel: isMemoryProLevel ?? this.isMemoryProLevel,
    );
  }
}