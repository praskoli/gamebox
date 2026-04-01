import '../data/block_piece_library.dart';
import '../domain/block_board.dart';
import '../domain/block_cell_type.dart';
import '../domain/block_game_session.dart';
import '../domain/block_mode.dart';
import '../domain/block_piece.dart';
import '../domain/block_special_type.dart';
import '../progression/data/block_level_catalog.dart';
import '../progression/domain/level_definition.dart';
import '../progression/domain/level_progress.dart';
import '../progression/engine/level_manager.dart';
import '../progression/engine/score_breakdown.dart';
import '../progression/engine/score_calculator.dart';
import 'block_game_over.dart';
import 'block_special_handler.dart';

class BlockEngine {
  BlockEngine({
    required this.mode,
    required int levelNumber,
  }) : levelDefinition = BlockLevelCatalog.forMode(
    mode,
    levelNumber: levelNumber,
  );

  final BlockMode mode;
  final BlockBoard board = BlockBoard(8);
  final BlockGameSession session = BlockGameSession();
  final LevelDefinition levelDefinition;

  List<BlockPiece> tray = <BlockPiece>[];
  late LevelProgress progress;

  void start() {
    board.reset();
    board.applyLevelLayout(
      deadZones: levelDefinition.deadZones,
      blockedCells: levelDefinition.blockedCells,
    );

    session.reset(
      initialSeconds: levelDefinition.timeLimitSeconds,
    );

    tray = BlockPieceLibrary.generateTray(
      levelDefinition: levelDefinition,
    );

    progress = LevelManager.evaluate(
      session: session,
      level: levelDefinition,
    );
  }

  BlockTurnResult? placePiece(int index, int row, int col) {
    if (session.isGameOver) return null;
    if (index < 0 || index >= tray.length) return null;

    final piece = tray[index];
    if (!board.canPlace(piece, row, col)) return null;

    final scoreBefore = session.score;
    final cellsPlaced = _countCells(piece);

    if (piece.specialType == BlockSpecialType.bomb) {
      board.place(piece, row, col);
      final bombClearedKeys = BlockSpecialHandler.applyBomb(
        board: board,
        centerRow: row,
        centerCol: col,
      );

      final bombBonus = 45 + (bombClearedKeys.length * 6);

      session.combo = 0;
      session.movesMade += 1;
      session.placedCells += cellsPlaced;
      session.score += bombBonus;

      tray.removeAt(index);
      if (tray.isEmpty) {
        tray = BlockPieceLibrary.generateTray(
          levelDefinition: levelDefinition,
        );
      }

      progress = LevelManager.evaluate(
        session: session,
        level: levelDefinition,
      );

      session.isLevelComplete = progress.isComplete;
      session.isGameOver =
          session.isLevelComplete || BlockGameOver.check(board, tray);

      return BlockTurnResult(
        scoreBreakdown: ScoreBreakdown(
          placementPoints: 15,
          lineClearBonus: 0,
          comboBonus: 0,
          milestoneBonus: bombBonus - 15,
        ),
        clearedLineCount: 0,
        progress: progress,
        usedBomb: true,
        bombClearedKeys: bombClearedKeys,
      );
    }

    board.place(piece, row, col);

    final cleared = board.clearLines();
    final clearedLineCount = cleared.length;

    session.combo = clearedLineCount > 0 ? session.combo + 1 : 0;
    session.movesMade += 1;
    session.placedCells += cellsPlaced;
    session.totalClearedLines += clearedLineCount;

    final scoreBreakdown = ScoreCalculator.calculate(
      cellsPlaced: cellsPlaced,
      clearedLines: clearedLineCount,
      combo: session.combo,
      scoreBefore: scoreBefore,
    );

    session.score += scoreBreakdown.total;

    tray.removeAt(index);
    if (tray.isEmpty) {
      tray = BlockPieceLibrary.generateTray(
        levelDefinition: levelDefinition,
      );
    }

    progress = LevelManager.evaluate(
      session: session,
      level: levelDefinition,
    );

    session.isLevelComplete = progress.isComplete;
    session.isGameOver =
        session.isLevelComplete || BlockGameOver.check(board, tray);

    return BlockTurnResult(
      scoreBreakdown: scoreBreakdown,
      clearedLineCount: clearedLineCount,
      progress: progress,
      usedBomb: false,
      bombClearedKeys: const <String>{},
    );
  }

  bool tickTimer() {
    if (!mode.isTimed || session.isGameOver) return false;
    if (session.remainingSeconds <= 0) return false;

    session.remainingSeconds -= 1;

    if (session.remainingSeconds <= 0) {
      session.remainingSeconds = 0;
      progress = LevelManager.evaluate(
        session: session,
        level: levelDefinition,
      );
      session.isLevelComplete = progress.isComplete;
      session.isGameOver = true;
      return true;
    }

    return false;
  }

  int _countCells(BlockPiece piece) {
    int count = 0;
    for (final row in piece.shape) {
      for (final cell in row) {
        if (cell == 1) count += 1;
      }
    }
    return count;
  }
}

class BlockTurnResult {
  const BlockTurnResult({
    required this.scoreBreakdown,
    required this.clearedLineCount,
    required this.progress,
    required this.usedBomb,
    required this.bombClearedKeys,
  });

  final ScoreBreakdown scoreBreakdown;
  final int clearedLineCount;
  final LevelProgress progress;
  final bool usedBomb;
  final Set<String> bombClearedKeys;
}