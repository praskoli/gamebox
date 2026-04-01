import '../../domain/block_mode.dart';
import '../../domain/block_position.dart';
import '../domain/difficulty_config.dart';
import '../domain/level_definition.dart';
import '../domain/level_objective.dart';

class BlockLevelCatalog {
  const BlockLevelCatalog._();

  static const int maxKingdomLevel = 100;

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
      allowBomb: false,
      bombChance: 0,
    );
  }

  static LevelDefinition timeTrial({required int levelNumber}) {
    final challenge = levelNumber.clamp(1, 10);

    final targetScore = switch (challenge) {
      1 => 260,
      2 => 320,
      3 => 380,
      4 => 450,
      5 => 520,
      6 => 600,
      7 => 680,
      8 => 760,
      9 => 840,
      _ => 920,
    };

    final seconds = switch (challenge) {
      1 => 95,
      2 => 90,
      3 => 85,
      4 => 80,
      5 => 75,
      6 => 72,
      7 => 69,
      8 => 66,
      9 => 63,
      _ => 60,
    };

    return LevelDefinition(
      levelNumber: challenge,
      title: 'Time Trial',
      subtitle: 'Beat the clock before the timer runs out.',
      objective: LevelObjective.reachScore(targetScore),
      difficulty: challenge <= 3
          ? const DifficultyConfig.timeTrial()
          : challenge <= 6
          ? const DifficultyConfig.mid()
          : const DifficultyConfig.late(),
      rewardCoins: 80 + (challenge * 12),
      rewardXp: 70 + (challenge * 14),
      timeLimitSeconds: seconds,
      deadZones: _timeTrialDeadZones(challenge),
      blockedCells: _timeTrialBlockedCells(challenge),
      allowBomb: challenge >= 4,
      bombChance: challenge >= 7 ? 0.10 : 0.06,
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
        allowBomb: false,
        bombChance: 0,
      );
    }

    if (level <= 25) {
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
        allowBomb: level >= 14,
        bombChance: level >= 20 ? 0.08 : 0.05,
      );
    }

    final hybridScore = 900 + ((level - 25) * 90);
    final hybridLines = 8 + ((level - 25) ~/ 2);

    return LevelDefinition(
      levelNumber: level,
      title: 'Kingdom Level $level',
      subtitle: 'Master precision with dual objectives and tighter boards.',
      objective: LevelObjective.hybrid(
        targetScore: hybridScore,
        targetLines: hybridLines,
      ),
      difficulty: const DifficultyConfig.late(),
      rewardCoins: 70 + (level * 5),
      rewardXp: 60 + (level * 6),
      deadZones: _kingdomDeadZones(level),
      blockedCells: _kingdomBlockedCells(level),
      allowBomb: true,
      bombChance: level >= 60 ? 0.12 : 0.09,
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

    if (level < 26) {
      return const <BlockPosition>[
        BlockPosition(1, 5),
        BlockPosition(2, 2),
        BlockPosition(5, 1),
        BlockPosition(6, 6),
      ];
    }

    if (level < 41) {
      return const <BlockPosition>[
        BlockPosition(1, 1),
        BlockPosition(1, 6),
        BlockPosition(3, 3),
        BlockPosition(4, 4),
        BlockPosition(6, 1),
        BlockPosition(6, 6),
      ];
    }

    return const <BlockPosition>[
      BlockPosition(0, 2),
      BlockPosition(0, 5),
      BlockPosition(2, 0),
      BlockPosition(2, 7),
      BlockPosition(5, 0),
      BlockPosition(5, 7),
      BlockPosition(7, 2),
      BlockPosition(7, 5),
    ];
  }

  static List<BlockPosition> _kingdomBlockedCells(int level) {
    if (level < 8) return const <BlockPosition>[];

    if (level < 16) {
      return const <BlockPosition>[
        BlockPosition(3, 3),
        BlockPosition(4, 4),
      ];
    }

    if (level < 30) {
      return const <BlockPosition>[
        BlockPosition(2, 4),
        BlockPosition(3, 3),
        BlockPosition(4, 4),
        BlockPosition(5, 2),
      ];
    }

    if (level < 50) {
      return const <BlockPosition>[
        BlockPosition(0, 0),
        BlockPosition(0, 7),
        BlockPosition(7, 0),
        BlockPosition(7, 7),
        BlockPosition(3, 4),
        BlockPosition(4, 3),
      ];
    }

    return const <BlockPosition>[
      BlockPosition(1, 3),
      BlockPosition(1, 4),
      BlockPosition(3, 1),
      BlockPosition(4, 1),
      BlockPosition(3, 6),
      BlockPosition(4, 6),
      BlockPosition(6, 3),
      BlockPosition(6, 4),
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

    if (challenge <= 6) {
      return const <BlockPosition>[
        BlockPosition(1, 6),
        BlockPosition(2, 2),
        BlockPosition(5, 5),
        BlockPosition(6, 1),
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

  static List<BlockPosition> _timeTrialBlockedCells(int challenge) {
    if (challenge <= 3) return const <BlockPosition>[];

    if (challenge <= 6) {
      return const <BlockPosition>[
        BlockPosition(3, 3),
        BlockPosition(3, 4),
        BlockPosition(4, 3),
        BlockPosition(4, 4),
      ];
    }

    return const <BlockPosition>[
      BlockPosition(2, 3),
      BlockPosition(2, 4),
      BlockPosition(3, 2),
      BlockPosition(3, 5),
      BlockPosition(4, 2),
      BlockPosition(4, 5),
      BlockPosition(5, 3),
      BlockPosition(5, 4),
    ];
  }
}