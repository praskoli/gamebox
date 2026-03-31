import 'package:flutter/widgets.dart';
import '../models/game_definition.dart';

class GameRegistry {
  static final Map<String, GameDefinition> _games = {};

  static void register(GameDefinition game) {
    _games[game.id] = game;
  }

  static GameDefinition get(String id) {
    final game = _games[id];
    if (game == null) {
      throw Exception('Game not found: $id');
    }
    return game;
  }

  static List<GameDefinition> getAll() {
    return _games.values.toList();
  }
}