import '../domain/block_board.dart';
import '../domain/block_cell_type.dart';

class BlockSpecialHandler {
  const BlockSpecialHandler._();

  static Set<String> applyBomb({
    required BlockBoard board,
    required int centerRow,
    required int centerCol,
  }) {
    final cleared = <String>{};

    for (int r = centerRow - 1; r <= centerRow + 1; r++) {
      for (int c = centerCol - 1; c <= centerCol + 1; c++) {
        if (r < 0 || c < 0 || r >= board.size || c >= board.size) {
          continue;
        }

        final cell = board.grid[r][c];

        // Dead zones and blocked cells stay intact.
        if (cell == BlockCellType.deadZone || cell == BlockCellType.blocked) {
          continue;
        }

        if (cell == BlockCellType.filled) {
          cleared.add('${r}_$c');
        }

        board.grid[r][c] = BlockCellType.empty;
      }
    }

    return cleared;
  }
}