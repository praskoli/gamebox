import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gamebox/features/memory_match/domain/memory_level.dart';
import '../../../core/models/player_profile.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/sound_service.dart';
import 'package:gamebox/features/memory_match/config/difficulty_config.dart';
import '../data/memory_progress_repository.dart';
import '../data/memory_world_registry.dart';
import '../domain/memory_card_model.dart';
import '../domain/memory_game_engine.dart';
import '../domain/memory_theme_pack.dart';

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

  late MemoryThemePack theme;
  late MemoryLevel level;

  List<MemoryCardModel> _cards = <MemoryCardModel>[];
  bool _isLoading = true;
  bool _isPreviewing = true;
  bool _isLocked = false;
  bool _isCompleted = false;

  int _moves = 0;
  int _matchesFound = 0;
  int _secondsElapsed = 0;

  int _score = 0;
  int _coinsEarned = 0;
  int _xpEarned = 0;

  Timer? _timer;
  int? _firstIndex;
  int? _secondIndex;

  PlayerProfile? _playerProfile;
  Set<String> _wrongCardIds = <String>{};
  Set<String> _justMatchedIds = <String>{};

  int _lastPointsAward = 0;
  int _pointsBurstTick = 0;

  MemoryReactionData? _reaction;
  int _reactionTick = 0;

  int _comboCount = 0;
  DateTime? _lastMatchTime;

  int _rewardAnimationTick = 0;

  bool get isLoading => _isLoading;
  bool get isPreviewing => _isPreviewing;
  bool get isLocked => _isLocked;
  bool get isCompleted => _isCompleted;

  int get moves => _moves;
  int get matchesFound => _matchesFound;
  int get secondsElapsed => _secondsElapsed;

  int get score => _score;
  int get coinsEarned => _coinsEarned;
  int get xpEarned => _xpEarned;
  int get rewardAnimationTick => _rewardAnimationTick;

  List<MemoryCardModel> get cards => _cards;
  int get totalPairs => level.totalPairs;
  PlayerProfile? get playerProfile => _playerProfile;

  int get lastPointsAward => _lastPointsAward;
  int get pointsBurstTick => _pointsBurstTick;

  MemoryReactionData? get reaction => _reaction;
  int get reactionTick => _reactionTick;

  int get comboCount => _comboCount;

  bool isWrongCard(String id) => _wrongCardIds.contains(id);
  bool isJustMatchedCard(String id) => _justMatchedIds.contains(id);

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    theme = MemoryWorldRegistry.byWorldId(worldId);
    level = MemoryWorldRegistry.generateLevel(worldId, levelNumber);

    _cards = MemoryGameEngine.buildBoard(
      level: level,
      theme: theme,
      seed: level.boardSeed,
    ).map((e) => e.copyWith(isFaceUp: true)).toList();

    _playerProfile = await ProfileService.instance.getProfile();

    _isLoading = false;
    _isPreviewing = level.hasPreview;
    notifyListeners();

    if (level.hasPreview) {
      await Future.delayed(Duration(milliseconds: level.previewMs));
      _cards = _cards.map((e) => e.copyWith(isFaceUp: false)).toList();
      _isPreviewing = false;
      notifyListeners();
    } else {
      _isPreviewing = false;
      notifyListeners();
    }

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsElapsed += 1;
      notifyListeners();
    });
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
    notifyListeners();
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

    Color color;
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
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (_reactionTick > 0) {
        _reaction = null;
        notifyListeners();
      }
    });
  }

  Future<void> onTapCard(int index) async {
    if (_isLoading || _isPreviewing || _isLocked || _isCompleted) return;
    if (index < 0 || index >= _cards.length) return;

    final tappedCard = _cards[index];
    if (tappedCard.isMatched || tappedCard.isFaceUp) return;

    _cards[index] = tappedCard.copyWith(isFaceUp: true);
    notifyListeners();

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    if (_firstIndex == index) return;

    _secondIndex = index;
    _isLocked = true;
    _moves += 1;
    notifyListeners();

    try {
      await Future.delayed(Duration(milliseconds: level.flipBackDelayMs));

      final firstIndex = _firstIndex;
      final secondIndex = _secondIndex;
      if (firstIndex == null || secondIndex == null) return;

      final first = _cards[firstIndex];
      final second = _cards[secondIndex];

      if (first.value == second.value) {
        await _handleMatch(firstIndex, secondIndex, first, second);
      } else {
        await _handleMismatch(firstIndex, secondIndex, first, second);
      }

      if (_matchesFound == totalPairs) {
        await _completeLevel();
      }
    } finally {
      _firstIndex = null;
      _secondIndex = null;
      _isLocked = false;
      notifyListeners();
    }
  }

  Future<void> _handleMatch(
      int firstIndex,
      int secondIndex,
      MemoryCardModel first,
      MemoryCardModel second,
      ) async {
    _safePlayMatchSound();

    _cards[firstIndex] = first.copyWith(
      isFaceUp: true,
      isMatched: true,
    );
    _cards[secondIndex] = second.copyWith(
      isFaceUp: true,
      isMatched: true,
    );

    _justMatchedIds = <String>{first.id, second.id};
    _matchesFound += 1;

    final now = DateTime.now();
    if (_lastMatchTime != null &&
        now.difference(_lastMatchTime!).inSeconds <= 4) {
      _comboCount += 1;
    } else {
      _comboCount = 1;
    }
    _lastMatchTime = now;

    final timeBonus =
    _secondsElapsed < 60 ? level.timeBonusFast : level.timeBonusSlow;
    final comboBonus = _comboCount > 1 ? ((_comboCount - 1) * 18) : 0;
    final specialBonus = level.isSpeedLevel
        ? 18
        : level.isMemoryProLevel
        ? 12
        : level.isRewardLevel
        ? 8
        : 0;

    final gained = level.matchPoints + timeBonus + comboBonus + specialBonus;

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

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 260));
    _justMatchedIds = <String>{};
    notifyListeners();
  }

  Future<void> _handleMismatch(
      int firstIndex,
      int secondIndex,
      MemoryCardModel first,
      MemoryCardModel second,
      ) async {
    _safePlayFailSound();

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

    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 260));

    _cards[firstIndex] = first.copyWith(isFaceUp: false);
    _cards[secondIndex] = second.copyWith(isFaceUp: false);
    _wrongCardIds = <String>{};

    _score = (_score - level.mismatchPenalty).clamp(0, 9999999).toInt();
    notifyListeners();
  }

  Future<void> _completeLevel() async {
    _timer?.cancel();
    _isCompleted = true;

    final stars = MemoryGameEngine.calculateStars(
      moves: _moves,
      level: level,
    );

    final finishTimeBonus = _secondsElapsed < 45
        ? (level.timeBonusFast * 2)
        : _secondsElapsed < 90
        ? level.timeBonusFast
        : level.timeBonusSlow;

    final comboFinishBonus = _comboCount > 1 ? (_comboCount * 12) : 0;

    _score += level.completionBonus + finishTimeBonus + comboFinishBonus;

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
      worldId: worldId,
      levelNumber: level.levelNumber,
      score: _score,
      stars: stars,
    );

    await ProfileService.instance.addGameCompletionRewards(
      coins: _coinsEarned,
      xp: _xpEarned,
    );

    _playerProfile = await ProfileService.instance.getProfile();
    notifyListeners();
  }

  int _calculateCoins(int stars) {
    var coins = level.baseCoins + (stars * 2);

    if (level.specialType == MemorySpecialLevelType.reward) {
      coins += 8;
    } else if (level.specialType == MemorySpecialLevelType.speed) {
      coins += 3;
    } else if (level.specialType == MemorySpecialLevelType.memoryPro) {
      coins += 4;
    }

    return coins.clamp(10, 40);
  }

  int _calculateXp(int stars) {
    var xp = level.baseXp + (stars * 4);

    if (_comboCount >= 3) {
      xp += 6;
    }

    return xp.clamp(20, 60);
  }

  int get earnedStars {
    return MemoryGameEngine.calculateStars(
      moves: _moves == 0 ? 999 : _moves,
      level: level,
    );
  }

  String get specialLevelLabel {
    switch (level.specialType) {
      case MemorySpecialLevelType.reward:
        return 'Reward Level';
      case MemorySpecialLevelType.speed:
        return 'Speed Level';
      case MemorySpecialLevelType.memoryPro:
        return 'Memory Pro';
      case MemorySpecialLevelType.normal:
        return 'Classic';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}