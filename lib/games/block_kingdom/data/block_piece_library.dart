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
    return List<BlockPiece>.generate(
      levelDefinition.difficulty.traySize,
          (_) => randomWeighted(levelDefinition),
      growable: true,
    );
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
}