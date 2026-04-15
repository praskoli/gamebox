import 'sort_container_rules.dart';
import 'sort_piece.dart';
import 'sort_puzzle_variant.dart';
import 'sort_rule_family.dart';
import 'sort_special_rules.dart';
import 'sort_theme_config.dart';

class SortContainerDefinition {
  const SortContainerDefinition({
    required this.id,
    required this.capacity,
    required this.pieces,
    this.rules = const SortContainerRules(),
  });

  final String id;
  final int capacity;
  final List<SortPiece> pieces;
  final SortContainerRules rules;

  factory SortContainerDefinition.fromJson(
      Map<String, dynamic> json,
      int fallbackCapacity,
      ) {
    final List<dynamic> rawPieces =
    (json['pieces'] as List<dynamic>? ?? const <dynamic>[]);

    return SortContainerDefinition(
      id: (json['id'] as String?) ?? 'c_${DateTime.now().microsecondsSinceEpoch}',
      capacity: (json['capacity'] as num?)?.toInt() ?? fallbackCapacity,
      pieces: rawPieces
          .map(
            (dynamic item) => SortPiece.fromJson(
          Map<String, dynamic>.from(item as Map),
        ),
      )
          .toList(growable: false),
      rules: SortContainerRules.fromJson(
        json['rules'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'capacity': capacity,
    'pieces': pieces.map((e) => e.toJson()).toList(growable: false),
    'rules': rules.toJson(),
  };
}

class SortLevel {
  const SortLevel({
    required this.id,
    required this.levelNumber,
    required this.variant,
    required this.ruleFamily,
    required this.title,
    required this.containers,
    required this.themeKey,
    required this.themeConfig,
    required this.specialRules,
    required this.star3Target,
    required this.star2Target,
    required this.star1Target,
    required this.allowUndo,
    required this.allowHints,
    this.hintText,
    this.difficulty = 'easy',
  });

  final String id;
  final int levelNumber;
  final SortPuzzleVariant variant;
  final SortRuleFamily ruleFamily;
  final String title;
  final List<SortContainerDefinition> containers;

  /// Kept for backward compatibility with older files/screens.
  final String themeKey;

  final SortThemeConfig themeConfig;
  final SortSpecialRules specialRules;

  final int star3Target;
  final int star2Target;
  final int star1Target;
  final bool allowUndo;
  final bool allowHints;
  final String? hintText;
  final String difficulty;

  int get containerCapacity => containers.isEmpty ? 4 : containers.first.capacity;

  factory SortLevel.fromJson(Map<String, dynamic> json) {
    final SortPuzzleVariant variant = SortPuzzleVariant.values.firstWhere(
          (SortPuzzleVariant item) => item.name == json['variant'],
    );

    final SortRuleFamily ruleFamily = SortRuleFamily.values.firstWhere(
          (SortRuleFamily item) => item.name == json['ruleFamily'],
      orElse: () => variant.isDiscrete
          ? SortRuleFamily.discreteStack
          : SortRuleFamily.flowSegment,
    );

    final int defaultCapacity = (json['containerCapacity'] as num?)?.toInt() ?? 4;
    final List<dynamic> rawContainers =
        json['containers'] as List<dynamic>? ?? const <dynamic>[];

    final String fallbackThemeKey =
        (json['themeKey'] as String?) ?? variant.name;

    return SortLevel(
      id: json['id'] as String,
      levelNumber: (json['levelNumber'] as num?)?.toInt() ?? 1,
      variant: variant,
      ruleFamily: ruleFamily,
      title:
      (json['title'] as String?) ?? 'Level ${(json['levelNumber'] as num?)?.toInt() ?? 1}',
      containers: rawContainers
          .map(
            (dynamic item) => SortContainerDefinition.fromJson(
          Map<String, dynamic>.from(item as Map),
          defaultCapacity,
        ),
      )
          .toList(growable: false),
      themeKey: fallbackThemeKey,
      themeConfig: SortThemeConfig.fromJson(
        json['themeConfig'] as Map<String, dynamic>?,
        fallbackThemeKey: fallbackThemeKey,
      ),
      specialRules: SortSpecialRules.fromJson(
        json['specialRules'] as Map<String, dynamic>?,
      ),
      star3Target: (json['star3Target'] as num?)?.toInt() ?? 16,
      star2Target: (json['star2Target'] as num?)?.toInt() ?? 22,
      star1Target: (json['star1Target'] as num?)?.toInt() ?? 30,
      allowUndo: json['allowUndo'] as bool? ?? true,
      allowHints: json['allowHints'] as bool? ?? true,
      hintText: json['hintText'] as String?,
      difficulty: (json['difficulty'] as String?) ?? 'easy',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'levelNumber': levelNumber,
    'variant': variant.name,
    'ruleFamily': ruleFamily.name,
    'title': title,
    'themeKey': themeKey,
    'themeConfig': themeConfig.toJson(),
    'specialRules': specialRules.toJson(),
    'star3Target': star3Target,
    'star2Target': star2Target,
    'star1Target': star1Target,
    'allowUndo': allowUndo,
    'allowHints': allowHints,
    'difficulty': difficulty,
    if (hintText != null) 'hintText': hintText,
    'containerCapacity': containerCapacity,
    'containers': containers.map((e) => e.toJson()).toList(growable: false),
  };
}