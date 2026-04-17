import '../domain/sort_challenge_family.dart';
import '../domain/sort_level.dart';
import '../domain/sort_official_mode.dart';
import '../domain/sort_pattern_family.dart';
import '../domain/sort_visual_family.dart';

class SortPolicyBand {
  const SortPolicyBand({
    required this.startLevel,
    required this.endLevel,
    required this.minColors,
    required this.maxColors,
    required this.minContainers,
    required this.maxContainers,
    required this.minEmptyContainers,
    required this.minMixedContainers,
    required this.maxSolvedContainersAtStart,
    required this.patternFamilies,
    required this.challengeFamilies,
    required this.visualFamilies,
    this.allowCapacityFive = false,
  });

  final int startLevel;
  final int endLevel;

  final int minColors;
  final int maxColors;

  final int minContainers;
  final int maxContainers;

  final int minEmptyContainers;
  final int minMixedContainers;
  final int maxSolvedContainersAtStart;

  final List<SortPatternFamily> patternFamilies;
  final List<SortChallengeFamily> challengeFamilies;
  final List<SortVisualFamily> visualFamilies;

  final bool allowCapacityFive;

  bool matches(int levelNumber) {
    return levelNumber >= startLevel && levelNumber <= endLevel;
  }
}

class SortModePolicy {
  const SortModePolicy({
    required this.mode,
    required this.targetOfficialLevels,
    required this.description,
    required this.requiresMoveLimit,
    required this.requiresTimeLimit,
    required this.requiresWorldKey,
    required this.bands,
  });

  final SortOfficialMode mode;
  final int targetOfficialLevels;
  final String description;

  final bool requiresMoveLimit;
  final bool requiresTimeLimit;
  final bool requiresWorldKey;

  final List<SortPolicyBand> bands;

  SortPolicyBand? bandForLevel(int levelNumber) {
    for (final SortPolicyBand band in bands) {
      if (band.matches(levelNumber)) {
        return band;
      }
    }
    return null;
  }

  String get key => mode.key;
  String get title => mode.title;
}

class SortLevelPolicy {
  SortLevelPolicy._();

  static final SortLevelPolicy instance = SortLevelPolicy._();

  static const List<SortPatternFamily> _earlyPatterns = <SortPatternFamily>[
    SortPatternFamily.zigzag,
    SortPatternFamily.staircase,
    SortPatternFamily.alternating,
    SortPatternFamily.offsetBlocks,
  ];

  static const List<SortPatternFamily> _midPatterns = <SortPatternFamily>[
    SortPatternFamily.crossMix,
    SortPatternFamily.clusterBreak,
    SortPatternFamily.mirrorBreak,
    SortPatternFamily.ladderMix,
    SortPatternFamily.splitBridge,
  ];

  static const List<SortPatternFamily> _latePatterns = <SortPatternFamily>[
    SortPatternFamily.centerHeavy,
    SortPatternFamily.edgeHeavy,
    SortPatternFamily.topTrap,
    SortPatternFamily.bottomTrap,
    SortPatternFamily.spiralShift,
    SortPatternFamily.funnel,
    SortPatternFamily.cornerPressure,
  ];

  static const List<SortChallengeFamily> _earlyChallenges = <SortChallengeFamily>[
    SortChallengeFamily.obviousStart,
    SortChallengeFamily.recoveryBoard,
    SortChallengeFamily.fakeEasy,
  ];

  static const List<SortChallengeFamily> _midChallenges = <SortChallengeFamily>[
    SortChallengeFamily.hiddenStart,
    SortChallengeFamily.competingPaths,
    SortChallengeFamily.sequencingBoard,
    SortChallengeFamily.symmetryBreak,
  ];

  static const List<SortChallengeFamily> _lateChallenges = <SortChallengeFamily>[
    SortChallengeFamily.topColorTrap,
    SortChallengeFamily.buriedColorTrap,
    SortChallengeFamily.competingPaths,
    SortChallengeFamily.pressureBoard,
    SortChallengeFamily.sequencingBoard,
  ];

  static const List<SortVisualFamily> _earlyVisuals = <SortVisualFamily>[
    SortVisualFamily.cleanOpen,
    SortVisualFamily.symmetricCalm,
    SortVisualFamily.centerFocus,
  ];

