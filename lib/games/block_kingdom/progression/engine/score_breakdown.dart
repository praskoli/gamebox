class ScoreBreakdown {
  const ScoreBreakdown({
    required this.placementPoints,
    required this.lineClearBonus,
    required this.comboBonus,
    required this.milestoneBonus,
  });

  final int placementPoints;
  final int lineClearBonus;
  final int comboBonus;
  final int milestoneBonus;

  int get total =>
      placementPoints + lineClearBonus + comboBonus + milestoneBonus;
}