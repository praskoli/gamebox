import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../domain/sort_level.dart';
import '../domain/sort_puzzle_variant.dart';
import 'sort_puzzle_pack.dart';

class AssetSortPuzzleRepository {
  AssetSortPuzzleRepository._();

  static final AssetSortPuzzleRepository instance = AssetSortPuzzleRepository._();

  static const Map<SortPuzzleVariant, String> _assets = <SortPuzzleVariant, String>{
    SortPuzzleVariant.color: 'assets/gamepacks/sort_puzzle/color_sort_pack.json',
    SortPuzzleVariant.ball: 'assets/gamepacks/sort_puzzle/ball_sort_pack.json',
    SortPuzzleVariant.bird: 'assets/gamepacks/sort_puzzle/bird_sort_pack.json',
    SortPuzzleVariant.water: 'assets/gamepacks/sort_puzzle/water_sort_pack.json',
    SortPuzzleVariant.sand: 'assets/gamepacks/sort_puzzle/sand_sort_pack.json',
  };

  final Map<SortPuzzleVariant, SortPuzzlePack> _cache = <SortPuzzleVariant, SortPuzzlePack>{};

  Future<SortPuzzlePack> loadPack(SortPuzzleVariant variant) async {
    final SortPuzzlePack? cached = _cache[variant];
    if (cached != null) {
      return cached;
    }
    final String raw = await rootBundle.loadString(_assets[variant]!);
    final SortPuzzlePack pack = SortPuzzlePack.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    _cache[variant] = pack;
    return pack;
  }

  Future<List<SortLevel>> loadLevels(SortPuzzleVariant variant) async {
    final SortPuzzlePack pack = await loadPack(variant);
    return pack.levels;
  }
}
