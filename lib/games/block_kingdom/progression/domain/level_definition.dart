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
  });

  final int levelNumber;
  final String title;
  final String subtitle;
  final LevelObjective objective;
  final DifficultyConfig difficulty;
  final int rewardCoins;
  final int rewardXp;
  final int timeLimitSeconds;

  bool get isTimed => timeLimitSeconds > 0;
}