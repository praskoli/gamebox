import '../domain/block_board.dart';
import '../domain/block_piece.dart';
import '../domain/block_game_session.dart';
import '../data/block_piece_library.dart';
import 'block_scoring.dart';
import 'block_game_over.dart';

class BlockEngine {
  final BlockBoard board = BlockBoard(8);
  final BlockGameSession session = BlockGameSession();

  List<BlockPiece> tray = [];

  void start() {
    tray = _generatePieces();
  }

  List<BlockPiece> _generatePieces() {
    return [
      BlockPieceLibrary.random(),
      BlockPieceLibrary.random(),
      BlockPieceLibrary.random(),
    ];
  }

  bool placePiece(int index, int row, int col) {
    final piece = tray[index];

    if (!board.canPlace(piece, row, col)) return false;

    board.place(piece, row, col);

    final cleared = board.clearLines();
    session.combo = cleared.isNotEmpty ? session.combo + 1 : 0;

    session.score += BlockScoring.calculate(cleared.length, session.combo);

    tray.removeAt(index);

    if (tray.isEmpty) {
      tray = _generatePieces();
    }

    session.isGameOver = BlockGameOver.check(board, tray);

    return true;
  }
}