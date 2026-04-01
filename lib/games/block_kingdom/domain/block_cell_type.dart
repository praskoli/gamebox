enum BlockCellType {
  empty,
  filled,
  deadZone,
  blocked,
}

extension BlockCellTypeX on BlockCellType {
  bool get isObstacle =>
      this == BlockCellType.deadZone || this == BlockCellType.blocked;
}