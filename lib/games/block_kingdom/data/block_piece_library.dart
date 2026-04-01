import 'dart:math';

import '../domain/block_piece.dart';
import '../progression/domain/difficulty_config.dart';

class BlockPieceLibrary {
  BlockPieceLibrary._();

  static final Random _random = Random();

  static final List<BlockPiece> _friendlyPieces = <BlockPiece>[
    const BlockPiece([
      [1],
    ]),
    const BlockPiece([
      [1, 1],
    ]),
    const BlockPiece([
      [1],
      [1],
    ]),
    const BlockPiece([
      [1, 1, 1],
    ]),
    const BlockPiece([
      [1],
      [1],
      [1],
    ]),
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
    required DifficultyConfig difficulty,
  }) {
    return List<BlockPiece>.generate(
      difficulty.traySize,
          (_) => randomWeighted(difficulty),
      growable: true,
    );
  }

  static BlockPiece randomWeighted(DifficultyConfig difficulty) {
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