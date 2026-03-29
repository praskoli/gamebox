import 'dart:math' as math;

enum MemorySpecialLevelType {
  normal,
  reward,
  speed,
  memoryPro,
}

class MemoryDifficultyConfig {
  const MemoryDifficultyConfig({
    required this.rows,
    required this.columns,
    required this.previewMs,
    required this.flipBackDelayMs,
    required this.matchPoints,
    required this.mismatchPenalty,
    required this.completionBonus,
    required this.timeBonusFast,
    required this.timeBonusSlow,
    required this.baseCoins,
    required this.baseXp,
    required this.targetStarsMoves,
    required this.specialType,
    required this.enableDistractors,
    required this.tileValues,
    required this.boardSeed,
  });

  final int rows;
  final int columns;
  final int previewMs;
  final int flipBackDelayMs;
  final int matchPoints;
  final int mismatchPenalty;
  final int completionBonus;
  final int timeBonusFast;
  final int timeBonusSlow;
  final int baseCoins;
  final int baseXp;
  final int targetStarsMoves;
  final MemorySpecialLevelType specialType;
  final bool enableDistractors;
  final List<String> tileValues;
  final int boardSeed;

  bool get hasPreview =>
      specialType != MemorySpecialLevelType.speed && previewMs > 0;

  static MemoryDifficultyConfig forLevel({
    required String worldId,
    required int levelNumber,
    required List<String> fallbackItems,
  }) {
    final specialType = _specialTypeForLevel(levelNumber);
    final boardSeed = _stableSeed(worldId, levelNumber);

    late int rows;
    late int columns;
    late int previewMs;
    late int flipBackDelayMs;
    late int matchPoints;
    late int mismatchPenalty;
    late int completionBonus;
    late int timeBonusFast;
    late int timeBonusSlow;
    late int baseCoins;
    late int baseXp;
    late int targetStarsMoves;

    if (levelNumber <= 10) {
      rows = 4;
      columns = 4;
      previewMs = _scaleDown(levelNumber, 1, 10, 2500, 1600);
      flipBackDelayMs = _scaleDown(levelNumber, 1, 10, 800, 650);
      matchPoints = 110;
      mismatchPenalty = 12;
      completionBonus = 180;
      timeBonusFast = 35;
      timeBonusSlow = 16;
      baseCoins = 10 + ((levelNumber - 1) ~/ 3);
      baseXp = 20 + ((levelNumber - 1) * 2);
      targetStarsMoves = 10;
    } else if (levelNumber <= 25) {
      rows = 4;
      columns = 4;
      previewMs = _scaleDown(levelNumber, 11, 25, 1550, 850);
      flipBackDelayMs = _scaleDown(levelNumber, 11, 25, 620, 500);
      matchPoints = 130;
      mismatchPenalty = 16;
      completionBonus = 240;
      timeBonusFast = 42;
      timeBonusSlow = 20;
      baseCoins = 14 + ((levelNumber - 11) ~/ 3);
      baseXp = 28 + ((levelNumber - 11) * 2);
      targetStarsMoves = 9;
    } else if (levelNumber <= 30) {
      rows = 5;
      columns = 4;
      previewMs = _scaleDown(levelNumber, 26, 30, 900, 650);
      flipBackDelayMs = _scaleDown(levelNumber, 26, 30, 500, 470);
      matchPoints = 150;
      mismatchPenalty = 18;
      completionBonus = 320;
      timeBonusFast = 55;
      timeBonusSlow = 26;
      baseCoins = 18 + (levelNumber - 26);
      baseXp = 40 + ((levelNumber - 26) * 2);
      targetStarsMoves = 12;
    } else {
      rows = 8;
      columns = 8;
      previewMs = _scaleDown(levelNumber, 31, 80, 800, 500);
      flipBackDelayMs = _scaleDown(levelNumber, 31, 80, 470, 450);
      matchPoints = 180;
      mismatchPenalty = 22;
      completionBonus = 700;
      timeBonusFast = 80;
      timeBonusSlow = 32;
      baseCoins = 22 + math.min(3, (levelNumber - 31) ~/ 15);
      baseXp = 48 + math.min(2, (levelNumber - 31) ~/ 20);
      targetStarsMoves = 36;
    }

    if (specialType == MemorySpecialLevelType.reward) {
      previewMs = math.max(previewMs, 1700);
      flipBackDelayMs = 700;
      mismatchPenalty = math.max(8, mismatchPenalty - 6);
      completionBonus += 160;
      baseCoins += 10;
      baseXp += 8;
      targetStarsMoves += 2;
    } else if (specialType == MemorySpecialLevelType.speed) {
      previewMs = 0;
      flipBackDelayMs = 450;
      matchPoints += 24;
      completionBonus += 100;
      baseCoins += 4;
      baseXp += 5;
    } else if (specialType == MemorySpecialLevelType.memoryPro) {
      previewMs = math.min(previewMs, 600);
      flipBackDelayMs = math.min(flipBackDelayMs, 460);
      matchPoints += 28;
      completionBonus += 120;
      baseCoins += 5;
      baseXp += 6;
    }

    final enableDistractors = levelNumber >= 15;

    return MemoryDifficultyConfig(
      rows: rows,
      columns: columns,
      previewMs: previewMs,
      flipBackDelayMs: flipBackDelayMs,
      matchPoints: matchPoints,
      mismatchPenalty: mismatchPenalty,
      completionBonus: completionBonus,
      timeBonusFast: timeBonusFast,
      timeBonusSlow: timeBonusSlow,
      baseCoins: baseCoins.clamp(10, 25),
      baseXp: baseXp.clamp(20, 50),
      targetStarsMoves: targetStarsMoves,
      specialType: specialType,
      enableDistractors: enableDistractors,
      tileValues: _buildTileValues(
        pairCount: (rows * columns) ~/ 2,
        seed: boardSeed,
        enableDistractors: enableDistractors,
        fallbackItems: fallbackItems,
      ),
      boardSeed: boardSeed,
    );
  }

