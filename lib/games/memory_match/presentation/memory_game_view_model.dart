import 'dart:async';

import 'package:flutter/material.dart';
import '../../../platform/profile/services/profile_service.dart';
import '../../../platform/player/services/player_stats_service.dart';
import '../../../platform/player/player_profile.dart';
import '../../../platform/profile/services/profile_service.dart';
import '../../../platform/audio/sound_service.dart';
import '../../../platform/play_access/data/play_access_service.dart';
import '../../../platform/play_access/data/play_pause_message_library.dart';
import '../../../platform/play_access/domain/play_pause_message.dart';
import '../data/memory_progress_repository.dart';
import '../data/memory_world_registry.dart';
import '../../../games/memory_match/domain/memory_card_model.dart';
import '../domain/memory_game_engine.dart';
import '../../../games/memory_match/domain/memory_level.dart';
import '../domain/memory_theme_pack.dart';
import '../../../games/memory_match/domain/memory_world_bundle.dart';

enum MemoryReactionType {
  success,
  fail,
  complete,
}

class MemoryReactionData {
  const MemoryReactionData({
    required this.text,
    required this.emoji,
    required this.color,
    required this.type,
  });

  final String text;
  final String emoji;
  final Color color;
  final MemoryReactionType type;
}

class MemoryGameViewModel extends ChangeNotifier {
  MemoryGameViewModel({
    required this.worldId,
    required this.levelNumber,
  });

  final String worldId;
  final int levelNumber;

  final PlayAccessService _playAccessService = PlayAccessService.instance;

  late MemoryThemePack theme;
  late MemoryLevel level;
  late MemoryGameEngine _engine;
  bool _hasPersistedCompletion = false;
  bool _isLoading = true;
  bool _isPreviewing = false;
  bool _isCompleted = false;
  bool _playAccessSessionStarted = false;
// 🔧 TEMP COMPATIBILITY (old screen expects these)
  bool get isParentControlEnabled => false;
  int get tokensRemaining => 0;
  bool get isLevelLocked => false;
  int _secondsElapsed = 0;
  int _score = 0;

  Timer? _timer;
  Timer? _clearWrongTimer;
  Timer? _clearMatchedTimer;
  Timer? _clearReactionTimer;
  Timer? _softPauseReminderTimer;
  StreamSubscription<MemoryWorldBundle>? _bundleUpdatesSub;

  PlayerProfile? _playerProfile;

  int _coinsEarned = 0;
  int _xpEarned = 0;
  int _rewardAnimationTick = 0;

  int _lastPointsAward = 0;
  int _pointsBurstTick = 0;

  int _comboCount = 0;
  DateTime? _lastMatchTime;

  MemoryReactionData? _reaction;
  int _reactionTick = 0;

  Set<String> _wrongCardIds = <String>{};
  Set<String> _justMatchedIds = <String>{};

  bool _showSoftPauseReminder = false;
  PlayPauseMessage? _softPauseMessage;

  bool get isLoading => _isLoading;
  bool get isPreviewing => _isPreviewing;
  bool get isCompleted => _isCompleted;

  int get moves => _engine.moves;
  int get matchesFound => _engine.matches;
  int get totalPairs => level.totalPairs;
  int get secondsElapsed => _secondsElapsed;
  int get score => _score;

  int get coinsEarned => _coinsEarned;
  int get xpEarned => _xpEarned;
  int get rewardAnimationTick => _rewardAnimationTick;

  List<MemoryCardModel> get cards => _engine.cards;
  PlayerProfile? get playerProfile => _playerProfile;

  int get lastPointsAward => _lastPointsAward;
  int get pointsBurstTick => _pointsBurstTick;

  MemoryReactionData? get reaction => _reaction;
  int get reactionTick => _reactionTick;

  int get comboCount => _comboCount;

  bool get showSoftPauseReminder => _showSoftPauseReminder;
  PlayPauseMessage? get softPauseMessage => _softPauseMessage;

  int get pauseMessageSeed =>
      levelNumber + level.levelNumber + _secondsElapsed + moves;

  bool isWrongCard(String id) => _wrongCardIds.contains(id);
  bool isJustMatchedCard(String id) => _justMatchedIds.contains(id);

