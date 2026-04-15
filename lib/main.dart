import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'game_engine/catalog/game_registry.dart';
import 'games/memory_match/integration/memory_match_game_definition.dart';
import 'games/block_kingdom/integration/block_kingdom_definition.dart';
import 'games/sort_puzzle/integration/sort_puzzle_game_definition.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  GameRegistry.register(
    MemoryMatchGameDefinition.create(),
  );
  GameRegistry.register(
    BlockKingdomGameDefinition.create(),
  );
  GameRegistry.register(
    SortPuzzleGameDefinition.create(),
  );

  runApp(const GameBoxApp());
}