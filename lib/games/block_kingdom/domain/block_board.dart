import 'block_cell_type.dart';
import 'block_piece.dart';
import 'block_position.dart';

class BlockBoard {
  final int size;
  late List<List<BlockCellType>> grid;
  BlockBoard(this.size) {
    reset();
  }

  void reset() {
    grid = List<List<BlockCellType>>.generate(
      size,
          (_) => List<BlockCellType>.filled(size, BlockCellType.empty),
      growable: false,
    );
  }

  void applyLevelLayout({
    List<BlockPosition> deadZones = const <BlockPosition>[],
    List<BlockPosition> blockedCells = const <BlockPosition>[],
  }) {
    for (final pos in deadZones) {
      if (_isInside(pos.row, pos.col)) {
        grid[pos.row][pos.col] = BlockCellType.deadZone;
      }
    }

    for (final pos in blockedCells) {
      if (_isInside(pos.row, pos.col) &&
          grid[pos.row][pos.col] != BlockCellType.deadZone) {
        grid[pos.row][pos.col] = BlockCellType.blocked;
      }
    }
  }

  bool canPlace(BlockPiece piece, int row, int col) {
    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] != 1) continue;

        final nr = row + r;
        final nc = col + c;

        if (!_isInside(nr, nc)) return false;
        if (grid[nr][nc] != BlockCellType.empty) return false;
      }
    }
    return true;
  }

  void place(BlockPiece piece, int row, int col) {
    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] == 1) {
          grid[row + r][col + c] = BlockCellType.filled;
        }
      }
    }
  }

  List<int> clearLines() {
    final cleared = <int>[];

    for (int i = 0; i < size; i++) {
      if (grid[i].every((cell) => cell == BlockCellType.filled)) {
        cleared.add(i);
      }
    }

    for (int j = 0; j < size; j++) {
      bool full = true;
      for (int i = 0; i < size; i++) {
        if (grid[i][j] != BlockCellType.filled) {
          full = false;
          break;
        }
      }
      if (full) {
        cleared.add(size + j);
      }
    }

    for (final value in cleared) {
      if (value < size) {
        for (int c = 0; c < size; c++) {
          if (grid[value][c] == BlockCellType.filled) {
            grid[value][c] = BlockCellType.empty;
          }
        }
      } else {
        final col = value - size;
        for (int r = 0; r < size; r++) {
          if (grid[r][col] == BlockCellType.filled) {
            grid[r][col] = BlockCellType.empty;
          }
        }
      }
    }

    return cleared;
  }

  bool _isInside(int row, int col) {
    return row >= 0 && col >= 0 && row < size && col < size;
  }
}