import 'dart:math';

import '../domain/block_piece.dart';
import '../domain/block_special_type.dart';
import '../progression/domain/level_definition.dart';

class BlockPieceLibrary {
  BlockPieceLibrary._();

  static final Random _random = Random();

  static final List<BlockPiece> _friendlyPieces = <BlockPiece>[
    const BlockPiece([[1]]),
    const BlockPiece([[1, 1]]),
    const BlockPiece([[1], [1]]),
    const BlockPiece([[1, 1, 1]]),
    const BlockPiece([[1], [1], [1]]),
    const BlockPiece([
      [1, 1],
      [1, 1],
    ]),
  ];

  static final List<BlockPiece> _standardPieces = <BlockPiece>[
    const BlockPiece([
      [1, 0],
      [1, 1],
    ]),
    const BlockPiece([
      [0, 1],
      [1, 1],
    ]),
    const BlockPiece([
      [1, 1, 1],
      [0, 1, 0],
    ]),
    const BlockPiece([
      [1, 1, 0],
      [0, 1, 1],
    ]),
    const BlockPiece([
      [0, 1, 1],
      [1, 1, 0],
    ]),
  ];

  static final List<BlockPiece> _trickyPieces = <BlockPiece>[
    const BlockPiece([
      [1, 1, 1, 1],
    ]),
    const BlockPiece([
      [1],
      [1],
      [1],
      [1],
    ]),
    const BlockPiece([
      [1, 0, 0],
      [1, 1, 1],
    ]),
    const BlockPiece([
      [0, 0, 1],
      [1, 1, 1],
    ]),
    const BlockPiece([
      [1, 1, 1],
      [1, 0, 0],
    ]),
    const BlockPiece([
      [1, 1, 1],
      [0, 0, 1],
    ]),
  ];

  static BlockPiece random() {
    final all = <BlockPiece>[
      ..._friendlyPieces,
      ..._standardPieces,
      ..._trickyPieces,
    ];
    return all[_random.nextInt(all.length)];
  }

  static List<BlockPiece> generateTray({
    required LevelDefinition levelDefinition,
  }) {
    final tray = <BlockPiece>[];

    final wantsRecoveryBomb = _shouldInjectRecoveryBomb(levelDefinition);

    if (wantsRecoveryBomb) {
      tray.add(const BlockPiece(
        [[1]],
        specialType: BlockSpecialType.bomb,
      ));
    }

    while (tray.length < levelDefinition.difficulty.traySize) {
      tray.add(randomWeighted(levelDefinition));
    }

    tray.shuffle(_random);
    return List<BlockPiece>.from(tray, growable: true);
  }

  static BlockPiece randomWeighted(LevelDefinition levelDefinition) {
    if (levelDefinition.allowBomb &&
        _random.nextDouble() < levelDefinition.bombChance) {
      return const BlockPiece(
        [[1]],
        specialType: BlockSpecialType.bomb,
      );
    }

    final difficulty = levelDefinition.difficulty;
    final total = difficulty.friendlyWeight +
        difficulty.standardWeight +
        difficulty.trickyWeight;

    final roll = _random.nextInt(total);

    if (roll < difficulty.friendlyWeight) {
      return _friendlyPieces[_random.nextInt(_friendlyPieces.length)];
    }

    if (roll < difficulty.friendlyWeight + difficulty.standardWeight) {
      return _standardPieces[_random.nextInt(_standardPieces.length)];
    }

    return _trickyPieces[_random.nextInt(_trickyPieces.length)];
  }

  static bool _shouldInjectRecoveryBomb(LevelDefinition levelDefinition) {
    if (!levelDefinition.allowBomb) return false;

    final level = levelDefinition.levelNumber;

    // Never spam bombs in early unlock range.
    if (level < 18) {
      return _random.nextDouble() < 0.10;
    }

    // Mid levels: occasional controlled recovery.
    if (level < 40) {
      return _random.nextDouble() < 0.14;
    }

    // Late levels: slightly more often, still not guaranteed.
    if (level < 75) {
      return _random.nextDouble() < 0.18;
    }

    return _random.nextDouble() < 0.22;
  }
}