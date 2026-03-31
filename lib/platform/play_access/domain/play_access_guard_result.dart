enum PlayAccessBlockReason {
  none,
  dailyMinutesReached,
  dailyLevelsReached,
  approvalsExhausted,
}

class PlayAccessGuardResult {
  const PlayAccessGuardResult({
    required this.canStart,
    required this.shouldWarn,
    required this.reason,
    required this.minutesRemaining,
    required this.levelsRemaining,
  });

  final bool canStart;
  final bool shouldWarn;
  final PlayAccessBlockReason reason;
  final int minutesRemaining;
  final int levelsRemaining;

  factory PlayAccessGuardResult.allowed({
    required bool shouldWarn,
    required int minutesRemaining,
    required int levelsRemaining,
  }) {
    return PlayAccessGuardResult(
      canStart: true,
      shouldWarn: shouldWarn,
      reason: PlayAccessBlockReason.none,
      minutesRemaining: minutesRemaining,
      levelsRemaining: levelsRemaining,
    );
  }

  factory PlayAccessGuardResult.blocked({
    required PlayAccessBlockReason reason,
    required int minutesRemaining,
    required int levelsRemaining,
  }) {
    return PlayAccessGuardResult(
      canStart: false,
      shouldWarn: false,
      reason: reason,
      minutesRemaining: minutesRemaining,
      levelsRemaining: levelsRemaining,
    );
  }
}