import 'dart:async';

import 'package:flutter/material.dart';

import '../data/memory_progress_repository.dart';
import '../../../games/memory_match/data/memory_world_registry.dart';
import '../../../games/memory_match/domain/memory_level.dart';
import '../domain/memory_progress.dart';
import '../domain/memory_theme_pack.dart';
import '../../../games/memory_match/domain/memory_world_bundle.dart';

class MemoryWorldMapViewModel extends ChangeNotifier {
  MemoryWorldMapViewModel({
    required this.worldId,
  });

  final String worldId;

  bool _isLoading = true;
  String? _error;
  MemoryThemePack? _theme;
  List<MemoryLevel> _levels = const [];
  MemoryProgress? _progress;

  int _windowStart = 1;
  int _windowCount = 120;
  int? _highlightLevel;

  StreamSubscription<MemoryWorldBundle>? _bundleUpdatesSub;

  bool get isLoading => _isLoading;
  String? get error => _error;
  MemoryThemePack? get theme => _theme;
  List<MemoryLevel> get levels => _levels;
  MemoryProgress? get progress => _progress;
  int? get highlightLevel => _highlightLevel;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await MemoryWorldRegistry.ensureInitialized();
      _bindLiveUpdates();

      await _reloadFromRegistry();
    } catch (e) {
      _error = 'Failed to load memory world: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _bindLiveUpdates() {
    _bundleUpdatesSub?.cancel();
    _bundleUpdatesSub = MemoryWorldRegistry.updates.listen((_) async {
      try {
        await _reloadFromRegistry();
        notifyListeners();
      } catch (_) {}
    });
  }

  Future<void> _reloadFromRegistry() async {
    final String resolvedWorldId = MemoryWorldRegistry.resolveWorldId(
      requestedWorldId: worldId,
      levelNumber: 1,
    );

    _theme = MemoryWorldRegistry.byWorldId(resolvedWorldId);
    _progress = await MemoryProgressRepository.instance.getProgress(resolvedWorldId);

    final unlocked = _progress?.unlockedLevel ?? 1;

    _windowStart = 1;
    _levels = MemoryWorldRegistry.generateLevelWindow(
      worldId: resolvedWorldId,
      startLevel: _windowStart,
      count: _windowCount,
    );

    _highlightLevel = unlocked;
  }

  Future<void> refreshAfterLevelComplete() async {
    await _reloadFromRegistry();
    notifyListeners();
  }

  bool isUnlocked(int levelNumber) {
    final currentProgress = _progress;
    if (currentProgress == null) return false;
    return levelNumber <= currentProgress.unlockedLevel;
  }

  bool isCompleted(int levelNumber) {
    final currentProgress = _progress;
    if (currentProgress == null) return false;
    return currentProgress.completedLevels.contains(levelNumber);
  }

  int starsFor(int levelNumber) {
    final currentProgress = _progress;
    if (currentProgress == null) return 0;
    return currentProgress.starsByLevel[levelNumber] ?? 0;
  }

  @override
  void dispose() {
    _bundleUpdatesSub?.cancel();
    super.dispose();
  }
}