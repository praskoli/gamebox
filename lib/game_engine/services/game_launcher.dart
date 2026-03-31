import 'package:flutter/material.dart';
import '../catalog/game_registry.dart';

class GameLauncher {
  static Future<void> launch(
      BuildContext context,
      String gameId,
      ) async {
    final game = GameRegistry.get(gameId);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => game.builder(context),
      ),
    );
  }
}