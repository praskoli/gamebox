import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../platform/audio/sound_service.dart';
import '../../../../platform/play_access/data/play_access_service.dart';
import '../../data/sort_asset_resolver.dart';
import '../../domain/sort_level.dart';
import '../../domain/sort_move.dart';
import '../../domain/sort_session.dart';
import '../../engine/sort_puzzle_engine.dart';

class SortPuzzleController extends ChangeNotifier {
  SortPuzzleController({
    required SortPuzzleEngine engine,
    required SortLevel level,
    SortAssetResolver assetResolver = const SortAssetResolver(),
  })  : _engine = engine,
        _level = level,
        _assetResolver = assetResolver,
        _session = engine.createSession(level);

  final SortPuzzleEngine _engine;
  final SortLevel _level;
  final SortAssetResolver _assetResolver;

  final Stopwatch _stopwatch = Stopwatch();

  Timer? _ticker;
  SortSession _session;

  bool _blocked = false;
  String? _blockMessage;
  bool _timeExpired = false;
  bool _moveLimitReached = false;
  bool _didPlaySolvedSound = false;

  SortSession get session => _session;
  bool get isSolved => _engine.isSolved(_session);
  bool get isBlocked => _blocked;
  String? get blockMessage => _blockMessage;

  bool get hasTimeLimit => _level.specialRules.hasTimeLimit;
  bool get hasMoveLimit => _level.specialRules.hasMoveLimit;
  bool get isTimeExpired => _timeExpired;
  bool get isMoveLimitReached => _moveLimitReached;

  int? get moveLimit => _level.specialRules.moveLimit;
  int? get timeLimitSeconds => _level.specialRules.timeLimitSeconds;

  int? get remainingMoves {
    if (!hasMoveLimit) return null;
    return (moveLimit! - _session.moveCount).clamp(0, 999999);
  }

  Duration? get remainingTime {
    if (!hasTimeLimit) return null;
    final int left = timeLimitSeconds! - _stopwatch.elapsed.inSeconds;
    return Duration(seconds: left.clamp(0, 999999));
  }

  Future<void> initialize() async {
    await PlayAccessService.instance.initialize();

    final guard = await PlayAccessService.instance.canStartPlay(
      gameId: 'sort_puzzle',
    );

    if (!guard.canStart) {
      _blocked = true;
      _blockMessage = 'Play limit reached for today.';
      notifyListeners();
      return;
    }

    await PlayAccessService.instance.beginGameplaySession(
      gameId: 'sort_puzzle',
      levelNumber: _level.levelNumber,
    );

    _startLevelAudio();
    _startTicker();
    notifyListeners();
  }

  void selectContainer(int index) {
    if (_blocked || isSolved || _timeExpired || _moveLimitReached) {
      return;
    }

    PlayAccessService.instance.recordUserInteraction();

    final int? current = _session.selectedContainerIndex;

    if (current == null) {
      _session = _session.copyWith(selectedContainerIndex: index);
      notifyListeners();
      return;
    }

    if (current == index) {
      _session = _session.copyWith(selectedContainerIndex: null);
      notifyListeners();
      return;
    }

    final SortSession before = _session.copyWith(selectedContainerIndex: null);

    final result = _engine.applyMove(
      before,
      SortMove(fromIndex: current, toIndex: index),
    );

    final bool moveChanged = result.session.moveCount != before.moveCount ||
        !_sameContainerSnapshot(before, result.session);

    _session = result.session.copyWith(
      selectedContainerIndex: null,
      elapsed: _stopwatch.elapsed,
    );

    if (moveChanged) {
      _playSuccessAudio();
    } else {
      _playErrorAudio();
    }

    _checkLimitsAfterMove();
    _handleSolvedAudioOnce();
    notifyListeners();
  }

  void undo() {
    if (!_level.allowUndo || _blocked || _timeExpired || _moveLimitReached) {
      return;
    }

    _session = _engine.undo(_session).copyWith(
      elapsed: _stopwatch.elapsed,
      selectedContainerIndex: null,
    );

    _resetLimitFlagsAfterUndo();
    notifyListeners();
  }

  void applyHint() {
    if (!_level.allowHints || _blocked || _timeExpired || _moveLimitReached) {
      return;
    }

    final move = _engine.findHintMove(_session);
    if (move == null) return;

    _session = _session.copyWith(
      hintsUsed: _session.hintsUsed + 1,
      selectedContainerIndex: move.fromIndex,
    );
    notifyListeners();
  }

  void restart() {
    _session = _engine.createSession(_level);
    _timeExpired = false;
    _moveLimitReached = false;
    _didPlaySolvedSound = false;
    _blockMessage = null;

    _stopwatch
      ..reset()
      ..start();

    _startLevelAudio();
    notifyListeners();
  }

  Future<void> disposeSession() async {
    _ticker?.cancel();
    _stopwatch.stop();
    await PlayAccessService.instance.endGameplaySession(
      completedLevel: isSolved,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startTicker() {
    _stopwatch.start();
    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _session = _session.copyWith(elapsed: _stopwatch.elapsed);
      _checkTimerLimit();
      _handleSolvedAudioOnce();
      notifyListeners();
    });
  }

  void _checkLimitsAfterMove() {
    if (hasMoveLimit && _session.moveCount >= moveLimit! && !isSolved) {
      _moveLimitReached = true;
      _blockMessage = 'Move limit reached.';
    }
  }

  void _checkTimerLimit() {
    if (hasTimeLimit &&
        _stopwatch.elapsed.inSeconds >= timeLimitSeconds! &&
        !isSolved) {
      _timeExpired = true;
      _blockMessage = 'Time is up.';
    }
  }

  void _resetLimitFlagsAfterUndo() {
    if (hasMoveLimit && _session.moveCount < moveLimit!) {
      _moveLimitReached = false;
      if (!_timeExpired) {
        _blockMessage = null;
      }
    }
  }

  void _handleSolvedAudioOnce() {
    if (isSolved && !_didPlaySolvedSound) {
      _didPlaySolvedSound = true;
      unawaited(SoundService.instance.playLevelComplete());
    }
  }

  bool _sameContainerSnapshot(SortSession a, SortSession b) {
    if (a.containers.length != b.containers.length) return false;

    for (int i = 0; i < a.containers.length; i++) {
      final ac = a.containers[i];
      final bc = b.containers[i];

      if (ac.pieces.length != bc.pieces.length) {
        return false;
      }

      for (int j = 0; j < ac.pieces.length; j++) {
        if (ac.pieces[j].groupKey != bc.pieces[j].groupKey ||
            ac.pieces[j].amount != bc.pieces[j].amount ||
            ac.pieces[j].assetKey != bc.pieces[j].assetKey) {
          return false;
        }
      }
    }

    return true;
  }

  void _startLevelAudio() {
    final soundPack = _assetResolver.resolveSoundPack(
      _level.themeConfig.soundPackKey,
    );

    if (soundPack.containsKey('start')) {
      unawaited(SoundService.instance.playGameStart());
    }
  }

  void _playSuccessAudio() {
    final soundPack = _assetResolver.resolveSoundPack(
      _level.themeConfig.soundPackKey,
    );

    if (soundPack.containsKey('success')) {
      unawaited(SoundService.instance.playBlockPlace());
    }
  }

  void _playErrorAudio() {
    final soundPack = _assetResolver.resolveSoundPack(
      _level.themeConfig.soundPackKey,
    );

    if (soundPack.containsKey('error')) {
      unawaited(SoundService.instance.playFail());
    }
  }
}