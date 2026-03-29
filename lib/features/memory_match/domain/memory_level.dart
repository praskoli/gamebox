import '../config/difficulty_config.dart';

class MemoryLevel {
  const MemoryLevel({
    required this.id,
    required this.worldId,
    required this.levelNumber,
    required this.unlocksAtLevel,
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
    required this.boardSeed,
    required this.tileValues,
  });

  final String id;
  final String worldId;
  final int levelNumber;
  final int unlocksAtLevel;

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
  final int boardSeed;
  final List<String> tileValues;

  int get totalTiles => rows * columns;
  int get totalPairs => totalTiles ~/ 2;

  bool get hasPreview =>
      specialType != MemorySpecialLevelType.speed && previewMs > 0;

  bool get isRewardLevel => specialType == MemorySpecialLevelType.reward;
  bool get isSpeedLevel => specialType == MemorySpecialLevelType.speed;
  bool get isMemoryProLevel => specialType == MemorySpecialLevelType.memoryPro;

  MemoryLevel copyWith({
    String? id,
    String? worldId,
    int? levelNumber,
    int? unlocksAtLevel,
    int? rows,
    int? columns,
    int? previewMs,
    int? flipBackDelayMs,
    int? matchPoints,
    int? mismatchPenalty,
    int? completionBonus,
    int? timeBonusFast,
    int? timeBonusSlow,
    int? baseCoins,
    int? baseXp,
    int? targetStarsMoves,
    MemorySpecialLevelType? specialType,
    bool? enableDistractors,
    int? boardSeed,
    List<String>? tileValues,
  }) {
    return MemoryLevel(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      levelNumber: levelNumber ?? this.levelNumber,
      unlocksAtLevel: unlocksAtLevel ?? this.unlocksAtLevel,
      rows: rows ?? this.rows,
      columns: columns ?? this.columns,
      previewMs: previewMs ?? this.previewMs,
      flipBackDelayMs: flipBackDelayMs ?? this.flipBackDelayMs,
      matchPoints: matchPoints ?? this.matchPoints,
      mismatchPenalty: mismatchPenalty ?? this.mismatchPenalty,
      completionBonus: completionBonus ?? this.completionBonus,
      timeBonusFast: timeBonusFast ?? this.timeBonusFast,
      timeBonusSlow: timeBonusSlow ?? this.timeBonusSlow,
      baseCoins: baseCoins ?? this.baseCoins,
      baseXp: baseXp ?? this.baseXp,
      targetStarsMoves: targetStarsMoves ?? this.targetStarsMoves,
      specialType: specialType ?? this.specialType,
      enableDistractors: enableDistractors ?? this.enableDistractors,
      boardSeed: boardSeed ?? this.boardSeed,
      tileValues: tileValues ?? this.tileValues,
    );
  }
}