  static const List<SortVisualFamily> _midVisuals = <SortVisualFamily>[
    SortVisualFamily.asymmetricFlow,
    SortVisualFamily.alternatingRhythm,
    SortVisualFamily.edgeFocus,
  ];

  static const List<SortVisualFamily> _lateVisuals = <SortVisualFamily>[
    SortVisualFamily.compactDense,
    SortVisualFamily.fragmentedRhythm,
    SortVisualFamily.asymmetricFlow,
    SortVisualFamily.edgeFocus,
  ];

  static const SortModePolicy _classicJourney = SortModePolicy(
    mode: SortOfficialMode.classicJourney,
    targetOfficialLevels: 300,
    description:
    'Classic Journey is the main progression track. No move limit, no time limit, no world key.',
    requiresMoveLimit: false,
    requiresTimeLimit: false,
    requiresWorldKey: false,
    bands: <SortPolicyBand>[
      SortPolicyBand(
        startLevel: 1,
        endLevel: 75,
        minColors: 3,
        maxColors: 4,
        minContainers: 4,
        maxContainers: 6,
        minEmptyContainers: 1,
        minMixedContainers: 1,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _earlyPatterns,
        challengeFamilies: _earlyChallenges,
        visualFamilies: _earlyVisuals,
      ),
      SortPolicyBand(
        startLevel: 76,
        endLevel: 150,
        minColors: 4,
        maxColors: 5,
        minContainers: 5,
        maxContainers: 7,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _midPatterns,
        challengeFamilies: _midChallenges,
        visualFamilies: _midVisuals,
      ),
      SortPolicyBand(
        startLevel: 151,
        endLevel: 225,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 8,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _lateVisuals,
      ),
      SortPolicyBand(
        startLevel: 226,
        endLevel: 300,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 9,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _lateVisuals,
        allowCapacityFive: true,
      ),
    ],
  );

  static const SortModePolicy _moveChallenge = SortModePolicy(
    mode: SortOfficialMode.moveChallenge,
    targetOfficialLevels: 300,
    description:
    'Move Challenge requires moveLimit and should feel tighter and more deliberate.',
    requiresMoveLimit: true,
    requiresTimeLimit: false,
    requiresWorldKey: false,
    bands: <SortPolicyBand>[
      SortPolicyBand(
        startLevel: 1,
        endLevel: 75,
        minColors: 3,
        maxColors: 4,
        minContainers: 4,
        maxContainers: 6,
        minEmptyContainers: 1,
        minMixedContainers: 1,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _earlyPatterns,
        challengeFamilies: _midChallenges,
        visualFamilies: _earlyVisuals,
      ),
      SortPolicyBand(
        startLevel: 76,
        endLevel: 150,
        minColors: 4,
        maxColors: 5,
        minContainers: 5,
        maxContainers: 7,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _midPatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _midVisuals,
      ),
      SortPolicyBand(
        startLevel: 151,
        endLevel: 225,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 8,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _lateVisuals,
      ),
      SortPolicyBand(
        startLevel: 226,
        endLevel: 300,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 9,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _lateVisuals,
        allowCapacityFive: true,
      ),
    ],
  );

  static const SortModePolicy _timeChallenge = SortModePolicy(
    mode: SortOfficialMode.timeChallenge,
    targetOfficialLevels: 300,
    description:
    'Time Challenge requires timeLimitSeconds and should stay visually readable under pressure.',
    requiresMoveLimit: false,
    requiresTimeLimit: true,
    requiresWorldKey: false,
    bands: <SortPolicyBand>[
      SortPolicyBand(
        startLevel: 1,
        endLevel: 75,
        minColors: 3,
        maxColors: 4,
        minContainers: 4,
        maxContainers: 6,
        minEmptyContainers: 1,
        minMixedContainers: 1,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _earlyPatterns,
        challengeFamilies: _earlyChallenges,
        visualFamilies: _earlyVisuals,
      ),
      SortPolicyBand(
        startLevel: 76,
        endLevel: 150,
        minColors: 4,
        maxColors: 5,
        minContainers: 5,
        maxContainers: 7,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _midPatterns,
        challengeFamilies: _midChallenges,
        visualFamilies: _midVisuals,
      ),
      SortPolicyBand(
        startLevel: 151,
        endLevel: 225,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 8,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _midVisuals,
      ),
      SortPolicyBand(
        startLevel: 226,
        endLevel: 300,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 9,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _lateVisuals,
        allowCapacityFive: true,
      ),
    ],
  );

