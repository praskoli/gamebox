import '../../domain/block_position.dart';
import 'difficulty_config.dart';
import 'level_objective.dart';

class LevelDefinition {
  const LevelDefinition({
    required this.levelNumber,
    required this.title,
    required this.subtitle,
    required this.objective,
    required this.difficulty,
    required this.rewardCoins,
    required this.rewardXp,
    this.timeLimitSeconds = 0,
    this.deadZones = const <BlockPosition>[],
    this.blockedCells = const <BlockPosition>[],
    this.allowBomb = false,
    this.bombChance = 0.0,
  });

  final int levelNumber;
  final String title;
  final String subtitle;
  final LevelObjective objective;
  final DifficultyConfig difficulty;
  final int rewardCoins;
  final int rewardXp;
  final int timeLimitSeconds;
  final List<BlockPosition> deadZones;
  final List<BlockPosition> blockedCells;

  final bool allowBomb;
  final double bombChance;

  bool get isTimed => timeLimitSeconds > 0;
}