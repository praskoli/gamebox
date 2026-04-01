class BlockGameSession {
  int score = 0;
  int combo = 0;
  bool isGameOver = false;
  bool isLevelComplete = false;

  int totalClearedLines = 0;
  int movesMade = 0;
  int placedCells = 0;
  int remainingSeconds = 0;

  void reset({
    required int initialSeconds,
  }) {
    score = 0;
    combo = 0;
    isGameOver = false;
    isLevelComplete = false;
    totalClearedLines = 0;
    movesMade = 0;
    placedCells = 0;
    remainingSeconds = initialSeconds;
  }
}