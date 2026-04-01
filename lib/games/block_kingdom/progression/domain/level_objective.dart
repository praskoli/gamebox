enum BlockObjectiveType {
  clearLines,
  reachScore,
  hybridScoreAndLines,
  survive,
}

class LevelObjective {
  const LevelObjective({
    required this.type,
    this.targetScore = 0,
    this.targetLines = 0,
  });

  final BlockObjectiveType type;
  final int targetScore;
  final int targetLines;

  const LevelObjective.clearLines(int target)
      : type = BlockObjectiveType.clearLines,
        targetScore = 0,
        targetLines = target;

  const LevelObjective.reachScore(int target)
      : type = BlockObjectiveType.reachScore,
        targetScore = target,
        targetLines = 0;

  const LevelObjective.hybrid({
    required int targetScore,
    required int targetLines,
  })  : type = BlockObjectiveType.hybridScoreAndLines,
        targetScore = targetScore,
        targetLines = targetLines;

  const LevelObjective.survive()
      : type = BlockObjectiveType.survive,
        targetScore = 0,
        targetLines = 0;
}