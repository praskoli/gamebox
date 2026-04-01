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
      1 => 240,
      2 => 300,
      3 => 360,
      4 => 430,
      5 => 500,
      6 => 580,
      7 => 660,
      8 => 740,
      9 => 820,
      _ => 900,
    };

    final seconds = switch (challenge) {
      1 => 95,
      2 => 90,
      3 => 86,
      4 => 82,
      5 => 78,
      6 => 74,
      7 => 70,
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
      rewardCoins: 90 + (challenge * 12),
      rewardXp: 80 + (challenge * 14),
      timeLimitSeconds: seconds,
      deadZones: _timeTrialDeadZones(challenge),
      blockedCells: _timeTrialBlockedCells(challenge),
      allowBomb: challenge >= 5,
      bombChance: challenge >= 8 ? 0.08 : 0.05,
    );
  }

  static LevelDefinition kingdom(int levelNumber) {
    final level = levelNumber.clamp(1, maxKingdomLevel);

    if (level <= 10) {
      return LevelDefinition(
        levelNumber: level,
        title: 'Kingdom Level $level',
        subtitle: 'Friendly layouts to build confidence and flow.',
        objective: LevelObjective.clearLines(_earlyTargetLines(level)),
        difficulty: _earlyDifficulty(level),
        rewardCoins: 24 + (level * 3),
        rewardXp: 18 + (level * 4),
        deadZones: _kingdomDeadZones(level),
        blockedCells: _kingdomBlockedCells(level),
        allowBomb: false,
        bombChance: 0,
      );
    }

    if (level <= 30) {
      return LevelDefinition(
        levelNumber: level,
        title: 'Kingdom Level $level',
        subtitle: 'More pressure, tighter boards, and tactical recovery.',
        objective: LevelObjective.reachScore(_midTargetScore(level)),
        difficulty: _midDifficulty(level),
        rewardCoins: 46 + (level * 4),
        rewardXp: 36 + (level * 5),
        deadZones: _kingdomDeadZones(level),
        blockedCells: _kingdomBlockedCells(level),
        allowBomb: level >= 14,
        bombChance: _midBombChance(level),
      );
    }

    return LevelDefinition(
      levelNumber: level,
      title: 'Kingdom Level $level',
      subtitle: 'Strategic play with dual-objective pressure.',
      objective: LevelObjective.hybrid(
        targetScore: _lateTargetScore(level),
        targetLines: _lateTargetLines(level),
      ),
      difficulty: _lateDifficulty(level),
      rewardCoins: 80 + (level * 5),
      rewardXp: 70 + (level * 6),
      deadZones: _kingdomDeadZones(level),
      blockedCells: _kingdomBlockedCells(level),
      allowBomb: true,
      bombChance: _lateBombChance(level),
    );
  }

  static int _earlyTargetLines(int level) {
    if (level <= 3) return 3;
    if (level <= 6) return 4;
    if (level <= 8) return 5;
    return 6;
  }

  static int _midTargetScore(int level) {
    if (level <= 15) return 320 + ((level - 10) * 55);
    if (level <= 22) return 620 + ((level - 15) * 65);
    return 1075 + ((level - 22) * 75);
  }

  static int _lateTargetScore(int level) {
    if (level <= 45) return 1550 + ((level - 30) * 80);
    if (level <= 70) return 2750 + ((level - 45) * 90);
    return 5000 + ((level - 70) * 110);
  }

  static int _lateTargetLines(int level) {
    if (level <= 40) return 8;
    if (level <= 55) return 9;
    if (level <= 75) return 10;
    return 11;
  }

  static DifficultyConfig _earlyDifficulty(int level) {
    if (level <= 4) return const DifficultyConfig.early();
    if (level <= 7) return const DifficultyConfig(
      traySize: 3,
      friendlyWeight: 68,
      standardWeight: 28,
      trickyWeight: 4,
    );
    return const DifficultyConfig(
      traySize: 3,
      friendlyWeight: 60,
      standardWeight: 34,
      trickyWeight: 6,
    );
  }

  static DifficultyConfig _midDifficulty(int level) {
    if (level <= 15) {
      return const DifficultyConfig(
        traySize: 3,
        friendlyWeight: 48,
        standardWeight: 40,
        trickyWeight: 12,
      );
    }
    if (level <= 22) {
      return const DifficultyConfig.mid();
    }
    return const DifficultyConfig(
      traySize: 3,
      friendlyWeight: 30,
      standardWeight: 42,
      trickyWeight: 28,
    );
  }

  static DifficultyConfig _lateDifficulty(int level) {
    if (level <= 45) {
      return const DifficultyConfig(
        traySize: 3,
        friendlyWeight: 22,
        standardWeight: 44,
        trickyWeight: 34,
      );
    }
    if (level <= 70) {
      return const DifficultyConfig(
        traySize: 3,
        friendlyWeight: 18,
        standardWeight: 40,
        trickyWeight: 42,
      );
    }
    return const DifficultyConfig.late();
  }

  static double _midBombChance(int level) {
    if (level < 14) return 0;
    if (level <= 18) return 0.04;
    if (level <= 24) return 0.055;
    return 0.07;
  }

  static double _lateBombChance(int level) {
    if (level <= 40) return 0.08;
    if (level <= 60) return 0.09;
    if (level <= 80) return 0.10;
    return 0.11;
  }

  static List<BlockPosition> _kingdomDeadZones(int level) {
    if (level <= 5) return const <BlockPosition>[];

    if (level <= 10) {
      return const <BlockPosition>[
        BlockPosition(1, 1),
        BlockPosition(6, 6),
      ];
    }

    if (level <= 15) {
      return const <BlockPosition>[
        BlockPosition(0, 3),
        BlockPosition(3, 0),
        BlockPosition(4, 7),
        BlockPosition(7, 4),
      ];
    }

    if (level <= 22) {
      return const <BlockPosition>[
        BlockPosition(1, 5),
        BlockPosition(2, 2),
        BlockPosition(5, 1),
        BlockPosition(6, 6),
      ];
    }

    if (level <= 35) {
      return const <BlockPosition>[
        BlockPosition(1, 1),
        BlockPosition(1, 6),
        BlockPosition(3, 3),
        BlockPosition(4, 4),
        BlockPosition(6, 1),
        BlockPosition(6, 6),
      ];
    }

    if (level <= 55) {
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

    return const <BlockPosition>[
      BlockPosition(1, 2),
      BlockPosition(1, 5),
      BlockPosition(2, 1),
      BlockPosition(2, 6),
      BlockPosition(3, 3),
      BlockPosition(3, 4),
      BlockPosition(4, 3),
      BlockPosition(4, 4),
      BlockPosition(5, 1),
      BlockPosition(5, 6),
      BlockPosition(6, 2),
      BlockPosition(6, 5),
    ];
  }

  static List<BlockPosition> _kingdomBlockedCells(int level) {
    if (level <= 7) return const <BlockPosition>[];

    if (level <= 14) {
      return const <BlockPosition>[
        BlockPosition(3, 3),
        BlockPosition(4, 4),
      ];
    }

    if (level <= 24) {
      return const <BlockPosition>[
        BlockPosition(2, 4),
        BlockPosition(3, 3),
        BlockPosition(4, 4),
        BlockPosition(5, 2),
      ];
    }

    if (level <= 40) {
      return const <BlockPosition>[
        BlockPosition(0, 0),
        BlockPosition(0, 7),
        BlockPosition(7, 0),
        BlockPosition(7, 7),
        BlockPosition(3, 4),
        BlockPosition(4, 3),
      ];
    }

    if (level <= 65) {
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

    return const <BlockPosition>[
      BlockPosition(0, 1),
      BlockPosition(0, 6),
      BlockPosition(1, 0),
      BlockPosition(1, 7),
      BlockPosition(3, 3),
      BlockPosition(3, 4),
      BlockPosition(4, 3),
      BlockPosition(4, 4),
      BlockPosition(6, 0),
      BlockPosition(6, 7),
      BlockPosition(7, 1),
      BlockPosition(7, 6),
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