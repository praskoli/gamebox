class BlockScoring {
  static int calculate(int cleared, int combo) {
    return (cleared * 10) + (combo * 5);
  }
}