import '../../../game_engine/models/game_definition.dart';
import 'memory_match_entry_screen.dart';
import 'package:flutter/material.dart';

class MemoryMatchGameDefinition {
  static GameDefinition create() {
    return GameDefinition(
      id: 'memory_match',
      title: 'Memory Match',
      builder: (context) => const MemoryMatchEntryScreen(),
      icon: Icons.grid_view_rounded,
      color: const Color(0xFF5B67F1),
    );
  }
}