import '../domain/block_piece.dart';
import 'dart:math';

class BlockPieceLibrary {
  static final _pieces = [
    [[1]],
    [[1,1]],
    [[1],[1]],
    [[1,1,1]],
    [[1],[1],[1]],
    [[1,1],[1,1]],
    [[1,0],[1,1]],
    [[0,1],[1,1]],
    [[1,1,1],[0,1,0]],
  ];

  static BlockPiece random() {
    final r = Random();
    return BlockPiece(_pieces[r.nextInt(_pieces.length)]);
  }
}