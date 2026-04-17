import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/sort_level.dart';
import '../domain/sort_puzzle_variant.dart';
import 'sort_level_policy.dart';
import 'sort_puzzle_pack.dart';

class AssetSortPuzzleRepository {
  AssetSortPuzzleRepository._();

  static final AssetSortPuzzleRepository instance =
  AssetSortPuzzleRepository._();

  static const Map<SortPuzzleVariant, String> _assets =
  <SortPuzzleVariant, String>{
    SortPuzzleVariant.color:
    'assets/gamepacks/sort_puzzle/color_sort_pack.json',
    SortPuzzleVariant.ball: 'assets/gamepacks/sort_puzzle/ball_sort_pack.json',
    SortPuzzleVariant.bird: 'assets/gamepacks/sort_puzzle/bird_sort_pack.json',
    SortPuzzleVariant.water:
    'assets/gamepacks/sort_puzzle/water_sort_pack.json',
    SortPuzzleVariant.sand: 'assets/gamepacks/sort_puzzle/sand_sort_pack.json',
  };

  static const Map<String, String> _colorModeAssets = <String, String>{
    'classic_journey':
    'assets/gamepacks/sort_puzzle/color_classic_journey_pack.json',
    'move_challenge':
    'assets/gamepacks/sort_puzzle/color_move_challenge_pack.json',
    'time_challenge':
    'assets/gamepacks/sort_puzzle/color_time_challenge_pack.json',
    'theme_worlds':
    'assets/gamepacks/sort_puzzle/color_theme_worlds_pack.json',
  };

  final Map<String, SortPuzzlePack> _cache = <String, SortPuzzlePack>{};

  String _cacheKey(SortPuzzleVariant variant, String? modeKey) {
    return '${variant.name}::${modeKey ?? 'all'}';
  }

  String _assetPathFor(SortPuzzleVariant variant, {String? modeKey}) {
    if (variant == SortPuzzleVariant.color && modeKey != null) {
      final String? modeAsset = _colorModeAssets[modeKey];
      if (modeAsset != null) {
        return modeAsset;
      }
    }
    return _assets[variant]!;
  }

  Future<SortPuzzlePack> loadPack(
      SortPuzzleVariant variant, {
        String? modeKey,
      }) async {
    final String cacheKey = _cacheKey(variant, modeKey);
    final SortPuzzlePack? cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final String assetPath = _assetPathFor(variant, modeKey: modeKey);
    final String raw = await rootBundle.loadString(assetPath);
    final SortPuzzlePack pack =
    SortPuzzlePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    _cache[cacheKey] = pack;
    return pack;
  }

  Future<List<SortLevel>> loadLevels(SortPuzzleVariant variant) async {
    final SortPuzzlePack pack = await loadPack(variant);
    return _sortOnly(pack.levels);
  }

  Future<List<SortLevel>> loadLevelsForMode(
      SortPuzzleVariant variant,
      String modeKey, {
        bool strict = false,
      }) async {
    // For Color Sort, load the world-specific file directly.
    if (variant == SortPuzzleVariant.color &&
        _colorModeAssets.containsKey(modeKey)) {
      final SortPuzzlePack pack = await loadPack(variant, modeKey: modeKey);
      final List<SortLevel> levels = _sortOnly(pack.levels);

      if (strict) {
        final List<String> issues = SortLevelPolicy.instance
            .validateCollectionForMode(
          levels,
          modeKey,
          requireTargetCount: false,
        );
        if (issues.isNotEmpty) {
          throw StateError(
            'Policy validation failed for $modeKey:\n${issues.join('\n')}',
          );
        }
      }

      return levels;
    }

    // Fallback for older combined-pack flow or other variants.
    final List<SortLevel> all = await loadLevels(variant);
    final List<SortLevel> filtered = filterLevelsForMode(all, modeKey);

    if (strict) {
      final List<String> issues = SortLevelPolicy.instance
          .validateCollectionForMode(
        filtered,
        modeKey,
        requireTargetCount: false,
      );
      if (issues.isNotEmpty) {
        throw StateError(
          'Policy validation failed for $modeKey:\n${issues.join('\n')}',
        );
      }
    }

    return filtered;
  }

  List<SortLevel> filterLevelsForMode(
      List<SortLevel> levels,
      String modeKey,
      ) {
    final Iterable<SortLevel> filtered = levels.where(
          (SortLevel level) =>
          SortLevelPolicy.instance.belongsToModeContract(level, modeKey),
    );

    return _sortOnly(filtered.toList(growable: false));
  }

  List<String> validateLevelsForMode(
      List<SortLevel> levels,
      String modeKey, {
        bool requireTargetCount = false,
      }) {
    return SortLevelPolicy.instance.validateCollectionForMode(
      levels,
      modeKey,
      requireTargetCount: requireTargetCount,
    );
  }

  List<SortLevel> _sortOnly(List<SortLevel> levels) {
    final List<SortLevel> sorted = List<SortLevel>.from(levels)
      ..sort((a, b) {
        final int modeCompare =
        (a.officialModeKey ?? '').compareTo(b.officialModeKey ?? '');
        if (modeCompare != 0) return modeCompare;
        return a.levelNumber.compareTo(b.levelNumber);
      });

    return sorted;
  }

  void clearCache() {
    _cache.clear();
  }
}