  static const SortModePolicy _themeWorlds = SortModePolicy(
    mode: SortOfficialMode.themeWorlds,
    targetOfficialLevels: 300,
    description:
    'Theme Worlds requires worldKey and should feel thematically distinct by layout rhythm and progression.',
    requiresMoveLimit: false,
    requiresTimeLimit: false,
    requiresWorldKey: true,
    bands: <SortPolicyBand>[
      SortPolicyBand(
        startLevel: 1,
        endLevel: 75,
        minColors: 3,
        maxColors: 4,
        minContainers: 4,
        maxContainers: 6,
        minEmptyContainers: 1,
        minMixedContainers: 1,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _earlyPatterns,
        challengeFamilies: _earlyChallenges,
        visualFamilies: _earlyVisuals,
      ),
      SortPolicyBand(
        startLevel: 76,
        endLevel: 150,
        minColors: 4,
        maxColors: 5,
        minContainers: 5,
        maxContainers: 7,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _midPatterns,
        challengeFamilies: _midChallenges,
        visualFamilies: _midVisuals,
      ),
      SortPolicyBand(
        startLevel: 151,
        endLevel: 225,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 8,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _lateVisuals,
      ),
      SortPolicyBand(
        startLevel: 226,
        endLevel: 300,
        minColors: 5,
        maxColors: 6,
        minContainers: 6,
        maxContainers: 9,
        minEmptyContainers: 1,
        minMixedContainers: 2,
        maxSolvedContainersAtStart: 1,
        patternFamilies: _latePatterns,
        challengeFamilies: _lateChallenges,
        visualFamilies: _lateVisuals,
        allowCapacityFive: true,
      ),
    ],
  );

  List<SortModePolicy> get allPolicies => const <SortModePolicy>[
    _classicJourney,
    _moveChallenge,
    _timeChallenge,
    _themeWorlds,
  ];

  SortModePolicy policyForModeKey(String modeKey) {
    final SortOfficialMode mode = SortOfficialModeX.fromKey(modeKey);
    switch (mode) {
      case SortOfficialMode.classicJourney:
        return _classicJourney;
      case SortOfficialMode.moveChallenge:
        return _moveChallenge;
      case SortOfficialMode.timeChallenge:
        return _timeChallenge;
      case SortOfficialMode.themeWorlds:
        return _themeWorlds;
    }
  }

  bool belongsToModeContract(SortLevel level, String modeKey) {
    final SortModePolicy policy = policyForModeKey(modeKey);

    final bool hasMoveLimit = level.hasMoveLimit;
    final bool hasTimeLimit = level.hasTimeLimit;
    final bool hasWorldKey = level.hasWorldKey;

    if (policy.requiresMoveLimit && !hasMoveLimit) return false;
    if (!policy.requiresMoveLimit && hasMoveLimit) return false;

    if (policy.requiresTimeLimit && !hasTimeLimit) return false;
    if (!policy.requiresTimeLimit && hasTimeLimit) return false;

    if (policy.requiresWorldKey && !hasWorldKey) return false;
    if (!policy.requiresWorldKey && hasWorldKey) return false;

    return true;
  }

