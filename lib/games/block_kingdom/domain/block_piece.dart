class BlockPiece {
  final List<List<int>> shape;

  const BlockPiece(this.shape);

  int get rows => shape.length;
  int get cols => shape[0].length;
}