import 'sort_level.dart';

class SortPuzzleScoring {
  const SortPuzzleScoring._();

  static int calculateStars({
    required SortLevel level,
    required int moveCount,
    required Duration elapsed,
    required bool solved,
  }) {
    if (!solved) return 0;

    final int metric = _metricForLevel(
      level: level,
      moveCount: moveCount,
      elapsed: elapsed,
    );

    if (metric <= level.star3Target) return 3;
    if (metric <= level.star2Target) return 2;
    return 1;
  }

  static int _metricForLevel({
    required SortLevel level,
    required int moveCount,
    required Duration elapsed,
  }) {
    if (level.specialRules.timeLimitSeconds != null) {
      return elapsed.inSeconds;
    }
    return moveCount;
  }
}