import '../../domain/block_mode.dart';
import '../../domain/block_position.dart';
import '../domain/difficulty_config.dart';
import '../domain/level_definition.dart';
import '../domain/level_objective.dart';

class BlockLevelCatalog {
  const BlockLevelCatalog._();

  static const int maxKingdomLevel = 30;

  static LevelDefinition forMode(
      BlockMode mode, {
        required int levelNumber,
      }) {
    switch (mode) {
      case BlockMode.kingdom:
        return kingdom(levelNumber);
      case BlockMode.timeTrial:
        return timeTrial(levelNumber: levelNumber);
      case BlockMode.endless:
        return endless();
    }
  }

  static LevelDefinition endless() {
    return const LevelDefinition(
      levelNumber: 1,
      title: 'Endless Classic',
      subtitle: 'Survive as long as you can and stack clean combos.',
      objective: LevelObjective.survive(),
      difficulty: DifficultyConfig.mid(),
      rewardCoins: 0,
      rewardXp: 0,
    );
  }

  static LevelDefinition timeTrial({required int levelNumber}) {
    final challenge = levelNumber.clamp(1, 5);
    final targetScore = switch (challenge) {
      1 => 260,
      2 => 320,
      3 => 380,
      4 => 450,
      _ => 520,
    };

    final seconds = switch (challenge) {
      1 => 95,
      2 => 90,
      3 => 85,
      4 => 80,
      _ => 75,
    };

    return LevelDefinition(
      levelNumber: challenge,
      title: 'Time Trial',
      subtitle: 'Beat the clock before the timer runs out.',
      objective: LevelObjective.reachScore(targetScore),
      difficulty: const DifficultyConfig.timeTrial(),
      rewardCoins: 80 + (challenge * 10),
      rewardXp: 70 + (challenge * 12),
      timeLimitSeconds: seconds,
      deadZones: _timeTrialDeadZones(challenge),
      blockedCells: _timeTrialBlockedCells(challenge),
    );
  }

  static LevelDefinition kingdom(int levelNumber) {
    final level = levelNumber.clamp(1, maxKingdomLevel);

    if (level <= 10) {
      return LevelDefinition(
        levelNumber: level,
        title: 'Kingdom Level $level',
        subtitle: 'Lay stable foundations with friendly shapes.',
        objective: LevelObjective.clearLines(2 + level),
        difficulty: const DifficultyConfig.early(),
        rewardCoins: 24 + (level * 3),
        rewardXp: 18 + (level * 4),
        deadZones: _kingdomDeadZones(level),
        blockedCells: _kingdomBlockedCells(level),
      );
    }

    if (level <= 20) {
      final targetScore = 260 + ((level - 10) * 85);
      return LevelDefinition(
        levelNumber: level,
        title: 'Kingdom Level $level',
        subtitle: 'Build momentum with scoring-focused missions.',
        objective: LevelObjective.reachScore(targetScore),
        difficulty: const DifficultyConfig.mid(),
        rewardCoins: 42 + (level * 4),
        rewardXp: 34 + (level * 5),
        deadZones: _kingdomDeadZones(level),
        blockedCells: _kingdomBlockedCells(level),
      );
    }

    final hybridScore = 900 + ((level - 20) * 120);
    final hybridLines = 8 + (level - 20);

    return LevelDefinition(
      levelNumber: level,
      title: 'Kingdom Level $level',
      subtitle: 'Master precise play with dual objectives.',
      objective: LevelObjective.hybrid(
        targetScore: hybridScore,
        targetLines: hybridLines,
      ),
      difficulty: const DifficultyConfig.late(),
      rewardCoins: 70 + (level * 5),
      rewardXp: 60 + (level * 6),
      deadZones: _kingdomDeadZones(level),
      blockedCells: _kingdomBlockedCells(level),
    );
  }

  static List<BlockPosition> _kingdomDeadZones(int level) {
    if (level < 6) return const <BlockPosition>[];

    if (level < 11) {
      return const <BlockPosition>[
        BlockPosition(1, 1),
        BlockPosition(6, 6),
      ];
    }

    if (level < 16) {
      return const <BlockPosition>[
        BlockPosition(0, 3),
        BlockPosition(3, 0),
        BlockPosition(4, 7),
        BlockPosition(7, 4),
      ];
    }

    if (level < 21) {
      return const <BlockPosition>[
        BlockPosition(1, 5),
        BlockPosition(2, 2),
        BlockPosition(5, 1),
        BlockPosition(6, 6),
      ];
    }

    return const <BlockPosition>[
      BlockPosition(1, 1),
      BlockPosition(1, 6),
      BlockPosition(3, 3),
      BlockPosition(4, 4),
      BlockPosition(6, 1),
      BlockPosition(6, 6),
    ];
  }

  static List<BlockPosition> _kingdomBlockedCells(int level) {
    if (level < 8) return const <BlockPosition>[];

    if (level < 13) {
      return const <BlockPosition>[
        BlockPosition(3, 3),
        BlockPosition(4, 4),
      ];
    }

    if (level < 21) {
      return const <BlockPosition>[
        BlockPosition(2, 4),
        BlockPosition(3, 3),
        BlockPosition(4, 4),
        BlockPosition(5, 2),
      ];
    }

    return const <BlockPosition>[
      BlockPosition(0, 0),
      BlockPosition(0, 7),
      BlockPosition(7, 0),
      BlockPosition(7, 7),
      BlockPosition(3, 4),
      BlockPosition(4, 3),
    ];
  }

  static List<BlockPosition> _timeTrialDeadZones(int challenge) {
    if (challenge <= 2) return const <BlockPosition>[];

    if (challenge == 3) {
      return const <BlockPosition>[
        BlockPosition(2, 2),
        BlockPosition(5, 5),
      ];
    }

    return const <BlockPosition>[
      BlockPosition(1, 6),
      BlockPosition(2, 2),
      BlockPosition(5, 5),
      BlockPosition(6, 1),
    ];
  }

  static List<BlockPosition> _timeTrialBlockedCells(int challenge) {
    if (challenge <= 3) return const <BlockPosition>[];

    return const <BlockPosition>[
      BlockPosition(3, 3),
      BlockPosition(3, 4),
      BlockPosition(4, 3),
      BlockPosition(4, 4),
    ];
  }
}