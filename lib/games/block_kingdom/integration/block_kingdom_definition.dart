import 'package:flutter/material.dart';
import '../../../game_engine/models/game_definition.dart';
import '../presentation/block_kingdom_screen.dart';

class BlockKingdomGameDefinition {
  static GameDefinition create() {
    return GameDefinition(
      id: 'block_kingdom',
      title: 'Block Kingdom',
      builder: (context) => const BlockKingdomScreen(),
      icon: Icons.grid_on,
      color: const Color(0xFFFF9800),
    );
  }
}