import 'package:flutter/material.dart';

import '../../games/block_kingdom/domain/block_mode.dart';
import '../../games/block_kingdom/presentation/block_kingdom_screen.dart';
import '../catalog/game_registry.dart';

class GameLauncher {
  static Future<void> launch(
      BuildContext context,
      String gameId, {
        BlockMode? blockMode,
        int initialLevelNumber = 1,
      }) async {
    if (gameId == 'block_kingdom') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlockKingdomScreen(
            mode: blockMode ?? BlockMode.endless,
            initialLevelNumber: initialLevelNumber,
          ),
        ),
      );
      return;
    }

    final game = GameRegistry.get(gameId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => game.builder(context),
      ),
    );
  }
}