import '../progression/engine/score_calculator.dart';

class BlockScoring {
  const BlockScoring._();

  static int calculate(
      int cleared,
      int combo, {
        int cellsPlaced = 1,
        int scoreBefore = 0,
      }) {
    return ScoreCalculator.calculate(
      cellsPlaced: cellsPlaced,
      clearedLines: cleared,
      combo: combo,
      scoreBefore: scoreBefore,
    ).total;
  }
}