  Future<void> requestUnlockFromParent() async {
    // Parent token flow is no longer used for gameplay unlock.
    // OTP-based unlock happens on the map screen via PlayAccess.
  }
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await MemoryWorldRegistry.ensureInitialized();
    await _playAccessService.initialize();
    _bindLiveUpdates();

    await _setupLevel();
  }

  Future<void> _setupLevel() async {
    final String resolvedWorldId = MemoryWorldRegistry.resolveWorldId(
      requestedWorldId: worldId,
      levelNumber: levelNumber,
    );

    theme = MemoryWorldRegistry.byWorldId(resolvedWorldId);
    level = MemoryWorldRegistry.generateLevel(
      worldId: resolvedWorldId,
      levelNumber: levelNumber,
    );

    _engine = MemoryGameEngine(level: level);

    try {
      _playerProfile = await ProfileService.instance.getProfile();
    } catch (_) {
      _playerProfile = null;
    }

    _score = 0;
    _secondsElapsed = 0;
    _coinsEarned = 0;
    _xpEarned = 0;
    _rewardAnimationTick = 0;
    _comboCount = 0;
    _lastMatchTime = null;
    _lastPointsAward = 0;
    _pointsBurstTick = 0;
    _reaction = null;
    _reactionTick = 0;
    _wrongCardIds = <String>{};
    _justMatchedIds = <String>{};
    _isCompleted = false;
    _showSoftPauseReminder = false;
    _softPauseMessage = null;
    _playAccessSessionStarted = false;

    if (level.previewDurationMs > 0) {
      _isPreviewing = true;
      _engine.revealAll();
      _isLoading = false;
      notifyListeners();

      await Future.delayed(Duration(milliseconds: level.previewDurationMs));

      _engine.hideUnmatched();
      _isPreviewing = false;
      notifyListeners();
    } else {
      _isPreviewing = false;
      _isLoading = false;
      notifyListeners();
    }

    await _beginPlayAccessSessionIfNeeded();
    _startTimer();
    _scheduleSoftPauseReminder();
  }
  Future<void> persistCompletionRewards() async {
    if (!_isCompleted) return;
    if (_hasPersistedCompletion) return;

    _hasPersistedCompletion = true;

    await ProfileService.instance.addGameCompletionRewards(
      coins: coinsEarned,
      xp: xpEarned,
    );

    await PlayerStatsService.instance.recordGameCompletion(
      gameId: 'memory_match',
      xp: xpEarned,
      coins: coinsEarned,
      levelNumber: level.levelNumber,
      score: score,
    );
  }
  Future<void> _beginPlayAccessSessionIfNeeded() async {
    if (_playAccessSessionStarted) return;
    await _playAccessService.beginGameplaySession(
      gameId: 'memory_match',
      levelNumber: level.levelNumber,
    );
    _playAccessSessionStarted = true;
  }

  void _bindLiveUpdates() {
    _bundleUpdatesSub?.cancel();
    _bundleUpdatesSub = MemoryWorldRegistry.updates.listen((_) async {
      if (_isCompleted) return;
      if (_secondsElapsed > 0 || _engine.moves > 0 || _engine.matches > 0) {
        return;
      }

      final String previousThemeId = theme.id;
      final int previousPreview = level.previewDurationMs;

      final String resolvedWorldId = MemoryWorldRegistry.resolveWorldId(
        requestedWorldId: worldId,
        levelNumber: levelNumber,
      );

      final nextTheme = MemoryWorldRegistry.byWorldId(resolvedWorldId);
      final nextLevel = MemoryWorldRegistry.generateLevel(
        worldId: resolvedWorldId,
        levelNumber: levelNumber,
      );

      final bool changed = previousThemeId != nextTheme.id ||
          previousPreview != nextLevel.previewDurationMs ||
          level.gridColumns != nextLevel.gridColumns ||
          level.gridRows != nextLevel.gridRows;

      if (!changed) return;

      theme = nextTheme;
      level = nextLevel;
      _engine = MemoryGameEngine(level: level);
      notifyListeners();
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsElapsed += 1;
      notifyListeners();
    });
  }

  void _scheduleSoftPauseReminder() {
    _softPauseReminderTimer?.cancel();

    _softPauseReminderTimer = Timer(const Duration(seconds: 18), () {
      if (_isCompleted) return;
      if (_secondsElapsed > 0 || moves > 0 || matchesFound > 0) {
        _softPauseMessage =
            PlayPauseMessageLibrary.pickBreakMessage(level.levelNumber);
        _showSoftPauseReminder = true;
        notifyListeners();
      }
    });
  }

  void dismissSoftPauseReminder() {
    if (!_showSoftPauseReminder) return;
    _showSoftPauseReminder = false;
    notifyListeners();
  }

  void _safePlayMatchSound() {
    unawaited(SoundService.instance.playMatch().catchError((_) {}));
  }

  void _safePlayFailSound() {
    unawaited(SoundService.instance.playFail().catchError((_) {}));
  }

  void _safePlayWinSound() {
    unawaited(SoundService.instance.playWin().catchError((_) {}));
  }

  void _emitPoints(int value) {
    if (value <= 0) return;
    _lastPointsAward = value;
    _pointsBurstTick += 1;
  }

  void _emitReaction({
    required MemoryReactionType type,
    required List<Map<String, String>> options,
    bool useCombo = false,
  }) {
    if (options.isEmpty) return;

    final picked =
    options[DateTime.now().microsecondsSinceEpoch % options.length];
    final comboText = useCombo && _comboCount > 1 ? ' ${_comboCount}x' : '';

    final Color color;
    switch (type) {
      case MemoryReactionType.success:
        color = const Color(0xFF5B67F1);
        break;
      case MemoryReactionType.fail:
        color = const Color(0xFFEF4444);
        break;
      case MemoryReactionType.complete:
        color = const Color(0xFFF59E0B);
        break;
    }

    _reaction = MemoryReactionData(
      text: '${picked['text']!}$comboText',
      emoji: picked['emoji']!,
      color: color,
      type: type,
    );
    _reactionTick += 1;

    _clearReactionTimer?.cancel();
    _clearReactionTimer = Timer(const Duration(milliseconds: 900), () {
      _reaction = null;
      notifyListeners();
    });
  }

  Future<void> onTapCard(int index) async {
    if (_isLoading || _isPreviewing || _isCompleted || _engine.isBusy) return;
    if (index < 0 || index >= _engine.cards.length) return;

    _playAccessService.recordUserInteraction();

    if (_showSoftPauseReminder) {
      _showSoftPauseReminder = false;
    }

    final FlipResult result = await _engine.flip(index);

    if (!result.didFlip) return;

    if (result.isMatch) {
      await _handleMatch(result);
      if (result.completed) {
        await _completeLevel();
      }
    } else if (result.isMismatch) {
      await _handleMismatch(result);
    }

    notifyListeners();
  }

  Future<void> _handleMatch(FlipResult result) async {
    _safePlayMatchSound();

    final int? firstIndex = result.firstIndex;
    final int? secondIndex = result.secondIndex;
    if (firstIndex == null || secondIndex == null) return;

    final first = _engine.cards[firstIndex];
    final second = _engine.cards[secondIndex];

    _justMatchedIds = <String>{first.id, second.id};

    final now = DateTime.now();
    if (_lastMatchTime != null &&
        now.difference(_lastMatchTime!).inSeconds <= 4) {
      _comboCount += 1;
    } else {
      _comboCount = 1;
    }
    _lastMatchTime = now;

    final int timeBonus = _secondsElapsed < 60 ? 12 : 5;
    final int comboBonus = _comboCount > 1 ? ((_comboCount - 1) * 18) : 0;
    final int specialBonus = level.isSpeedLevel
        ? 18
        : level.isMemoryProLevel
        ? 12
        : level.isRewardLevel
        ? 8
        : 0;

    final int gained = 100 + timeBonus + comboBonus + specialBonus;

    _score += gained;
    _emitPoints(gained);

    _emitReaction(
      type: MemoryReactionType.success,
      useCombo: true,
      options: const [
        {'emoji': '🔥', 'text': 'WOW!'},
        {'emoji': '✨', 'text': 'GREAT!'},
        {'emoji': '💥', 'text': 'AWESOME!'},
        {'emoji': '⚡', 'text': 'FAST!'},
        {'emoji': '🎯', 'text': 'PERFECT!'},
      ],
    );

    _clearMatchedTimer?.cancel();
    _clearMatchedTimer = Timer(const Duration(milliseconds: 260), () {
      _justMatchedIds = <String>{};
      notifyListeners();
    });
  }

  Future<void> _handleMismatch(FlipResult result) async {
    _safePlayFailSound();

    final int? firstIndex = result.firstIndex;
    final int? secondIndex = result.secondIndex;
    if (firstIndex == null || secondIndex == null) return;

    final first = _engine.cards[firstIndex];
    final second = _engine.cards[secondIndex];

    _wrongCardIds = <String>{first.id, second.id};
    _comboCount = 0;
    _lastMatchTime = null;

    _emitReaction(
      type: MemoryReactionType.fail,
      options: const [
        {'emoji': '😅', 'text': 'OOPS!'},
        {'emoji': '🙈', 'text': 'TRY AGAIN!'},
        {'emoji': '😵', 'text': 'NOOO!'},
      ],
    );

    _score = (_score - 8).clamp(0, 9999999).toInt();

    _clearWrongTimer?.cancel();
    _clearWrongTimer = Timer(const Duration(milliseconds: 260), () {
      _wrongCardIds = <String>{};
      notifyListeners();
    });
  }

  Future<void> _completeLevel() async {
    _timer?.cancel();
    _isCompleted = true;

    final stars = earnedStars;

    final int finishTimeBonus = _secondsElapsed < 45
        ? 40
        : _secondsElapsed < 90
        ? 24
        : 10;

    final int comboFinishBonus = _comboCount > 1 ? (_comboCount * 12) : 0;

    _score += 180 + finishTimeBonus + comboFinishBonus;

    _coinsEarned = _calculateCoins(stars);
    _xpEarned = _calculateXp(stars);
    _rewardAnimationTick += 1;

    _safePlayWinSound();

    _emitReaction(
      type: MemoryReactionType.complete,
      options: const [
        {'emoji': '🏆', 'text': 'AMAZING!'},
        {'emoji': '🎉', 'text': 'FANTASTIC!'},
        {'emoji': '🚀', 'text': 'BRILLIANT!'},
      ],
    );

    await MemoryProgressRepository.instance.saveLevelResult(
      worldId: level.worldId,
      levelNumber: level.levelNumber,
      score: _score,
      stars: stars,
    );

    if (_playAccessSessionStarted) {
      await _playAccessService.endGameplaySession(
        completedLevel: true,
      );
      _playAccessSessionStarted = false;
    }

    notifyListeners();
  }

  int _calculateCoins(int stars) {
    int coins = level.rewardCoins + (stars * 2);

    if (level.isRewardLevel) {
      coins += 8;
    } else if (level.isSpeedLevel) {
      coins += 3;
    } else if (level.isMemoryProLevel) {
      coins += 4;
    }

    return coins.clamp(10, 60);
  }

  int _calculateXp(int stars) {
    int xp = 20 + (stars * 4) + (level.levelNumber ~/ 2);

    if (_comboCount >= 3) {
      xp += 6;
    }

    return xp.clamp(20, 80);
  }

  int get earnedStars {
    if (moves <= totalPairs + 3) return 3;
    if (moves <= totalPairs + 6) return 2;
    return 1;
  }

  String get specialLevelLabel {
    if (level.isRewardLevel) return 'Reward Level';
    if (level.isSpeedLevel) return 'Speed Level';
    if (level.isMemoryProLevel) return 'Memory Pro';
    return 'Classic';
  }

  @override
  void dispose() {
    if (_playAccessSessionStarted && !_isCompleted) {
      unawaited(
        _playAccessService.endGameplaySession(
          completedLevel: false,
        ),
      );
      _playAccessSessionStarted = false;
    }

    _bundleUpdatesSub?.cancel();
    _timer?.cancel();
    _clearWrongTimer?.cancel();
    _clearMatchedTimer?.cancel();
    _clearReactionTimer?.cancel();
    _softPauseReminderTimer?.cancel();
    super.dispose();
  }
}