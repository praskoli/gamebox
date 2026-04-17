import '../domain/sort_level.dart';
import '../domain/sort_puzzle_variant.dart';

class SortPuzzlePack {
  const SortPuzzlePack({
    required this.id,
    required this.title,
    required this.variant,
    required this.levels,
  });

  final String id;
  final String title;
  final SortPuzzleVariant variant;
  final List<SortLevel> levels;

  factory SortPuzzlePack.fromJson(Map<String, dynamic> json) {
    final String variantName = (json['variant'] as String?) ?? 'color';
    final SortPuzzleVariant variant = SortPuzzleVariant.values.firstWhere(
          (SortPuzzleVariant item) => item.name == variantName,
      orElse: () => SortPuzzleVariant.color,
    );

    final String? worldKey = json['world'] as String?;
    final List<dynamic> rawLevels =
        json['levels'] as List<dynamic>? ?? const <dynamic>[];

    final List<SortLevel> levels = rawLevels.map((dynamic item) {
      final Map<String, dynamic> levelJson =
      Map<String, dynamic>.from(item as Map);

      final int levelNumber = (levelJson['levelNumber'] as num?)?.toInt() ?? 1;
      final String resolvedWorldKey =
          (levelJson['officialModeKey'] as String?) ??
              (levelJson['world'] as String?) ??
              worldKey ??
              'classic_journey';

      levelJson.putIfAbsent('variant', () => variant.name);
      levelJson.putIfAbsent(
        'id',
            () => '${variant.name}_$resolvedWorldKey\_$levelNumber',
      );
      levelJson.putIfAbsent('title', () => 'Level $levelNumber');
      levelJson.putIfAbsent('officialModeKey', () => resolvedWorldKey);

      return SortLevel.fromJson(levelJson);
    }).toList(growable: false);

    final String packId =
        (json['id'] as String?) ??
            '${variant.name}_${worldKey ?? 'official_pack'}';
    final String packTitle =
        (json['title'] as String?) ??
            _defaultPackTitle(variant, worldKey);

    return SortPuzzlePack(
      id: packId,
      title: packTitle,
      variant: variant,
      levels: levels,
    );
  }

  static String _defaultPackTitle(
      SortPuzzleVariant variant,
      String? worldKey,
      ) {
    switch (worldKey) {
      case 'classic_journey':
        return '${variant.title} · Classic Journey';
      case 'move_challenge':
        return '${variant.title} · Move Challenge';
      case 'time_challenge':
        return '${variant.title} · Time Challenge';
      default:
        return '${variant.title} · Official Pack';
    }
  }
}