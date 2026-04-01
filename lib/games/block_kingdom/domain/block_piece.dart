import 'block_special_type.dart';

class BlockPiece {
  final List<List<int>> shape;
  final BlockSpecialType specialType;

  const BlockPiece(
      this.shape, {
        this.specialType = BlockSpecialType.none,
      });

  int get rows => shape.length;
  int get cols => shape.isNotEmpty ? shape[0].length : 0;

  bool get isBomb => specialType == BlockSpecialType.bomb;
}