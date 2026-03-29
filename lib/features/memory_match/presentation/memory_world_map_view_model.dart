import 'package:flutter/material.dart';

import '../data/memory_progress_repository.dart';
import '../data/memory_world_registry.dart';
import '../domain/memory_level.dart';
import '../domain/memory_progress.dart';
import '../domain/memory_theme_pack.dart';

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
      _theme = MemoryWorldRegistry.byWorldId(worldId);
      _progress = await MemoryProgressRepository.instance.getProgress(worldId);

      final unlocked = _progress?.unlockedLevel ?? 1;

      _windowStart = 1;
      _levels = MemoryWorldRegistry.generateLevelWindow(
        worldId: worldId,
        startLevel: _windowStart,
        count: _windowCount,
      );

      _highlightLevel = unlocked;
    } catch (e) {
      _error = 'Failed to load memory world: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAfterLevelComplete() async {
    _progress = await MemoryProgressRepository.instance.getProgress(worldId);
    final unlocked = _progress?.unlockedLevel ?? 1;

    _windowStart = 1;
    _levels = MemoryWorldRegistry.generateLevelWindow(
      worldId: worldId,
      startLevel: _windowStart,
      count: _windowCount,
    );

    _highlightLevel = unlocked;
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
}