import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/sort_container_rules.dart';
import '../../domain/sort_level.dart';
import '../../domain/sort_piece.dart';
import '../../domain/sort_puzzle_variant.dart';
import '../../domain/sort_rule_family.dart';
import '../../domain/sort_special_rules.dart';
import '../../domain/sort_theme_config.dart';

class SortPuzzleCreatorDraft {
  const SortPuzzleCreatorDraft({
    required this.id,
    required this.title,
    required this.variant,
    this.levelNumber = 1,
    this.containers = const <CreatorContainerDraft>[],
    this.capacity = 4,
    this.themeKey,
    this.difficulty = 'easy',
    this.allowUndo = true,
    this.allowHints = true,
    this.star3Target = 12,
    this.star2Target = 18,
    this.star1Target = 26,
    this.backgroundKey,
    this.containerSkinKey,
    this.pieceSkinKey,
    this.soundPackKey = 'default_sort',
    this.accentColorKey,
    this.moveLimit,
    this.timeLimitSeconds,
    this.gravityReversed = false,
    this.enableWildcardBlocks = false,
    this.enableMultiColorBlocks = false,
    this.enableAdaptiveDifficulty = false,
    this.worldKey,
    this.storyKey,
    this.bonusObjective,
    this.ownerUid = '',
    this.creatorName = 'Arena Builder',
    this.status = 'draft',
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy = '',
    this.rejectionReason = '',
    this.createdAt,
    this.updatedAt,
    this.communityVisible = false,
    this.approvedAt,
  });

  final String id;
  final String title;
  final SortPuzzleVariant variant;
  final int levelNumber;
  final int capacity;
  final List<CreatorContainerDraft> containers;
  final String? themeKey;
  final String difficulty;
  final bool allowUndo;
  final bool allowHints;
  final int star3Target;
  final int star2Target;
  final int star1Target;

  final String? backgroundKey;
  final String? containerSkinKey;
  final String? pieceSkinKey;
  final String soundPackKey;
  final String? accentColorKey;

  final int? moveLimit;
  final int? timeLimitSeconds;
  final bool gravityReversed;
  final bool enableWildcardBlocks;
  final bool enableMultiColorBlocks;
  final bool enableAdaptiveDifficulty;
  final String? worldKey;
  final String? storyKey;
  final String? bonusObjective;

  final String ownerUid;
  final String creatorName;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String reviewedBy;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool communityVisible;
  final DateTime? approvedAt;

  bool get isDraft => status == 'draft';
  bool get isPendingReview => status == 'pending_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  SortRuleFamily get ruleFamily =>
      variant.isDiscrete ? SortRuleFamily.discreteStack : SortRuleFamily.flowSegment;

  String get resolvedThemeKey => themeKey ?? variant.name;

