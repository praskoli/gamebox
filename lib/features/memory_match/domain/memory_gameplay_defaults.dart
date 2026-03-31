class MemoryGridRule {
  const MemoryGridRule({
    required this.startLevel,
    required this.endLevel,
    required this.columns,
    required this.rows,
  });

  final int startLevel;
  final int? endLevel;
  final int columns;
  final int rows;

  bool contains(int levelNumber) {
    if (levelNumber < startLevel) return false;
    if (endLevel == null) return true;
    return levelNumber <= endLevel!;
  }

  factory MemoryGridRule.fromMap(Map<String, dynamic> map) {
    return MemoryGridRule(
      startLevel: _toInt(map['startLevel'], fallback: 1),
      endLevel: map['endLevel'] == null
          ? null
          : _toInt(map['endLevel'], fallback: 1),
      columns: _toInt(map['columns'], fallback: 4),
      rows: _toInt(map['rows'], fallback: 4),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startLevel': startLevel,
      'endLevel': endLevel,
      'columns': columns,
      'rows': rows,
    };
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class MemoryPreviewRule {
  const MemoryPreviewRule({
    required this.startLevel,
    required this.endLevel,
    required this.previewSeconds,
  });

  final int startLevel;
  final int? endLevel;
  final double previewSeconds;

  bool contains(int levelNumber) {
    if (levelNumber < startLevel) return false;
    if (endLevel == null) return true;
    return levelNumber <= endLevel!;
  }

  factory MemoryPreviewRule.fromMap(Map<String, dynamic> map) {
    return MemoryPreviewRule(
      startLevel: _toInt(map['startLevel'], fallback: 1),
      endLevel: map['endLevel'] == null
          ? null
          : _toInt(map['endLevel'], fallback: 1),
      previewSeconds: _toDouble(map['previewSeconds'], fallback: 2.0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startLevel': startLevel,
      'endLevel': endLevel,
      'previewSeconds': previewSeconds,
    };
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _toDouble(dynamic value, {required double fallback}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class MemoryGameplayDefaults {
  const MemoryGameplayDefaults({
    required this.gridRules,
    required this.previewRules,
    required this.previewSecondsBase,
    required this.previewSecondsStepPerLevel,
    required this.previewSecondsMin,
    required this.flipBackMsBase,
    required this.flipBackMsStepPerLevel,
    required this.flipBackMsMin,
    required this.rewardCoinsBase,
    required this.rewardCoinsPerLevel,
    required this.rewardLevelEvery,
    required this.rewardLevelExtraCoins,
    required this.rewardLevelPreviewBonusSeconds,
    required this.speedLevelEvery,
    required this.speedLevelPreviewOverrideSeconds,
    required this.speedLevelExtraCoins,
    required this.memoryProEvery,
    required this.memoryProPreviewMaxSeconds,
    required this.memoryProExtraCoins,
  });

  final List<MemoryGridRule> gridRules;
  final List<MemoryPreviewRule> previewRules;

  final double previewSecondsBase;
  final double previewSecondsStepPerLevel;
  final double previewSecondsMin;

  final int flipBackMsBase;
  final int flipBackMsStepPerLevel;
  final int flipBackMsMin;

  final int rewardCoinsBase;
  final int rewardCoinsPerLevel;

  final int rewardLevelEvery;
  final int rewardLevelExtraCoins;
  final double rewardLevelPreviewBonusSeconds;

  final int speedLevelEvery;
  final double speedLevelPreviewOverrideSeconds;
  final int speedLevelExtraCoins;

  final int memoryProEvery;
  final double memoryProPreviewMaxSeconds;
  final int memoryProExtraCoins;

  factory MemoryGameplayDefaults.fromMap(Map<String, dynamic> map) {
    final List<MemoryGridRule> parsedGridRules =
    ((map['gridRules'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => MemoryGridRule.fromMap(
      Map<String, dynamic>.from(e as Map),
    ))
        .toList(growable: false);

    final List<MemoryGridRule> safeGridRules = parsedGridRules.isEmpty
        ? const <MemoryGridRule>[
      MemoryGridRule(startLevel: 1, endLevel: 10, columns: 4, rows: 4),
      MemoryGridRule(startLevel: 11, endLevel: 25, columns: 4, rows: 4),
      MemoryGridRule(startLevel: 26, endLevel: 30, columns: 5, rows: 4),
      MemoryGridRule(startLevel: 31, endLevel: null, columns: 8, rows: 8),
    ]
        : parsedGridRules;

    final List<MemoryPreviewRule> parsedPreviewRules =
    ((map['previewRules'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => MemoryPreviewRule.fromMap(
      Map<String, dynamic>.from(e as Map),
    ))
        .toList(growable: false);

    final List<MemoryPreviewRule> safePreviewRules = parsedPreviewRules.isEmpty
        ? const <MemoryPreviewRule>[
      MemoryPreviewRule(
        startLevel: 1,
        endLevel: 30,
        previewSeconds: 2.0,
      ),
      MemoryPreviewRule(
        startLevel: 31,
        endLevel: null,
        previewSeconds: 3.0,
      ),
    ]
        : parsedPreviewRules;

    return MemoryGameplayDefaults(
      gridRules: safeGridRules,
      previewRules: safePreviewRules,
      previewSecondsBase: _toDouble(map['previewSecondsBase'], fallback: 2.0),
      previewSecondsStepPerLevel:
      _toDouble(map['previewSecondsStepPerLevel'], fallback: 0.0),
      previewSecondsMin: _toDouble(map['previewSecondsMin'], fallback: 2.0),
      flipBackMsBase: _toInt(map['flipBackMsBase'], fallback: 800),
      flipBackMsStepPerLevel:
      _toInt(map['flipBackMsStepPerLevel'], fallback: 12),
      flipBackMsMin: _toInt(map['flipBackMsMin'], fallback: 450),
      rewardCoinsBase: _toInt(map['rewardCoinsBase'], fallback: 10),
      rewardCoinsPerLevel: _toInt(map['rewardCoinsPerLevel'], fallback: 3),
      rewardLevelEvery: _toInt(map['rewardLevelEvery'], fallback: 0),
      rewardLevelExtraCoins:
      _toInt(map['rewardLevelExtraCoins'], fallback: 0),
      rewardLevelPreviewBonusSeconds:
      _toDouble(map['rewardLevelPreviewBonusSeconds'], fallback: 0.0),
      speedLevelEvery: _toInt(map['speedLevelEvery'], fallback: 0),
      speedLevelPreviewOverrideSeconds:
      _toDouble(map['speedLevelPreviewOverrideSeconds'], fallback: 0.0),
      speedLevelExtraCoins: _toInt(map['speedLevelExtraCoins'], fallback: 0),
      memoryProEvery: _toInt(map['memoryProEvery'], fallback: 0),
      memoryProPreviewMaxSeconds:
      _toDouble(map['memoryProPreviewMaxSeconds'], fallback: 0.0),
      memoryProExtraCoins: _toInt(map['memoryProExtraCoins'], fallback: 0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'gridRules': gridRules.map((e) => e.toMap()).toList(),
      'previewRules': previewRules.map((e) => e.toMap()).toList(),
      'previewSecondsBase': previewSecondsBase,
      'previewSecondsStepPerLevel': previewSecondsStepPerLevel,
      'previewSecondsMin': previewSecondsMin,
      'flipBackMsBase': flipBackMsBase,
      'flipBackMsStepPerLevel': flipBackMsStepPerLevel,
      'flipBackMsMin': flipBackMsMin,
      'rewardCoinsBase': rewardCoinsBase,
      'rewardCoinsPerLevel': rewardCoinsPerLevel,
      'rewardLevelEvery': rewardLevelEvery,
      'rewardLevelExtraCoins': rewardLevelExtraCoins,
      'rewardLevelPreviewBonusSeconds': rewardLevelPreviewBonusSeconds,
      'speedLevelEvery': speedLevelEvery,
      'speedLevelPreviewOverrideSeconds': speedLevelPreviewOverrideSeconds,
      'speedLevelExtraCoins': speedLevelExtraCoins,
      'memoryProEvery': memoryProEvery,
      'memoryProPreviewMaxSeconds': memoryProPreviewMaxSeconds,
      'memoryProExtraCoins': memoryProExtraCoins,
    };
  }

  bool isRewardLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    if (rewardLevelEvery <= 0) return false;
    return safeLevel % rewardLevelEvery == 0;
  }

  bool isSpeedLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    if (speedLevelEvery <= 0) return false;
    return safeLevel % speedLevelEvery == 0;
  }

  bool isMemoryProLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    if (memoryProEvery <= 0) return false;
    return safeLevel % memoryProEvery == 0;
  }

  ({int columns, int rows}) gridForLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;

    for (final rule in gridRules) {
      if (rule.contains(safeLevel)) {
        final int safeColumns = rule.columns < 2 ? 2 : rule.columns;
        final int safeRows = rule.rows < 2 ? 2 : rule.rows;

        int columns = safeColumns;
        int rows = safeRows;
        if ((columns * rows).isOdd) {
          if (columns > 2) {
            columns -= 1;
          } else {
            rows += 1;
          }
        }

        return (columns: columns, rows: rows);
      }
    }

    return (columns: 4, rows: 4);
  }

  int previewDurationMsForLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;

    for (final rule in previewRules) {
      if (rule.contains(safeLevel)) {
        double seconds = rule.previewSeconds;
        if (seconds < 0) seconds = 0;
        return (seconds * 1000).round();
      }
    }

    double seconds =
        previewSecondsBase - ((safeLevel - 1) * previewSecondsStepPerLevel);

    if (seconds < previewSecondsMin) {
      seconds = previewSecondsMin;
    }

    if (isRewardLevel(safeLevel)) {
      seconds += rewardLevelPreviewBonusSeconds;
    }

    if (isSpeedLevel(safeLevel)) {
      seconds = speedLevelPreviewOverrideSeconds;
    }

    if (isMemoryProLevel(safeLevel) &&
        memoryProPreviewMaxSeconds > 0 &&
        seconds > memoryProPreviewMaxSeconds) {
      seconds = memoryProPreviewMaxSeconds;
    }

    if (seconds < 0) {
      seconds = 0;
    }

    return (seconds * 1000).round();
  }

  int flipBackDelayMsForLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    final int raw = flipBackMsBase - ((safeLevel - 1) * flipBackMsStepPerLevel);
    final int safeMin = flipBackMsMin < 100 ? 100 : flipBackMsMin;
    return raw < safeMin ? safeMin : raw;
  }

  int rewardCoinsForLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    int coins = rewardCoinsBase + (safeLevel * rewardCoinsPerLevel);

    if (isRewardLevel(safeLevel)) {
      coins += rewardLevelExtraCoins;
    }
    if (isSpeedLevel(safeLevel)) {
      coins += speedLevelExtraCoins;
    }
    if (isMemoryProLevel(safeLevel)) {
      coins += memoryProExtraCoins;
    }

    return coins < 0 ? 0 : coins;
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _toDouble(dynamic value, {required double fallback}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}