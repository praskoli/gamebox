import 'package:shared_preferences/shared_preferences.dart';

import '../domain/sort_puzzle_variant.dart';

class SortPuzzleProgressService {
  SortPuzzleProgressService._();

  static final SortPuzzleProgressService instance =
  SortPuzzleProgressService._();

  Future<int> getUnlockedStep(
      SortPuzzleVariant variant,
      String modeKey,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_stepKey(variant, modeKey)) ?? 1;
  }

  Future<void> unlockStepIfHigher(
      SortPuzzleVariant variant,
      String modeKey,
      int step,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_stepKey(variant, modeKey)) ?? 1;
    if (step > current) {
      await prefs.setInt(_stepKey(variant, modeKey), step);
    }
  }

  Future<void> saveStars(
      SortPuzzleVariant variant,
      String modeKey,
      int levelNumber,
      int stars,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _starsKey(variant, modeKey, levelNumber);
    final current = prefs.getInt(key) ?? 0;
    if (stars > current) {
      await prefs.setInt(key, stars);
    }
  }

  Future<int> getStars(
      SortPuzzleVariant variant,
      String modeKey,
      int levelNumber,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_starsKey(variant, modeKey, levelNumber)) ?? 0;
  }

  String _stepKey(SortPuzzleVariant variant, String modeKey) =>
      'sort_${variant.name}_${modeKey}_unlocked_step';

  String _starsKey(
      SortPuzzleVariant variant,
      String modeKey,
      int levelNumber,
      ) =>
      'sort_${variant.name}_${modeKey}_stars_$levelNumber';
}