import 'dart:async';
import 'dart:collection';

import '../../../games/memory_match/domain/memory_level.dart';
import '../domain/memory_theme_pack.dart';
import '../../../games/memory_match/domain/memory_world_bundle.dart';
import '../../../games/memory_match/domain/memory_world_config.dart';
import 'memory_world_config_repository.dart';

class MemoryWorldRegistry {
  MemoryWorldRegistry._();

  static final MemoryWorldConfigRepository _repository =
      MemoryWorldConfigRepository.instance;

  static MemoryWorldBundle? _bundle;
  static StreamSubscription<MemoryWorldBundle>? _bundleSub;
  static final StreamController<MemoryWorldBundle> _updatesController =
  StreamController<MemoryWorldBundle>.broadcast();

  static const String fruitsWorldId = 'fruits';
  static const String animalsWorldId = 'animals';
  static const String vehiclesWorldId = 'vehicles';
  static const String mixedAllWorldId = 'mixed_all';

  static Stream<MemoryWorldBundle> get updates => _updatesController.stream;

  static Future<void> ensureInitialized({bool forceRefresh = false}) async {
    _bundle = await _repository.loadBundle(forceRefresh: forceRefresh);

    _bundleSub ??= _repository.bundleUpdates.listen((bundle) {
      _bundle = bundle;
      if (!_updatesController.isClosed) {
        _updatesController.add(bundle);
      }
    });
  }

  static MemoryWorldBundle get _safeBundle =>
      _bundle ?? _repository.fallbackBundle;

  static List<String> get availableWorldIds =>
      _safeBundle.enabledWorlds.map((e) => e.id).toList(growable: false);

  static String resolveWorldId({
    required String requestedWorldId,
    required int levelNumber,
  }) {
    final MemoryWorldBundle bundle = _safeBundle;

    if (requestedWorldId.trim().isNotEmpty) {
      final explicit = bundle.configForWorldId(requestedWorldId.trim());
      if (explicit != null && explicit.enabled) {
        return explicit.id;
      }
    }

    final String fromSequence = bundle.sequence.worldIdForGlobalLevel(levelNumber);
    final MemoryWorldConfig? config = bundle.configForWorldId(fromSequence);
    if (config != null && config.enabled) {
      return config.id;
    }

    return bundle.sequence.fallbackWorldId;
  }

  static MemoryThemePack byWorldId(String worldId) {
    final MemoryWorldBundle bundle = _safeBundle;
    final String safeWorldId = worldId.trim().isEmpty
        ? bundle.sequence.fallbackWorldId
        : worldId.trim();

    final MemoryWorldConfig config = bundle.configForWorldId(safeWorldId) ??
        bundle.configForWorldId(bundle.sequence.fallbackWorldId) ??
        bundle.enabledWorlds.first;

    final List<String> resolvedItems = _resolvedItemPool(config, bundle);
    return MemoryThemePack.fromConfig(
      config,
      resolvedItemPool: resolvedItems,
    );
  }

  static MemoryThemePack themeForWorld(String worldId) {
    return byWorldId(worldId);
  }

  static MemoryThemePack themeForGlobalLevel(int levelNumber) {
    final String worldId = worldIdForGlobalLevel(levelNumber);
    return byWorldId(worldId);
  }

  static int worldIndexForGlobalLevel(int levelNumber) {
    final MemoryWorldBundle bundle = _safeBundle;
    final String worldId = worldIdForGlobalLevel(levelNumber);
    final int sequenceSectionIndex =
    bundle.sequence.sectionIndexForGlobalLevel(levelNumber);
    final int worldIndex = bundle.indexForWorldId(worldId);

    return sequenceSectionIndex >= 0 ? sequenceSectionIndex : worldIndex;
  }

  static String worldIdForGlobalLevel(int levelNumber) {
    final MemoryWorldBundle bundle = _safeBundle;
    return bundle.sequence.worldIdForGlobalLevel(levelNumber);
  }

  static MemoryLevel generateGlobalLevel(int levelNumber) {
    final MemoryWorldBundle bundle = _safeBundle;
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    final String worldId = bundle.sequence.worldIdForGlobalLevel(safeLevel);

    return generateLevel(
      worldId: worldId,
      levelNumber: safeLevel,
    );
  }

  static MemoryLevel generateLevel({
    required String worldId,
    required int levelNumber,
  }) {
    final MemoryWorldBundle bundle = _safeBundle;
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    final String resolvedWorldId = resolveWorldId(
      requestedWorldId: worldId,
      levelNumber: safeLevel,
    );

    final MemoryThemePack theme = byWorldId(resolvedWorldId);
    final grid = bundle.gameplay.gridForLevel(safeLevel);

    final bool isRewardLevel = bundle.gameplay.isRewardLevel(safeLevel);
    final bool isSpeedLevel = bundle.gameplay.isSpeedLevel(safeLevel);
    final bool isMemoryProLevel = bundle.gameplay.isMemoryProLevel(safeLevel);

    final int previewDurationMs =
    bundle.gameplay.previewDurationMsForLevel(safeLevel);

    final int flipBackDelayMs =
    bundle.gameplay.flipBackDelayMsForLevel(safeLevel);

    final int rewardCoins = bundle.gameplay.rewardCoinsForLevel(safeLevel);

    return MemoryLevel(
      levelNumber: safeLevel,
      worldIndex: bundle.indexForWorldId(resolvedWorldId),
      theme: theme,
      gridColumns: grid.columns,
      gridRows: grid.rows,
      previewDurationMs: previewDurationMs,
      flipBackDelayMs: flipBackDelayMs,
      rewardCoins: rewardCoins,
      isRewardLevel: isRewardLevel,
      isSpeedLevel: isSpeedLevel,
      isMemoryProLevel: isMemoryProLevel,
    );
  }

  static List<MemoryLevel> generateLevelWindow({
    required String worldId,
    required int startLevel,
    required int count,
  }) {
    final int safeStart = startLevel < 1 ? 1 : startLevel;
    final int safeCount = count < 1 ? 1 : count;

    return List<MemoryLevel>.generate(
      safeCount,
          (int index) => generateLevel(
        worldId: worldId,
        levelNumber: safeStart + index,
      ),
    );
  }

  static List<String> _resolvedItemPool(
      MemoryWorldConfig config,
      MemoryWorldBundle bundle,
      ) {
    final LinkedHashSet<String> resolved = LinkedHashSet<String>();

    for (final item in config.itemPool) {
      final trimmed = item.trim();
      if (trimmed.isNotEmpty) {
        resolved.add(trimmed);
      }
    }

    for (final sourceId in config.mixedSourceWorldIds) {
      final source = bundle.configForWorldId(sourceId);
      if (source == null) continue;
      for (final item in source.itemPool) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) {
          resolved.add(trimmed);
        }
      }
    }

    if (resolved.isEmpty) {
      final fallback = bundle.configForWorldId(bundle.sequence.fallbackWorldId);
      if (fallback != null) {
        for (final item in fallback.itemPool) {
          final trimmed = item.trim();
          if (trimmed.isNotEmpty) {
            resolved.add(trimmed);
          }
        }
      }
    }

    final int safeMax =
    config.maxUniqueItems <= 0 ? resolved.length : config.maxUniqueItems;

    return resolved.take(safeMax).toList(growable: false);
  }

  static Future<void> dispose() async {
    await _bundleSub?.cancel();
    await _updatesController.close();
  }
}