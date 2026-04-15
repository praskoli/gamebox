import 'package:flutter/material.dart';

import '../../../game_engine/models/game_definition.dart';
import '../presentation/screens/sort_puzzle_entry_screen.dart';

class SortPuzzleGameDefinition {
  static GameDefinition create() {
    return GameDefinition(
      id: 'sort_puzzle',
      title: 'Sort Puzzle Studio',
      builder: (BuildContext context) => const SortPuzzleEntryScreen(),
      icon: Icons.local_drink_rounded,
      color: const Color(0xFF17A8FF),
    );
  }
}
