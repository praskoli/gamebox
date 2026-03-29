import 'package:flutter/material.dart';

import '../config/difficulty_config.dart';
import '../domain/memory_level.dart';
import '../domain/memory_theme_pack.dart';

class MemoryWorldRegistry {
  static const String fruitsWorldId = 'fruits_world';

  static final Map<String, MemoryThemePack> _worlds = <String, MemoryThemePack>{
    fruitsWorldId: const MemoryThemePack(
      id: fruitsWorldId,
      title: 'Fruit Fiesta',
      worldTitle: 'Fruit Fiesta',
      backgroundTop: Color(0xFFFFF7ED),
      backgroundBottom: Color(0xFFFFE4E6),
      pathColor: Color(0xFFF59E0B),
      nodeColor: Color(0xFFFF8A4C),
      tileGradientStart: Color(0xFFFF8A4C),
      tileGradientEnd: Color(0xFFEC4899),
      items: [
        '🍎', '🍐', '🍊', '🍋', '🍉', '🍇', '🍓', '🫐',
        '🍒', '🍑', '🥝', '🍍', '🥥', '🥭', '🍌', '🍏',
        '🍈', '🍅', '🥕', '🌽', '🍄', '🥔', '🥦', '🫑',
        '🍆', '🥒', '🧄', '🧅', '🥜', '🌶️', '🥬', '🫛',
        '🍪', '🧁', '🍭', '🍬', '🍩', '🍰', '🍫', '🍿',
      ],
      worldEmoji: '🍓',
    ),
  };

  static MemoryThemePack byWorldId(String worldId) {
    final theme = _worlds[worldId];
    if (theme == null) {
      throw StateError('Unknown memory world: $worldId');
    }
    return theme;
  }

  static MemoryLevel generateLevel(String worldId, int levelNumber) {
    if (levelNumber <= 0) {
      throw ArgumentError.value(
        levelNumber,
        'levelNumber',
        'Level number must be greater than 0.',
      );
    }

    final theme = byWorldId(worldId);

    final config = MemoryDifficultyConfig.forLevel(
      worldId: worldId,
      levelNumber: levelNumber,
      fallbackItems: theme.items,
    );

    return MemoryLevel(
      id: '${worldId}_level_$levelNumber',
      worldId: worldId,
      levelNumber: levelNumber,
      unlocksAtLevel: levelNumber,
      rows: config.rows,
      columns: config.columns,
      previewMs: config.previewMs,
      flipBackDelayMs: config.flipBackDelayMs,
      matchPoints: config.matchPoints,
      mismatchPenalty: config.mismatchPenalty,
      completionBonus: config.completionBonus,
      timeBonusFast: config.timeBonusFast,
      timeBonusSlow: config.timeBonusSlow,
      baseCoins: config.baseCoins,
      baseXp: config.baseXp,
      targetStarsMoves: config.targetStarsMoves,
      specialType: config.specialType,
      enableDistractors: config.enableDistractors,
      boardSeed: config.boardSeed,
      tileValues: config.tileValues,
    );
  }

  static List<MemoryLevel> generateLevelWindow({
    required String worldId,
    required int startLevel,
    int count = 60,
  }) {
    return List<MemoryLevel>.generate(
      count,
          (index) => generateLevel(worldId, startLevel + index),
      growable: false,
    );
  }
}