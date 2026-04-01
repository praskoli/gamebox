import '../data/block_piece_library.dart';
import '../domain/block_board.dart';
import '../domain/block_game_session.dart';
import '../domain/block_mode.dart';
import '../domain/block_piece.dart';
import '../progression/data/block_level_catalog.dart';
import '../progression/domain/level_definition.dart';
import '../progression/domain/level_progress.dart';
import '../progression/engine/level_manager.dart';
import '../progression/engine/score_breakdown.dart';
import '../progression/engine/score_calculator.dart';
import 'block_game_over.dart';

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
    session.reset(
      initialSeconds: levelDefinition.timeLimitSeconds,
    );
    tray = BlockPieceLibrary.generateTray(
      difficulty: levelDefinition.difficulty,
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

    final beforeScore = session.score;

    board.place(piece, row, col);

    final cleared = board.clearLines();
    final clearedLineCount = cleared.length;

    session.combo = cleared.isNotEmpty ? session.combo + 1 : 0;
    session.movesMade += 1;
    session.placedCells += _countCells(piece);
    session.totalClearedLines += clearedLineCount;

    // OLD BEHAVIOR: simple scoring path
    final gainedScore = (clearedLineCount * 10) + (session.combo * 5);
    session.score += gainedScore;

    tray.removeAt(index);

    if (tray.isEmpty) {
      tray = BlockPieceLibrary.generateTray(
        difficulty: levelDefinition.difficulty,
      );
    }

    // Keep progression update, but keep it as light as possible.
    progress = LevelManager.evaluate(
      session: session,
      level: levelDefinition,
    );

    session.isLevelComplete = progress.isComplete;
    session.isGameOver =
        session.isLevelComplete || BlockGameOver.check(board, tray);

    return BlockTurnResult(
      scoreBreakdown: ScoreBreakdown(
        placementPoints: 0,
        lineClearBonus: clearedLineCount * 10,
        comboBonus: session.combo * 5,
        milestoneBonus: 0,
      ),
      clearedLineCount: clearedLineCount,
      progress: progress,
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
  });

  final ScoreBreakdown scoreBreakdown;
  final int clearedLineCount;
  final LevelProgress progress;
}