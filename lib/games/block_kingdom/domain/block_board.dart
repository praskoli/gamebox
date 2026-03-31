import 'block_piece.dart';
class BlockBoard {
  final int size;
  final List<List<int>> grid;

  BlockBoard(this.size)
      : grid = List.generate(size, (_) => List.filled(size, 0));

  bool canPlace(BlockPiece piece, int row, int col) {
    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] == 1) {
          final nr = row + r;
          final nc = col + c;

          if (nr >= size || nc >= size) return false;
          if (grid[nr][nc] == 1) return false;
        }
      }
    }
    return true;
  }

  void place(BlockPiece piece, int row, int col) {
    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] == 1) {
          grid[row + r][col + c] = 1;
        }
      }
    }
  }

  List<int> clearLines() {
    final cleared = <int>[];

    for (int i = 0; i < size; i++) {
      if (grid[i].every((e) => e == 1)) {
        cleared.add(i);
      }
    }

    for (int j = 0; j < size; j++) {
      if (grid.every((row) => row[j] == 1)) {
        cleared.add(size + j);
      }
    }

    for (final i in cleared) {
      if (i < size) {
        grid[i] = List.filled(size, 0);
      } else {
        final col = i - size;
        for (int r = 0; r < size; r++) {
          grid[r][col] = 0;
        }
      }
    }

    return cleared;
  }
}