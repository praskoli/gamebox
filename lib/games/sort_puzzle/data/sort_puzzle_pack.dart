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
    final SortPuzzleVariant variant = SortPuzzleVariant.values.firstWhere(
      (SortPuzzleVariant item) => item.name == json['variant'],
    );
    final List<dynamic> rawLevels = json['levels'] as List<dynamic>? ?? const <dynamic>[];
    return SortPuzzlePack(
      id: json['id'] as String,
      title: json['title'] as String,
      variant: variant,
      levels: rawLevels
          .map((dynamic item) => SortLevel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}
