import 'dart:math';

import 'memory_card_model.dart';
import 'memory_level.dart';
import 'memory_theme_pack.dart';

class MemoryGameEngine {
  const MemoryGameEngine._();

  static List<MemoryCardModel> buildBoard({
    required MemoryLevel level,
    required MemoryThemePack theme,
    required int seed,
  }) {
    final sourceItems = level.tileValues.isNotEmpty
        ? level.tileValues
        : theme.items.take(level.totalPairs).toList(growable: false);

    final items = sourceItems.take(level.totalPairs).toList(growable: false);
    final pairs = <MemoryCardModel>[];

    var counter = 0;
    for (final item in items) {
      pairs.add(
        MemoryCardModel(
          id: 'c_${counter++}_a',
          value: item,
          isFaceUp: false,
          isMatched: false,
        ),
      );
      pairs.add(
        MemoryCardModel(
          id: 'c_${counter++}_b',
          value: item,
          isFaceUp: false,
          isMatched: false,
        ),
      );
    }

    final shuffled = List<MemoryCardModel>.from(pairs);
    _strongShuffle(shuffled, seed);

    return shuffled;
  }

  static void _strongShuffle(List<MemoryCardModel> items, int seed) {
    final rng = Random(seed);

    for (var pass = 0; pass < 3; pass++) {
      items.shuffle(rng);
    }

    for (var i = items.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = items[i];
      items[i] = items[j];
      items[j] = temp;
    }

    _reduceImmediatePatternClumps(items, rng);
  }

  static void _reduceImmediatePatternClumps(
      List<MemoryCardModel> items,
      Random rng,
      ) {
    if (items.length < 4) return;

    for (var i = 1; i < items.length; i++) {
      if (items[i].value == items[i - 1].value) {
        final swapIndex = _findSwapCandidate(items, i, rng);
        if (swapIndex != -1) {
          final temp = items[i];
          items[i] = items[swapIndex];
          items[swapIndex] = temp;
        }
      }
    }
  }

  static int _findSwapCandidate(
      List<MemoryCardModel> items,
      int index,
      Random rng,
      ) {
    final candidates = <int>[];

    for (var i = index + 1; i < items.length; i++) {
      if (items[i].value != items[index].value &&
          items[i].value != items[index - 1].value) {
        candidates.add(i);
      }
    }

    if (candidates.isEmpty) return -1;
    return candidates[rng.nextInt(candidates.length)];
  }

  static int calculateScore({
    required int matchesFound,
    required int moves,
    required int secondsElapsed,
  }) {
    final base = matchesFound * 100;
    final efficiencyBonus = max(0, 200 - (moves * 5));
    final timeBonus = max(0, 300 - (secondsElapsed * 3));
    return base + efficiencyBonus + timeBonus;
  }

  static int calculateStars({
    required int moves,
    required MemoryLevel level,
  }) {
    if (moves <= level.targetStarsMoves) return 3;
    if (moves <= level.targetStarsMoves + 4) return 2;
    return 1;
  }
}