  List<String> validateLevelForMode(
      SortLevel level,
      String modeKey,
      ) {
    final SortModePolicy policy = policyForModeKey(modeKey);
    final List<String> issues = <String>[];

    if (!belongsToModeContract(level, modeKey)) {
      issues.add(
        'Level ${level.levelNumber} does not match ${policy.title} world contract.',
      );
      return issues;
    }

    final SortPolicyBand? band = policy.bandForLevel(level.levelNumber);
    if (band == null) {
      issues.add(
        'Level ${level.levelNumber} is outside the supported policy range for ${policy.title}.',
      );
      return issues;
    }

    if (level.activeGroupCount < band.minColors ||
        level.activeGroupCount > band.maxColors) {
      issues.add(
        'Level ${level.levelNumber} has ${level.activeGroupCount} colors, expected ${band.minColors}-${band.maxColors}.',
      );
    }

    if (level.containers.length < band.minContainers ||
        level.containers.length > band.maxContainers) {
      issues.add(
        'Level ${level.levelNumber} has ${level.containers.length} containers, expected ${band.minContainers}-${band.maxContainers}.',
      );
    }

    if (level.emptyContainerCount < band.minEmptyContainers) {
      issues.add(
        'Level ${level.levelNumber} needs at least ${band.minEmptyContainers} empty container(s).',
      );
    }

    if (level.mixedContainerCount < band.minMixedContainers) {
      issues.add(
        'Level ${level.levelNumber} needs at least ${band.minMixedContainers} mixed container(s).',
      );
    }

    if (level.solvedContainerCount > band.maxSolvedContainersAtStart) {
      issues.add(
        'Level ${level.levelNumber} starts with too many solved containers (${level.solvedContainerCount}).',
      );
    }

    if (!band.allowCapacityFive && level.containerCapacity > 4) {
      issues.add(
        'Level ${level.levelNumber} uses capacity ${level.containerCapacity}, but this band allows only capacity 4.',
      );
    }

    for (final MapEntry<String, int> entry in level.groupTotals.entries) {
      if (entry.value != level.containerCapacity) {
        issues.add(
          'Level ${level.levelNumber} has invalid group total for ${entry.key}: ${entry.value}/${level.containerCapacity}.',
        );
      }
    }

    if (level.officialModeKey != null && level.officialModeKey != modeKey) {
      issues.add(
        'Level ${level.levelNumber} officialModeKey is "${level.officialModeKey}" but expected "$modeKey".',
      );
    }

    if (level.patternFamilyKey != null &&
        !band.patternFamilies.any((e) => e.key == level.patternFamilyKey)) {
      issues.add(
        'Level ${level.levelNumber} patternFamilyKey "${level.patternFamilyKey}" is not allowed in this band.',
      );
    }

    if (level.challengeFamilyKey != null &&
        !band.challengeFamilies.any((e) => e.key == level.challengeFamilyKey)) {
      issues.add(
        'Level ${level.levelNumber} challengeFamilyKey "${level.challengeFamilyKey}" is not allowed in this band.',
      );
    }

    if (level.visualFamilyKey != null &&
        !band.visualFamilies.any((e) => e.key == level.visualFamilyKey)) {
      issues.add(
        'Level ${level.levelNumber} visualFamilyKey "${level.visualFamilyKey}" is not allowed in this band.',
      );
    }

    return issues;
  }

  List<String> validateCollectionForMode(
      List<SortLevel> levels,
      String modeKey, {
        bool requireTargetCount = false,
      }) {
    final SortModePolicy policy = policyForModeKey(modeKey);
    final List<String> issues = <String>[];

    final Set<int> seen = <int>{};
    String? previousPattern;
    String? previousChallenge;
    String? previousVisual;

    for (final SortLevel level in levels) {
      if (!seen.add(level.levelNumber)) {
        issues.add(
          'Duplicate levelNumber ${level.levelNumber} found in ${policy.title}.',
        );
      }

      issues.addAll(validateLevelForMode(level, modeKey));

      if (level.levelNumber % 2 == 1) {
        previousPattern = level.patternFamilyKey;
        previousChallenge = level.challengeFamilyKey;
        previousVisual = level.visualFamilyKey;
      } else {
        int changed = 0;
        if (level.patternFamilyKey != null &&
            level.patternFamilyKey != previousPattern) {
          changed++;
        }
        if (level.challengeFamilyKey != null &&
            level.challengeFamilyKey != previousChallenge) {
          changed++;
        }
        if (level.visualFamilyKey != null &&
            level.visualFamilyKey != previousVisual) {
          changed++;
        }
        if (changed < 2) {
          issues.add(
            'Level ${level.levelNumber} should differ more clearly from the previous level pair.',
          );
        }
      }
    }

    if (requireTargetCount && levels.length != policy.targetOfficialLevels) {
      issues.add(
        '${policy.title} has ${levels.length} levels, expected ${policy.targetOfficialLevels}.',
      );
    }

    return issues;
  }
}