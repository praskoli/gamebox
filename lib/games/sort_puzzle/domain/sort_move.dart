class SortMove {
  const SortMove({
    required this.fromIndex,
    required this.toIndex,
    this.amount = 1,
  });

  final int fromIndex;
  final int toIndex;
  final int amount;
}
