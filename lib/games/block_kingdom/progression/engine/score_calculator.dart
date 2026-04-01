import 'score_breakdown.dart';

class ScoreCalculator {
  const ScoreCalculator._();

  static const List<int> _milestones = <int>[
    100,
    250,
    500,
    900,
    1500,
    2500,
    4000,
  ];

  static ScoreBreakdown calculate({
    required int cellsPlaced,
    required int clearedLines,
    required int combo,
    required int scoreBefore,
  }) {
    final placementPoints = cellsPlaced * 3;

    final lineClearBonus = switch (clearedLines) {
      0 => 0,
      1 => 24,
      2 => 70,
      3 => 135,
      4 => 220,
      _ => 220 + ((clearedLines - 4) * 55),
    };

    final comboBonus = clearedLines > 0
        ? ((combo.clamp(0, 12)) * 12) + ((clearedLines - 1).clamp(0, 6) * 8)
        : 0;

    final subtotal = placementPoints + lineClearBonus + comboBonus;
    final afterWithoutMilestone = scoreBefore + subtotal;

    final crossed = _milestones.where(
          (milestone) =>
      milestone > scoreBefore && milestone <= afterWithoutMilestone,
    );

    final milestoneBonus = crossed.fold<int>(0, (sum, _) => sum + 30);

    return ScoreBreakdown(
      placementPoints: placementPoints,
      lineClearBonus: lineClearBonus,
      comboBonus: comboBonus,
      milestoneBonus: milestoneBonus,
    );
  }
}