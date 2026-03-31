import '../domain/block_board.dart';
import '../domain/block_piece.dart';

class BlockGameOver {
  static bool check(BlockBoard board, List<BlockPiece> pieces) {
    for (final piece in pieces) {
      for (int r = 0; r < board.size; r++) {
        for (int c = 0; c < board.size; c++) {
          if (board.canPlace(piece, r, c)) return false;
        }
      }
    }
    return true;
  }
}