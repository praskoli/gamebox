import '../../../game_engine/models/game_definition.dart';
import 'memory_match_entry_screen.dart';

class MemoryMatchGameDefinition {
  static GameDefinition create() {
    return GameDefinition(
      id: 'memory_match',
      title: 'Memory Match',
      builder: (context) => const MemoryMatchEntryScreen(),
    );
  }
}