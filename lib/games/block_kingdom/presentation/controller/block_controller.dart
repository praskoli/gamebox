import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gamebox/platform/audio/sound_service.dart';
import 'package:gamebox/platform/haptics/haptic_service.dart';
import 'package:gamebox/platform/play_access/data/play_access_service.dart';
import '../../data/block_caption_pool.dart';
import '../../domain/block_piece.dart';
import '../../domain/block_mode.dart';
import '../../engine/block_engine.dart';
import '../../progression/domain/level_definition.dart';
import '../../progression/domain/level_progress.dart';


class BlockController extends ChangeNotifier {
  BlockController({
    required this.mode,
    required this.initialLevelNumber,
  });

  final BlockMode mode;
  int initialLevelNumber;

  late BlockEngine engine;

  Rect? _boardRect;

  Offset dragGlobalPosition = Offset.zero;

  BlockPiece? draggingPiece;
  int? draggingIndex;

  int? previewRow;
  int? previewCol;
  bool isValidPlacement = false;
  bool isDragging = false;

  String banner = '';
  String secondaryBanner = '';
  Color bannerColor = const Color(0xFFFFD37A);

  static const double dragLift = 90;

  PlacementFeedback? latestFeedback;
  int feedbackVersion = 0;

  Set<String> recentPlacedCellKeys = <String>{};
  Set<String> recentClearedCellKeys = <String>{};

  bool scorePulse = false;
  int lastScoreGain = 0;

  int _transientToken = 0;
  BlockSessionOutcome sessionOutcome = BlockSessionOutcome.none;

  void start() {
    engine = BlockEngine(
      mode: mode,
      levelNumber: initialLevelNumber,
    )..start();

    sessionOutcome = BlockSessionOutcome.none;
    _resetDragState();
    _resetTransientState();
    banner = '';
    secondaryBanner = '';
    bannerColor = const Color(0xFFFFD37A);
    notifyListeners();
  }

  void restart({int? levelNumber}) {
    if (levelNumber != null) {
      initialLevelNumber = levelNumber;
    }
    start();
  }

  void attachBoardRect(Rect rect) {
    if (_boardRect == rect) return;
    _boardRect = rect;
  }

  Rect? get boardRect => _boardRect;

  LevelDefinition get levelDefinition => engine.levelDefinition;
  LevelProgress get progress => engine.progress;

  int get currentLevelNumber => levelDefinition.levelNumber;

  String get levelLabel {
    switch (mode) {
      case BlockMode.kingdom:
        return 'Level ${levelDefinition.levelNumber}';
      case BlockMode.timeTrial:
        return 'Challenge ${levelDefinition.levelNumber}';
      case BlockMode.endless:
        return 'Classic Run';
    }
  }

  String get rewardLabel {
    if (mode == BlockMode.endless) {
      return 'Score-based rewards';
    }
    return '+${levelDefinition.rewardXp} XP • +${levelDefinition.rewardCoins} coins';
  }

  bool get showTimer => mode.isTimed;

  String get timerLabel {
    final seconds = engine.session.remainingSeconds.clamp(0, 9999);
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  double get boardCellSize {
    final rect = _boardRect;
    if (rect == null) return 0;
    return rect.width / engine.board.size;
  }

  double get dragVisualCellSize {
    final cell = boardCellSize;
    if (cell <= 0) return 36;
    return math.max(36, cell * 1.20);
  }

  double get dragLiftPx => dragLift;

  double get dragLeft {
    final piece = draggingPiece;
    if (piece == null) return dragGlobalPosition.dx;

    final visualWidth = piece.cols * dragVisualCellSize;
    return dragGlobalPosition.dx - (visualWidth / 2);
  }

  double get dragTop {
    final piece = draggingPiece;
    if (piece == null) return dragGlobalPosition.dy;

    final visualHeight = piece.rows * dragVisualCellSize;
    return dragGlobalPosition.dy - visualHeight - dragLiftPx;
  }

  List<PreviewCell> get previewCells {
    final piece = draggingPiece;
    final row = previewRow;
    final col = previewCol;

    if (piece == null || row == null || col == null) {
      return const <PreviewCell>[];
    }

    final cells = <PreviewCell>[];

    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] != 1) continue;

        final rr = row + r;
        final cc = col + c;

        if (rr < 0 ||
            cc < 0 ||
            rr >= engine.board.size ||
            cc >= engine.board.size) {
          continue;
        }