  static MemorySpecialLevelType _specialTypeForLevel(int levelNumber) {
    if (levelNumber % 5 != 0) {
      return MemorySpecialLevelType.normal;
    }

    final bucket = ((levelNumber ~/ 5) - 1) % 3;
    switch (bucket) {
      case 0:
        return MemorySpecialLevelType.reward;
      case 1:
        return MemorySpecialLevelType.speed;
      default:
        return MemorySpecialLevelType.memoryPro;
    }
  }

  static int _scaleDown(
      int level,
      int startLevel,
      int endLevel,
      int startValue,
      int endValue,
      ) {
    if (endLevel <= startLevel) return endValue;
    final t = ((level - startLevel) / (endLevel - startLevel)).clamp(0.0, 1.0);
    return (startValue + ((endValue - startValue) * t)).round();
  }

  static int _stableSeed(String worldId, int levelNumber) {
    var hash = 17;
    for (final unit in worldId.codeUnits) {
      hash = 37 * hash + unit;
    }
    hash = 37 * hash + levelNumber;
    return hash & 0x7fffffff;
  }

  static List<String> _buildTileValues({
    required int pairCount,
    required int seed,
    required bool enableDistractors,
    required List<String> fallbackItems,
  }) {
    const distractorPriority = <String>[
      '🍋', '🍌', '🍐', '🥝', '🍏', '🍈', '🥭', '🍑',
      '🫐', '🍇', '🍒', '🍓', '🥥', '🍍', '🍊', '🍅',
      '🌽', '🥕', '🥔', '🍄', '🥒', '🫑', '🍬', '🍭',
      '🍪', '🍩', '🍫', '🧁', '🍰', '🍿', '🥜', '🫛',
    ];

    final merged = <String>[
      ...distractorPriority,
      ...fallbackItems,
    ].toSet().toList();

    final shuffled = List<String>.from(merged)..shuffle(math.Random(seed));

    if (!enableDistractors) {
      final normal = List<String>.from(fallbackItems)..shuffle(math.Random(seed));
      return normal.take(pairCount).toList(growable: false);
    }

    return shuffled.take(pairCount).toList(growable: false);
  }
}