  SortPuzzleCreatorDraft copyWith({
    String? id,
    String? title,
    SortPuzzleVariant? variant,
    int? levelNumber,
    List<CreatorContainerDraft>? containers,
    int? capacity,
    String? themeKey,
    String? difficulty,
    bool? allowUndo,
    bool? allowHints,
    int? star3Target,
    int? star2Target,
    int? star1Target,
    String? backgroundKey,
    String? containerSkinKey,
    String? pieceSkinKey,
    String? soundPackKey,
    String? accentColorKey,
    int? moveLimit,
    int? timeLimitSeconds,
    bool? gravityReversed,
    bool? enableWildcardBlocks,
    bool? enableMultiColorBlocks,
    bool? enableAdaptiveDifficulty,
    String? worldKey,
    String? storyKey,
    String? bonusObjective,
    String? ownerUid,
    String? creatorName,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? communityVisible,
    DateTime? approvedAt,
  }) {
    return SortPuzzleCreatorDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      variant: variant ?? this.variant,
      levelNumber: levelNumber ?? this.levelNumber,
      containers: containers ?? this.containers,
      capacity: capacity ?? this.capacity,
      themeKey: themeKey ?? this.themeKey,
      difficulty: difficulty ?? this.difficulty,
      allowUndo: allowUndo ?? this.allowUndo,
      allowHints: allowHints ?? this.allowHints,
      star3Target: star3Target ?? this.star3Target,
      star2Target: star2Target ?? this.star2Target,
      star1Target: star1Target ?? this.star1Target,
      backgroundKey: backgroundKey ?? this.backgroundKey,
      containerSkinKey: containerSkinKey ?? this.containerSkinKey,
      pieceSkinKey: pieceSkinKey ?? this.pieceSkinKey,
      soundPackKey: soundPackKey ?? this.soundPackKey,
      accentColorKey: accentColorKey ?? this.accentColorKey,
      moveLimit: moveLimit ?? this.moveLimit,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      gravityReversed: gravityReversed ?? this.gravityReversed,
      enableWildcardBlocks: enableWildcardBlocks ?? this.enableWildcardBlocks,
      enableMultiColorBlocks:
      enableMultiColorBlocks ?? this.enableMultiColorBlocks,
      enableAdaptiveDifficulty:
      enableAdaptiveDifficulty ?? this.enableAdaptiveDifficulty,
      worldKey: worldKey ?? this.worldKey,
      storyKey: storyKey ?? this.storyKey,
      bonusObjective: bonusObjective ?? this.bonusObjective,
      ownerUid: ownerUid ?? this.ownerUid,
      creatorName: creatorName ?? this.creatorName,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      communityVisible: communityVisible ?? this.communityVisible,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  SortLevel toSortLevel() {
    return SortLevel(
      id: id,
      levelNumber: levelNumber,
      variant: variant,
      ruleFamily: ruleFamily,
      title: title,
      containers: _resolvedContainers(),
      themeKey: resolvedThemeKey,
      themeConfig: SortThemeConfig(
        themeKey: resolvedThemeKey,
        backgroundKey: backgroundKey ?? resolvedThemeKey,
        containerSkinKey: containerSkinKey ?? _defaultContainerSkinFor(variant),
        pieceSkinKey: pieceSkinKey ?? _defaultPieceSkinFor(variant),
        soundPackKey: soundPackKey,
        accentColorKey: accentColorKey,
      ),
      specialRules: SortSpecialRules(
        moveLimit: moveLimit,
        timeLimitSeconds: timeLimitSeconds,
        gravityReversed: gravityReversed,
        enableWildcardBlocks: enableWildcardBlocks,
        enableMultiColorBlocks: enableMultiColorBlocks,
        enableAdaptiveDifficulty: enableAdaptiveDifficulty,
        worldKey: worldKey,
        storyKey: storyKey,
        bonusObjective: bonusObjective,
      ),
      star3Target: star3Target,
      star2Target: star2Target,
      star1Target: star1Target,
      allowUndo: allowUndo,
      allowHints: allowHints,
      difficulty: difficulty,
    );
  }

  SortLevel toLevel({int? levelNumber}) {
    final SortLevel base = toSortLevel();
    if (levelNumber == null || levelNumber == base.levelNumber) {
      return base;
    }

    return SortLevel(
      id: base.id,
      levelNumber: levelNumber,
      variant: base.variant,
      ruleFamily: base.ruleFamily,
      title: base.title,
      containers: base.containers,
      themeKey: base.themeKey,
      themeConfig: base.themeConfig,
      specialRules: base.specialRules,
      star3Target: base.star3Target,
      star2Target: base.star2Target,
      star1Target: base.star1Target,
      allowUndo: base.allowUndo,
      allowHints: base.allowHints,
      hintText: base.hintText,
      difficulty: base.difficulty,
    );
  }

  List<SortContainerDefinition> _resolvedContainers() {
    return containers.map((e) => e.toLevelDefinition()).toList(growable: false);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'variant': variant.name,
    'gameType': 'sort_puzzle',
    'levelNumber': levelNumber,
    'capacity': capacity,
    'themeKey': themeKey,
    'difficulty': difficulty,
    'allowUndo': allowUndo,
    'allowHints': allowHints,
    'star3Target': star3Target,
    'star2Target': star2Target,
    'star1Target': star1Target,
    'backgroundKey': backgroundKey,
    'containerSkinKey': containerSkinKey,
    'pieceSkinKey': pieceSkinKey,
    'soundPackKey': soundPackKey,
    'accentColorKey': accentColorKey,
    'moveLimit': moveLimit,
    'timeLimitSeconds': timeLimitSeconds,
    'gravityReversed': gravityReversed,
    'enableWildcardBlocks': enableWildcardBlocks,
    'enableMultiColorBlocks': enableMultiColorBlocks,
    'enableAdaptiveDifficulty': enableAdaptiveDifficulty,
    'worldKey': worldKey,
    'storyKey': storyKey,
    'bonusObjective': bonusObjective,
    'ownerUid': ownerUid,
    'creatorName': creatorName,
    'status': status,
    'submittedAt': submittedAt?.toIso8601String(),
    'reviewedAt': reviewedAt?.toIso8601String(),
    'reviewedBy': reviewedBy,
    'rejectionReason': rejectionReason,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'communityVisible': communityVisible,
    'approvedAt': approvedAt?.toIso8601String(),
    'containers': containers.map((e) => e.toJson()).toList(growable: false),
  };

  factory SortPuzzleCreatorDraft.fromJson(Map<String, dynamic> json) {
    final SortPuzzleVariant variant = SortPuzzleVariant.values.firstWhere(
          (e) => e.name == json['variant'],
    );

    final List<dynamic> rawContainers =
        json['containers'] as List<dynamic>? ?? const <dynamic>[];

    return SortPuzzleCreatorDraft(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? 'Untitled Sort Puzzle',
      variant: variant,
      levelNumber: (json['levelNumber'] as num?)?.toInt() ?? 1,
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      themeKey: json['themeKey'] as String?,
      difficulty: (json['difficulty'] as String?) ?? 'easy',
      allowUndo: json['allowUndo'] as bool? ?? true,
      allowHints: json['allowHints'] as bool? ?? true,
      star3Target: (json['star3Target'] as num?)?.toInt() ?? 12,
      star2Target: (json['star2Target'] as num?)?.toInt() ?? 18,
      star1Target: (json['star1Target'] as num?)?.toInt() ?? 26,
      backgroundKey: json['backgroundKey'] as String?,
      containerSkinKey: json['containerSkinKey'] as String?,
      pieceSkinKey: json['pieceSkinKey'] as String?,
      soundPackKey: (json['soundPackKey'] as String?) ?? 'default_sort',
      accentColorKey: json['accentColorKey'] as String?,
      moveLimit: (json['moveLimit'] as num?)?.toInt(),
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
      gravityReversed: json['gravityReversed'] as bool? ?? false,
      enableWildcardBlocks: json['enableWildcardBlocks'] as bool? ?? false,
      enableMultiColorBlocks: json['enableMultiColorBlocks'] as bool? ?? false,
      enableAdaptiveDifficulty:
      json['enableAdaptiveDifficulty'] as bool? ?? false,
      worldKey: json['worldKey'] as String?,
      storyKey: json['storyKey'] as String?,
      bonusObjective: json['bonusObjective'] as String?,
      ownerUid: (json['ownerUid'] as String?) ?? '',
      creatorName: (json['creatorName'] as String?) ?? 'Arena Builder',
      status: (json['status'] as String?) ?? 'draft',
      submittedAt: _parseDate(json['submittedAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
      reviewedBy: (json['reviewedBy'] as String?) ?? '',
      rejectionReason: (json['rejectionReason'] as String?) ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      communityVisible: json['communityVisible'] as bool? ?? false,
      approvedAt: _parseDate(json['approvedAt']),
      containers: rawContainers
          .map((dynamic item) => CreatorContainerDraft.fromJson(
        Map<String, dynamic>.from(item as Map),
      ))
          .toList(growable: false),
    );
  }

  factory SortPuzzleCreatorDraft.fromFirestore(
      Map<String, dynamic> json,
      String id,
      ) {
    final Map<String, dynamic> copy = Map<String, dynamic>.from(json);
    copy['id'] = id;
    return SortPuzzleCreatorDraft.fromJson(copy);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  static String _defaultContainerSkinFor(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return 'branch_classic';
      case SortPuzzleVariant.ball:
        return 'tube_neon';
      case SortPuzzleVariant.color:
        return 'tube_glass';
      case SortPuzzleVariant.water:
        return 'bottle_water';
      case SortPuzzleVariant.sand:
        return 'bottle_sand';
    }
  }

  static String _defaultPieceSkinFor(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return 'bird_cartoon';
      case SortPuzzleVariant.ball:
        return 'ball_glossy';
      case SortPuzzleVariant.color:
        return 'color_flat';
      case SortPuzzleVariant.water:
        return 'water_liquid';
      case SortPuzzleVariant.sand:
        return 'sand_texture';
    }
  }
}

class CreatorContainerDraft {
  const CreatorContainerDraft({
    required this.id,
    required this.capacity,
    required this.pieces,
    this.rules = const SortContainerRules(),
  });

  final String id;
  final int capacity;
  final List<SortPiece> pieces;
  final SortContainerRules rules;

  SortContainerDefinition toLevelDefinition() {
    return SortContainerDefinition(
      id: id,
      capacity: capacity,
      pieces: pieces,
      rules: rules,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'capacity': capacity,
    'pieces': pieces.map((e) => e.toJson()).toList(growable: false),
    'rules': rules.toJson(),
  };

  factory CreatorContainerDraft.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPieces =
        json['pieces'] as List<dynamic>? ?? const <dynamic>[];

    return CreatorContainerDraft(
      id: (json['id'] as String?) ?? 'c_${DateTime.now().microsecondsSinceEpoch}',
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      pieces: rawPieces
          .map((dynamic item) => SortPiece.fromJson(
        Map<String, dynamic>.from(item as Map),
      ))
          .toList(growable: false),
      rules: SortContainerRules.fromJson(
        json['rules'] as Map<String, dynamic>?,
      ),
    );
  }
}