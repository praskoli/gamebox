import 'package:flutter/material.dart';

import '../../games/block_kingdom/domain/block_mode.dart';
import '../../games/block_kingdom/presentation/block_kingdom_map_screen.dart';
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
      final mode = blockMode ?? BlockMode.endless;

      if (mode == BlockMode.kingdom) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BlockKingdomMapScreen(),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlockKingdomScreen(
            mode: mode,
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