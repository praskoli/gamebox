import '../../../games/memory_match/domain/memory_gameplay_defaults.dart';
import '../../../games/memory_match/domain/memory_world_config.dart';
import '../../../games/memory_match/domain/memory_world_sequence_config.dart';

class MemoryWorldBundle {
  const MemoryWorldBundle({
    required this.worlds,
    required this.sequence,
    required this.gameplay,
  });

  final List<MemoryWorldConfig> worlds;
  final MemoryWorldSequenceConfig sequence;
  final MemoryGameplayDefaults gameplay;

  Map<String, MemoryWorldConfig> get worldById {
    return <String, MemoryWorldConfig>{
      for (final world in worlds) world.id: world,
    };
  }

  List<MemoryWorldConfig> get enabledWorlds {
    final List<MemoryWorldConfig> list = worlds.where((e) => e.enabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  int indexForWorldId(String worldId) {
    final list = enabledWorlds;
    final index = list.indexWhere((e) => e.id == worldId);
    return index >= 0 ? index : 0;
  }

  MemoryWorldConfig? configForWorldId(String worldId) {
    try {
      return worlds.firstWhere((e) => e.id == worldId);
    } catch (_) {
      return null;
    }
  }
}