        cells.add(PreviewCell(rr, cc));
      }
    }

    return cells;
  }

  void startDrag(int index, Offset globalPosition) {
    if (engine.session.isGameOver) return;
    if (index < 0 || index >= engine.tray.length) return;

    PlayAccessService.instance.recordUserInteraction();

    draggingIndex = index;
    draggingPiece = engine.tray[index];
    dragGlobalPosition = globalPosition;
    isDragging = true;

    banner = '';
    secondaryBanner = '';

    _safeHaptic(HapticService.selection);
    _updatePreviewFromGlobal(globalPosition);
    notifyListeners();
  }

  void updateDrag(Offset globalPosition) {
    if (!isDragging || draggingPiece == null) return;

    PlayAccessService.instance.recordUserInteraction();

    dragGlobalPosition = globalPosition;
    _updatePreviewFromGlobal(globalPosition);
    notifyListeners();
  }

  void endDrag() {
    debugPrint('END_DRAG: entered');
    if (!isDragging) {
      debugPrint('END_DRAG: ignored because isDragging = false');
      return;
    }

    try {
      PlayAccessService.instance.recordUserInteraction();
      debugPrint('END_DRAG: recorded interaction');
    } catch (e, st) {
      debugPrint('END_DRAG: recordUserInteraction error -> $e');
      debugPrint('$st');
    }

    final piece = draggingPiece;
    final row = previewRow;
    final col = previewCol;
    final trayIndex = draggingIndex;

    debugPrint(
      'END_DRAG: piece=${piece != null}, trayIndex=$trayIndex, row=$row, col=$col, isValidPlacement=$isValidPlacement',
    );

    if (piece != null &&
        trayIndex != null &&
        row != null &&
        col != null &&
        isValidPlacement) {
      try {
        final placedCells = _buildPlacedCells(piece, row, col);
        debugPrint('END_DRAG: built placedCells = ${placedCells.length}');

        final previewResult = _simulatePlacement(piece, row, col);
        debugPrint(
          'END_DRAG: preview rows=${previewResult.clearedRows.length}, cols=${previewResult.clearedCols.length}, cells=${previewResult.clearedCells.length}',
        );

        debugPrint('END_DRAG: calling engine.placePiece...');
        final turnResult = engine.placePiece(
          trayIndex,
          row,
          col,
        );
        debugPrint('END_DRAG: engine.placePiece returned ${turnResult != null}');

        if (turnResult != null) {
          debugPrint('END_DRAG: turnResult.scoreBreakdown.total = ${turnResult.scoreBreakdown.total}');
          final scoreGain = turnResult.scoreBreakdown.total;
          final comboNow = engine.session.combo;
          final clearedLineCount = turnResult.clearedLineCount;

          recentPlacedCellKeys = placedCells.map((e) => e.key).toSet();
          recentClearedCellKeys =
              previewResult.clearedCells.map((e) => e.key).toSet();

          lastScoreGain = scoreGain;
          scorePulse = true;

          final crossedMilestone = turnResult.scoreBreakdown.milestoneBonus > 0;
          debugPrint('END_DRAG: crossedMilestone = $crossedMilestone');

          final feedback = PlacementFeedback(
            placedCells: placedCells,
            clearedCells: previewResult.clearedCells,
            clearedRows: previewResult.clearedRows,
            clearedCols: previewResult.clearedCols,
            primaryText: _resolvePrimaryCaption(
              clearedLineCount: clearedLineCount,
              combo: comboNow,
              scoreGain: scoreGain,
              completedObjective: engine.session.isLevelComplete,
            ),
            secondaryText: _resolveSecondaryCaption(
              clearedLineCount: clearedLineCount,
              combo: comboNow,
              crossedMilestone: crossedMilestone,
              scoreGain: scoreGain,
              completedObjective: engine.session.isLevelComplete,
            ),
            combo: comboNow,
            scoreGain: scoreGain,
            crossedMilestone: crossedMilestone,
            eventId: DateTime.now().microsecondsSinceEpoch,
          );

          latestFeedback = feedback;
          feedbackVersion++;

          banner = feedback.primaryText;
          secondaryBanner = feedback.secondaryText;

          if (engine.session.isLevelComplete) {
            bannerColor = const Color(0xFF84FFD2);
          } else if (crossedMilestone) {
            bannerColor = const Color(0xFFFFE37A);
          } else if (clearedLineCount > 0) {
            bannerColor = const Color(0xFF84FFD2);
          } else {
            bannerColor = const Color(0xFFFFD37A);
          }

          debugPrint('END_DRAG: playing sounds/haptics');
          SoundService.instance.playBlockPlace();

          try {
            HapticService.light();
          } catch (e, st) {
            debugPrint('END_DRAG: Haptic light error -> $e');
            debugPrint('$st');
          }

          if (clearedLineCount > 0) {
            SoundService.instance.playLineClear();
            SoundService.instance.playMatch();
            try {
              HapticService.medium();
            } catch (e, st) {
              debugPrint('END_DRAG: Haptic medium error -> $e');
              debugPrint('$st');
            }
          }

          if (comboNow >= 3 || crossedMilestone) {
            SoundService.instance.playBonus();
            try {
              HapticService.heavy();
            } catch (e, st) {
              debugPrint('END_DRAG: Haptic heavy error -> $e');
              debugPrint('$st');
            }
          }

          if (engine.session.isLevelComplete) {
            SoundService.instance.playLevelComplete();
            try {
              HapticService.heavy();
            } catch (e, st) {
              debugPrint('END_DRAG: Haptic heavy complete error -> $e');
              debugPrint('$st');
            }
            sessionOutcome = BlockSessionOutcome.success;
          } else if (engine.session.isGameOver) {
            SoundService.instance.playFail();
            try {
              HapticService.heavy();
            } catch (e, st) {
              debugPrint('END_DRAG: Haptic heavy fail error -> $e');
              debugPrint('$st');
            }
            sessionOutcome = BlockSessionOutcome.failure;
          }

          _scheduleTransientCleanup();
          debugPrint('END_DRAG: success branch completed');
        } else {
          debugPrint('END_DRAG: turnResult was null, playing fail');
          SoundService.instance.playFail();
          try {
            HapticService.selection();
          } catch (_) {}
        }
      } catch (e, st) {
        debugPrint('END_DRAG: SUCCESS BRANCH ERROR -> $e');
        debugPrint('$st');
      }
    } else {
      debugPrint('END_DRAG: invalid placement branch');
      SoundService.instance.playFail();
      try {
        HapticService.selection();
      } catch (_) {}
    }

    debugPrint('END_DRAG: resetting drag state');
    _resetDragState();
    notifyListeners();
    debugPrint('END_DRAG: finished');
  }

  void tickTimer() {
    if (!mode.isTimed || engine.session.isGameOver) return;

    final ended = engine.tickTimer();

    if (ended) {
      if (engine.session.isLevelComplete) {
        banner = 'Clock Beaten!';
        secondaryBanner = 'Time Trial cleared';
        bannerColor = const Color(0xFF84FFD2);
        SoundService.instance.playLevelComplete();
        _safeHaptic(HapticService.heavy);
        sessionOutcome = BlockSessionOutcome.success;
      } else {
        banner = 'Time Up!';
        secondaryBanner = 'Challenge missed';
        bannerColor = const Color(0xFFFF7C8B);
        SoundService.instance.playFail();
        _safeHaptic(HapticService.heavy);
        sessionOutcome = BlockSessionOutcome.failure;
      }
    } else if (engine.session.remainingSeconds <= 10) {
      banner = 'Final Seconds!';
      secondaryBanner = 'Move fast and finish strong';
      bannerColor = const Color(0xFF8B5CF6);
    }

    notifyListeners();
  }

  void clearSessionOutcome() {
    sessionOutcome = BlockSessionOutcome.none;
    notifyListeners();
  }
  void _safeHaptic(void Function() action) {
    try {
      action();
    } catch (_) {
      // Never let haptics break gameplay flow.
    }
  }
  void _scheduleTransientCleanup() {
    _transientToken++;
    final token = _transientToken;

    Future.delayed(const Duration(milliseconds: 180), () {
      if (token != _transientToken) return;
      scorePulse = false;
      notifyListeners();
    });

    Future.delayed(const Duration(milliseconds: 320), () {
      if (token != _transientToken) return;
      recentPlacedCellKeys = <String>{};
      notifyListeners();
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      if (token != _transientToken) return;
      recentClearedCellKeys = <String>{};
      if (!engine.session.isGameOver) {
        banner = '';
        secondaryBanner = '';
        bannerColor = const Color(0xFFFFD37A);
      }
      notifyListeners();
    });
  }

  void _resetTransientState() {
    recentPlacedCellKeys = <String>{};
    recentClearedCellKeys = <String>{};
    latestFeedback = null;
    feedbackVersion = 0;
    scorePulse = false;
    lastScoreGain = 0;
  }

  void _resetDragState() {
    draggingPiece = null;
    draggingIndex = null;
    previewRow = null;
    previewCol = null;
    isValidPlacement = false;
    isDragging = false;
  }

  void _updatePreviewFromGlobal(Offset globalPosition) {
    final rect = _boardRect;
    final piece = draggingPiece;

    if (rect == null || piece == null) {
      previewRow = null;
      previewCol = null;
      isValidPlacement = false;
      return;
    }

    final cell = rect.width / engine.board.size;

    final visualTopLeftGlobal = Offset(
      globalPosition.dx - ((piece.cols * cell) / 2),
      globalPosition.dy - (piece.rows * cell) - dragLiftPx,
    );

    final visualTopLeftLocal = visualTopLeftGlobal - rect.topLeft;

    final anchorCol = (visualTopLeftLocal.dx / cell).round();
    final anchorRow = (visualTopLeftLocal.dy / cell).round();

    previewRow = anchorRow;
    previewCol = anchorCol;
    isValidPlacement = _canPlace(piece, anchorRow, anchorCol);
  }

  bool _canPlace(BlockPiece piece, int row, int col) {
    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] != 1) continue;

        final rr = row + r;
        final cc = col + c;

        if (rr < 0 ||
            cc < 0 ||
            rr >= engine.board.size ||
            cc >= engine.board.size) {
          return false;
        }

        if (engine.board.grid[rr][cc] == 1) {
          return false;
        }
      }
    }

    return true;
  }

  List<CellRef> _buildPlacedCells(BlockPiece piece, int row, int col) {
    final cells = <CellRef>[];

    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] != 1) continue;
        cells.add(CellRef(row + r, col + c));
      }
    }

    return cells;
  }

  _PlacementPreview _simulatePlacement(BlockPiece piece, int row, int col) {
    final size = engine.board.size;
    final grid = List<List<int>>.generate(
      size,
          (r) => List<int>.from(engine.board.grid[r]),
    );

    for (int r = 0; r < piece.rows; r++) {
      for (int c = 0; c < piece.cols; c++) {
        if (piece.shape[r][c] != 1) continue;
        grid[row + r][col + c] = 1;
      }
    }

    final clearedRows = <int>[];
    final clearedCols = <int>[];

    for (int r = 0; r < size; r++) {
      if (grid[r].every((e) => e == 1)) {
        clearedRows.add(r);
      }
    }

    for (int c = 0; c < size; c++) {
      var full = true;
      for (int r = 0; r < size; r++) {
        if (grid[r][c] != 1) {
          full = false;
          break;
        }
      }
      if (full) {
        clearedCols.add(c);
      }
    }

    final clearedCells = <CellRef>[];
    for (final r in clearedRows) {
      for (int c = 0; c < size; c++) {
        clearedCells.add(CellRef(r, c));
      }
    }
    for (final c in clearedCols) {
      for (int r = 0; r < size; r++) {
        final cell = CellRef(r, c);
        if (!clearedCells.any((e) => e.row == cell.row && e.col == cell.col)) {
          clearedCells.add(cell);
        }
      }
    }

    return _PlacementPreview(
      clearedRows: clearedRows,
      clearedCols: clearedCols,
      clearedCells: clearedCells,
    );
  }

  String _resolvePrimaryCaption({
    required int clearedLineCount,
    required int combo,
    required int scoreGain,
    required bool completedObjective,
  }) {
    if (completedObjective) {
      return mode == BlockMode.timeTrial ? 'Trial Cleared!' : 'Level Complete!';
    }
    if (combo >= 5) return 'Legend Move!';
    if (combo == 4) return 'King Level!';
    if (combo == 3) return 'Brilliant!';
    if (combo == 2) return 'Combo Spark!';
    if (clearedLineCount >= 2) return 'Clean Sweep!';
    if (clearedLineCount == 1) return 'Sharp Clear!';
    if (scoreGain > 0) return 'Smart Move!';
    return BlockCaptionPool.random();
  }

  String _resolveSecondaryCaption({
    required int clearedLineCount,
    required int combo,
    required bool crossedMilestone,
    required int scoreGain,
    required bool completedObjective,
  }) {
    if (completedObjective) {
      return rewardLabel;
    }
    if (crossedMilestone) return 'Bonus unlocked!';
    if (combo >= 4) return 'Board mastery';
    if (combo == 3) return 'Keep the streak';
    if (combo == 2) return 'Chain reaction';
    if (clearedLineCount >= 2) return '+$scoreGain score';
    if (clearedLineCount == 1) return 'Line clear';
    return scoreGain > 0 ? '+$scoreGain score' : 'Perfect fit';
  }
}

enum BlockSessionOutcome {
  none,
  success,
  failure,
}

class PreviewCell {
  final int row;
  final int col;

  const PreviewCell(this.row, this.col);
}

class CellRef {
  final int row;
  final int col;

  const CellRef(this.row, this.col);

  String get key => '${row}_$col';
}

class PlacementFeedback {
  final List<CellRef> placedCells;
  final List<CellRef> clearedCells;
  final List<int> clearedRows;
  final List<int> clearedCols;
  final String primaryText;
  final String secondaryText;
  final int combo;
  final int scoreGain;
  final bool crossedMilestone;
  final int eventId;

  const PlacementFeedback({
    required this.placedCells,
    required this.clearedCells,
    required this.clearedRows,
    required this.clearedCols,
    required this.primaryText,
    required this.secondaryText,
    required this.combo,
    required this.scoreGain,
    required this.crossedMilestone,
    required this.eventId,
  });
}

class _PlacementPreview {
  final List<int> clearedRows;
  final List<int> clearedCols;
  final List<CellRef> clearedCells;

  const _PlacementPreview({
    required this.clearedRows,
    required this.clearedCols,
    required this.clearedCells,
  });
}