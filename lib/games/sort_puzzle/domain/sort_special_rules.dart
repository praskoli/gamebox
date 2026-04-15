class SortSpecialRules {
  const SortSpecialRules({
    this.moveLimit,
    this.timeLimitSeconds,
    this.gravityReversed = false,
    this.enableWildcardBlocks = false,
    this.enableMultiColorBlocks = false,
    this.enableAdaptiveDifficulty = false,
    this.worldKey,
    this.storyKey,
    this.bonusObjective,
  });

  final int? moveLimit;
  final int? timeLimitSeconds;
  final bool gravityReversed;
  final bool enableWildcardBlocks;
  final bool enableMultiColorBlocks;
  final bool enableAdaptiveDifficulty;
  final String? worldKey;
  final String? storyKey;
  final String? bonusObjective;

  bool get hasMoveLimit => moveLimit != null && moveLimit! > 0;
  bool get hasTimeLimit => timeLimitSeconds != null && timeLimitSeconds! > 0;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (moveLimit != null) 'moveLimit': moveLimit,
    if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
    'gravityReversed': gravityReversed,
    'enableWildcardBlocks': enableWildcardBlocks,
    'enableMultiColorBlocks': enableMultiColorBlocks,
    'enableAdaptiveDifficulty': enableAdaptiveDifficulty,
    if (worldKey != null) 'worldKey': worldKey,
    if (storyKey != null) 'storyKey': storyKey,
    if (bonusObjective != null) 'bonusObjective': bonusObjective,
  };

  factory SortSpecialRules.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SortSpecialRules();
    }

    return SortSpecialRules(
      moveLimit: (json['moveLimit'] as num?)?.toInt(),
      timeLimitSeconds: (json['timeLimitSeconds'] as num?)?.toInt(),
      gravityReversed: json['gravityReversed'] as bool? ?? false,
      enableWildcardBlocks: json['enableWildcardBlocks'] as bool? ?? false,
      enableMultiColorBlocks: json['enableMultiColorBlocks'] as bool? ?? false,
      enableAdaptiveDifficulty: json['enableAdaptiveDifficulty'] as bool? ?? false,
      worldKey: json['worldKey'] as String?,
      storyKey: json['storyKey'] as String?,
      bonusObjective: json['bonusObjective'] as String?,
    );
  }

  SortSpecialRules copyWith({
    int? moveLimit,
    int? timeLimitSeconds,
    bool? gravityReversed,
    bool? enableWildcardBlocks,
    bool? enableMultiColorBlocks,
    bool? enableAdaptiveDifficulty,
    String? worldKey,
    String? storyKey,
    String? bonusObjective,
  }) {
    return SortSpecialRules(
      moveLimit: moveLimit ?? this.moveLimit,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      gravityReversed: gravityReversed ?? this.gravityReversed,
      enableWildcardBlocks: enableWildcardBlocks ?? this.enableWildcardBlocks,
      enableMultiColorBlocks: enableMultiColorBlocks ?? this.enableMultiColorBlocks,
      enableAdaptiveDifficulty: enableAdaptiveDifficulty ?? this.enableAdaptiveDifficulty,
      worldKey: worldKey ?? this.worldKey,
      storyKey: storyKey ?? this.storyKey,
      bonusObjective: bonusObjective ?? this.bonusObjective,
    );
  }
}