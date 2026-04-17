import 'sort_challenge_family.dart';
import 'sort_container_rules.dart';
import 'sort_pattern_family.dart';
import 'sort_piece.dart';
import 'sort_puzzle_variant.dart';
import 'sort_rule_family.dart';
import 'sort_special_rules.dart';
import 'sort_theme_config.dart';
import 'sort_visual_family.dart';

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
        json['pieces'] as List<dynamic>? ?? const <dynamic>[];

    return SortContainerDefinition(
      id:
      (json['id'] as String?) ??
          'c_${DateTime.now().microsecondsSinceEpoch}',
      capacity: (json['capacity'] as num?)?.toInt() ?? fallbackCapacity,
      pieces: rawPieces
          .map(
            (dynamic item) =>
            SortPiece.fromJson(Map<String, dynamic>.from(item as Map)),
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

  int get pieceCount =>
      pieces.fold<int>(0, (sum, piece) => sum + piece.amount);

  Set<String> get groupKeys => pieces.map((piece) => piece.groupKey).toSet();

  bool get isEmpty => pieceCount == 0;

  bool isMixed(int capacity) {
    if (pieceCount == 0) return false;
    return groupKeys.length >= 2;
  }

  bool isSolved(int capacity) {
    if (pieceCount != capacity) return false;
    return groupKeys.length == 1;
  }
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
    this.officialModeKey,
    this.patternFamilyKey,
    this.challengeFamilyKey,
    this.visualFamilyKey,
  });

  final String id;
  final int levelNumber;
  final SortPuzzleVariant variant;
  final SortRuleFamily ruleFamily;
  final String title;
  final List<SortContainerDefinition> containers;

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

  final String? officialModeKey;
  final String? patternFamilyKey;
  final String? challengeFamilyKey;
  final String? visualFamilyKey;

  int get containerCapacity => containers.isEmpty ? 4 : containers.first.capacity;

  int get totalPieceCount =>
      containers.fold<int>(0, (sum, container) => sum + container.pieceCount);

  Map<String, int> get groupTotals {
    final Map<String, int> totals = <String, int>{};
    for (final SortContainerDefinition container in containers) {
      for (final SortPiece piece in container.pieces) {
        totals[piece.groupKey] = (totals[piece.groupKey] ?? 0) + piece.amount;
      }
    }
    return totals;
  }

  int get activeGroupCount => groupTotals.length;

  int get emptyContainerCount =>
      containers.where((container) => container.isEmpty).length;

  int get mixedContainerCount =>
      containers.where((container) => container.isMixed(containerCapacity)).length;

  int get solvedContainerCount =>
      containers.where((container) => container.isSolved(containerCapacity)).length;

  bool get hasMoveLimit => specialRules.moveLimit != null;
  bool get hasTimeLimit => specialRules.timeLimitSeconds != null;
  bool get hasWorldKey => (specialRules.worldKey ?? '').trim().isNotEmpty;

  SortPatternFamily? get patternFamily =>
      SortPatternFamilyX.fromKey(patternFamilyKey);

  SortChallengeFamily? get challengeFamily =>
      SortChallengeFamilyX.fromKey(challengeFamilyKey);

  SortVisualFamily? get visualFamily =>
      SortVisualFamilyX.fromKey(visualFamilyKey);

  factory SortLevel.fromJson(Map<String, dynamic> json) {
    final String variantName = (json['variant'] as String?) ?? 'color';
    final SortPuzzleVariant variant = SortPuzzleVariant.values.firstWhere(
          (SortPuzzleVariant item) => item.name == variantName,
      orElse: () => SortPuzzleVariant.color,
    );

    final String? worldKey =
        (json['officialModeKey'] as String?) ?? (json['world'] as String?);

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

    final Map<String, dynamic>? config =
    json['config'] as Map<String, dynamic>?;

    final Map<String, dynamic>? specialRulesJson =
        json['specialRules'] as Map<String, dynamic>? ??
            _specialRulesFromGeneratorJson(config, worldKey);

    final String? patternFamilyKey =
        json['patternFamilyKey'] as String? ??
            (config != null ? config['pattern'] as String? : null);

    final String? challengeFamilyKey =
        json['challengeFamilyKey'] as String? ??
            (config != null ? config['challenge'] as String? : null);

    final String? visualFamilyKey =
        json['visualFamilyKey'] as String? ??
            (config != null ? config['visualStyle'] as String? : null);

    final int levelNumber = (json['levelNumber'] as num?)?.toInt() ?? 1;

    return SortLevel(
      id: (json['id'] as String?) ??
          '${variant.name}_${worldKey ?? 'level'}_$levelNumber',
      levelNumber: levelNumber,
      variant: variant,
      ruleFamily: ruleFamily,
      title: (json['title'] as String?) ?? 'Level $levelNumber',
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
      specialRules: SortSpecialRules.fromJson(specialRulesJson),
      star3Target: (json['star3Target'] as num?)?.toInt() ?? 16,
      star2Target: (json['star2Target'] as num?)?.toInt() ?? 22,
      star1Target: (json['star1Target'] as num?)?.toInt() ?? 30,
      allowUndo: json['allowUndo'] as bool? ?? true,
      allowHints: json['allowHints'] as bool? ?? true,
      hintText: json['hintText'] as String?,
      difficulty: (json['difficulty'] as String?) ?? 'easy',
      officialModeKey: worldKey,
      patternFamilyKey: patternFamilyKey,
      challengeFamilyKey: challengeFamilyKey,
      visualFamilyKey: visualFamilyKey,
    );
  }

  static Map<String, dynamic>? _specialRulesFromGeneratorJson(
      Map<String, dynamic>? config,
      String? worldKey,
      ) {
    if (config == null && worldKey == null) {
      return null;
    }

    return <String, dynamic>{
      if ((config?['moveLimit'] as num?) != null)
        'moveLimit': (config!['moveLimit'] as num).toInt(),
      if ((config?['timeLimitSeconds'] as num?) != null)
        'timeLimitSeconds': (config!['timeLimitSeconds'] as num).toInt(),
      if ((worldKey ?? '').isNotEmpty) 'worldKey': worldKey,
    };
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
    if (officialModeKey != null) 'officialModeKey': officialModeKey,
    if (patternFamilyKey != null) 'patternFamilyKey': patternFamilyKey,
    if (challengeFamilyKey != null) 'challengeFamilyKey': challengeFamilyKey,
    if (visualFamilyKey != null) 'visualFamilyKey': visualFamilyKey,
    'containerCapacity': containerCapacity,
    'containers': containers.map((e) => e.toJson()).toList(growable: false),
  };
}