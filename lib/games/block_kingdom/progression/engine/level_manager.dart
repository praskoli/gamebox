import '../../domain/block_game_session.dart';
import '../domain/level_definition.dart';
import '../domain/level_objective.dart';
import '../domain/level_progress.dart';

class LevelManager {
  const LevelManager._();

  static LevelProgress evaluate({
    required BlockGameSession session,
    required LevelDefinition level,
  }) {
    switch (level.objective.type) {
      case BlockObjectiveType.clearLines:
        final target = level.objective.targetLines;
        final current = session.totalClearedLines;
        final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

        return LevelProgress(
          objectiveTitle: 'Clear $target lines',
          progressText: '$current / $target lines',
          primaryProgress: progress,
          secondaryProgress: 0,
          isComplete: current >= target,
          currentScore: session.score,
          currentLines: current,
          targetScore: 0,
          targetLines: target,
        );

      case BlockObjectiveType.reachScore:
        final target = level.objective.targetScore;
        final current = session.score;
        final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

        return LevelProgress(
          objectiveTitle: 'Reach score $target',
          progressText: '$current / $target score',
          primaryProgress: progress,
          secondaryProgress: 0,
          isComplete: current >= target,
          currentScore: current,
          currentLines: session.totalClearedLines,
          targetScore: target,
          targetLines: 0,
        );

      case BlockObjectiveType.hybridScoreAndLines:
        final scoreTarget = level.objective.targetScore;
        final lineTarget = level.objective.targetLines;
        final scoreProgress = scoreTarget <= 0
            ? 0.0
            : (session.score / scoreTarget).clamp(0.0, 1.0);
        final lineProgress = lineTarget <= 0
            ? 0.0
            : (session.totalClearedLines / lineTarget).clamp(0.0, 1.0);

        return LevelProgress(
          objectiveTitle: 'Reach $scoreTarget score + clear $lineTarget lines',
          progressText:
          '${session.score}/$scoreTarget score • ${session.totalClearedLines}/$lineTarget lines',
          primaryProgress: scoreProgress,
          secondaryProgress: lineProgress,
          isComplete:
          session.score >= scoreTarget &&
              session.totalClearedLines >= lineTarget,
          currentScore: session.score,
          currentLines: session.totalClearedLines,
          targetScore: scoreTarget,
          targetLines: lineTarget,
        );

      case BlockObjectiveType.survive:
        final nextMilestone = _nextMilestone(session.score);
        final prevMilestone = _previousMilestone(session.score);
        final span = (nextMilestone - prevMilestone).clamp(1, 999999);
        final progress =
        ((session.score - prevMilestone) / span).clamp(0.0, 1.0);

        return LevelProgress(
          objectiveTitle: 'Keep building your kingdom',
          progressText:
          'Score ${session.score} • next milestone $nextMilestone',
          primaryProgress: progress,
          secondaryProgress: 0,
          isComplete: false,
          currentScore: session.score,
          currentLines: session.totalClearedLines,
          targetScore: nextMilestone,
          targetLines: 0,
        );
    }
  }

  static int _nextMilestone(int score) {
    const milestones = <int>[100, 250, 500, 900, 1500, 2500, 4000, 6000];
    for (final value in milestones) {
      if (score < value) return value;
    }
    return score + 1000;
  }

  static int _previousMilestone(int score) {
    const milestones = <int>[0, 100, 250, 500, 900, 1500, 2500, 4000, 6000];
    int previous = 0;
    for (final value in milestones) {
      if (value <= score) previous = value;
    }
    return previous;
  }
}