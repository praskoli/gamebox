// lib/features/memory_match/domain/memory_game_engine.dart
import 'dart:async';
import 'dart:math';

import 'memory_card_model.dart';
import 'memory_level.dart';

class MemoryGameEngine {
  MemoryGameEngine({
    required this.level,
  }) {
    _cards = _buildCards(level);
  }

  final MemoryLevel level;

  late List<MemoryCardModel> _cards;
  final List<int> _selectedIndexes = <int>[];

  int _moves = 0;
  int _matches = 0;
  bool _isResolving = false;

  List<MemoryCardModel> get cards => List<MemoryCardModel>.unmodifiable(_cards);
  int get moves => _moves;
  int get matches => _matches;
  bool get isBusy => _isResolving;
  bool get isCompleted => _matches >= level.totalPairs;

  static List<MemoryCardModel> _buildCards(MemoryLevel level) {
    final Random random = Random(
      (level.levelNumber * 101) + (level.worldIndex * 17),
    );

    final List<String> source = List<String>.from(level.theme.itemPool)
      ..shuffle(random);

    final List<String> pairValues = source.take(level.totalPairs).toList();
    final List<String> values = <String>[...pairValues, ...pairValues]
      ..shuffle(random);

    return List<MemoryCardModel>.generate(
      values.length,
          (int index) => MemoryCardModel(
        id: '${level.theme.id}_${level.levelNumber}_$index',
        value: values[index],
        themeId: level.theme.id,
      ),
    );
  }

  void reset() {
    _moves = 0;
    _matches = 0;
    _isResolving = false;
    _selectedIndexes.clear();
    _cards = _buildCards(level);
  }

  void revealAll() {
    _cards = _cards
        .map((MemoryCardModel card) => card.copyWith(isFaceUp: true))
        .toList();
  }

  void hideUnmatched() {
    _cards = _cards.map((MemoryCardModel card) {
      if (card.isMatched) return card;
      return card.copyWith(isFaceUp: false, isLocked: false);
    }).toList();
  }

  Future<FlipResult> flip(int index) async {
    if (_isResolving) return FlipResult.ignored();
    if (index < 0 || index >= _cards.length) return FlipResult.ignored();

    final MemoryCardModel tapped = _cards[index];
    if (tapped.isMatched || tapped.isFaceUp) {
      return FlipResult.ignored();
    }

    _cards[index] = tapped.copyWith(isFaceUp: true);
    _selectedIndexes.add(index);

    if (_selectedIndexes.length < 2) {
      return FlipResult.progress(revealedIndex: index);
    }

    _moves++;
    _isResolving = true;

    final int firstIndex = _selectedIndexes[0];
    final int secondIndex = _selectedIndexes[1];

    final MemoryCardModel first = _cards[firstIndex];
    final MemoryCardModel second = _cards[secondIndex];

    if (first.value == second.value) {
      _cards[firstIndex] = first.copyWith(isMatched: true, isLocked: true);
      _cards[secondIndex] = second.copyWith(isMatched: true, isLocked: true);
      _matches++;
      _selectedIndexes.clear();
      _isResolving = false;

      return FlipResult.match(
        firstIndex: firstIndex,
        secondIndex: secondIndex,
        completed: isCompleted,
      );
    }

    await Future<void>.delayed(
      Duration(milliseconds: level.flipBackDelayMs),
    );

    _cards[firstIndex] = _cards[firstIndex].copyWith(
      isFaceUp: false,
      isLocked: false,
    );
    _cards[secondIndex] = _cards[secondIndex].copyWith(
      isFaceUp: false,
      isLocked: false,
    );

    _selectedIndexes.clear();
    _isResolving = false;

    return FlipResult.mismatch(
      firstIndex: firstIndex,
      secondIndex: secondIndex,
    );
  }
}

class FlipResult {
  const FlipResult._({
    required this.didFlip,
    required this.isMatch,
    required this.isMismatch,
    required this.completed,
    this.revealedIndex,
    this.firstIndex,
    this.secondIndex,
  });

  final bool didFlip;
  final bool isMatch;
  final bool isMismatch;
  final bool completed;
  final int? revealedIndex;
  final int? firstIndex;
  final int? secondIndex;

  factory FlipResult.ignored() {
    return const FlipResult._(
      didFlip: false,
      isMatch: false,
      isMismatch: false,
      completed: false,
    );
  }

  factory FlipResult.progress({
    int? revealedIndex,
  }) {
    return FlipResult._(
      didFlip: true,
      isMatch: false,
      isMismatch: false,
      completed: false,
      revealedIndex: revealedIndex,
    );
  }

  factory FlipResult.match({
    required int firstIndex,
    required int secondIndex,
    required bool completed,
  }) {
    return FlipResult._(
      didFlip: true,
      isMatch: true,
      isMismatch: false,
      completed: completed,
      firstIndex: firstIndex,
      secondIndex: secondIndex,
    );
  }

  factory FlipResult.mismatch({
    required int firstIndex,
    required int secondIndex,
  }) {
    return FlipResult._(
      didFlip: true,
      isMatch: false,
      isMismatch: true,
      completed: false,
      firstIndex: firstIndex,
      secondIndex: secondIndex,
    );
  }
}