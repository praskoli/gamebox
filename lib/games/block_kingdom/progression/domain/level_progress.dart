class LevelProgress {
  const LevelProgress({
    required this.objectiveTitle,
    required this.progressText,
    required this.primaryProgress,
    required this.secondaryProgress,
    required this.isComplete,
    required this.currentScore,
    required this.currentLines,
    required this.targetScore,
    required this.targetLines,
  });

  final String objectiveTitle;
  final String progressText;
  final double primaryProgress;
  final double secondaryProgress;
  final bool isComplete;
  final int currentScore;
  final int currentLines;
  final int targetScore;
  final int targetLines;
}