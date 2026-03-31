import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../games/memory_match/domain/memory_gameplay_defaults.dart';
import '../../../games/memory_match/domain/memory_world_bundle.dart';
import '../domain/memory_world_config.dart';
import '../domain/memory_world_sequence_config.dart';

class MemoryWorldConfigRepository {
  MemoryWorldConfigRepository._();

  static final MemoryWorldConfigRepository instance =
  MemoryWorldConfigRepository._();

  static const String _cacheKey = 'memory_match_bundle_cache_v1';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  MemoryWorldBundle? _cachedBundle;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _worldsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sequenceSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _gameplaySub;

  QuerySnapshot<Map<String, dynamic>>? _latestWorldsSnap;
  DocumentSnapshot<Map<String, dynamic>>? _latestSequenceSnap;
  DocumentSnapshot<Map<String, dynamic>>? _latestGameplaySnap;

  final StreamController<MemoryWorldBundle> _bundleUpdatesController =
  StreamController<MemoryWorldBundle>.broadcast();

  Stream<MemoryWorldBundle> get bundleUpdates => _bundleUpdatesController.stream;

  MemoryWorldBundle get fallbackBundle => _buildFallbackBundle();

  MemoryWorldBundle? get currentBundle => _cachedBundle;

  Future<MemoryWorldBundle> loadBundle({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedBundle != null) {
      _log('Returning in-memory bundle');
      return _cachedBundle!;
    }

    final MemoryWorldBundle? local = await _loadBundleFromLocalCache();
    if (!forceRefresh && local != null) {
      _cachedBundle = local;
      _log('Loaded bundle from local cache');
      unawaited(_refreshFromFirestoreInBackground());
      _ensureLiveListeners();
      return local;
    }

    try {
      final bundle = await _fetchBundleFromFirestore();
      _cachedBundle = bundle;
      await _saveBundleToLocalCache(bundle);
      _ensureLiveListeners();
      _log('Loaded bundle from Firestore');
      return bundle;
    } catch (e, st) {
      _logError('Failed to load Firestore bundle', e, st);

      if (local != null) {
        _cachedBundle = local;
        _ensureLiveListeners();
        _log('Using local cache after Firestore failure');
        return local;
      }

      final fallback = _buildFallbackBundle();
      _cachedBundle = fallback;
      _ensureLiveListeners();
      _log('Using hard fallback bundle');
      return fallback;
    }
  }

  Future<void> refreshNow() async {
    try {
      final bundle = await _fetchBundleFromFirestore();
      await _applyFreshBundle(bundle, source: 'manual_refresh');
    } catch (e, st) {
      _logError('Manual refresh failed', e, st);
    }
  }

  void _ensureLiveListeners() {
    if (_worldsSub != null || _sequenceSub != null || _gameplaySub != null) {
      return;
    }

    _log('Attaching live Firestore listeners');

    _worldsSub = _firestore
        .collection('memory_match_worlds')
        .where('enabled', isEqualTo: true)
        .snapshots()
        .listen(
          (snap) async {
        _latestWorldsSnap = snap;
        await _tryEmitBundleFromSnapshots(source: 'worlds_snapshot');
      },
      onError: (Object e, StackTrace st) {
        _logError('World listener error', e, st);
      },
    );

    _sequenceSub = _firestore
        .collection('memory_match_config')
        .doc('sequence')
        .snapshots()
        .listen(
          (snap) async {
        _latestSequenceSnap = snap;
        await _tryEmitBundleFromSnapshots(source: 'sequence_snapshot');
      },
      onError: (Object e, StackTrace st) {
        _logError('Sequence listener error', e, st);
      },
    );

    _gameplaySub = _firestore
        .collection('memory_match_config')
        .doc('gameplay_defaults')
        .snapshots()
        .listen(
          (snap) async {
        _latestGameplaySnap = snap;
        await _tryEmitBundleFromSnapshots(source: 'gameplay_snapshot');
      },
      onError: (Object e, StackTrace st) {
        _logError('Gameplay listener error', e, st);
      },
    );
  }

  Future<void> _refreshFromFirestoreInBackground() async {
    try {
      final bundle = await _fetchBundleFromFirestore();
      await _applyFreshBundle(bundle, source: 'background_refresh');
    } catch (e, st) {
      _logError('Background refresh failed', e, st);
    }
  }

  Future<MemoryWorldBundle> _fetchBundleFromFirestore() async {
    final worldsSnap = await _firestore
        .collection('memory_match_worlds')
        .where('enabled', isEqualTo: true)
        .get();

    final sequenceSnap = await _firestore
        .collection('memory_match_config')
        .doc('sequence')
        .get();

    final gameplaySnap = await _firestore
        .collection('memory_match_config')
        .doc('gameplay_defaults')
        .get();

    return _parseBundle(
      worldsDocs: worldsSnap.docs,
      sequenceData: sequenceSnap.data(),
      gameplayData: gameplaySnap.data(),
    );
  }

  Future<void> _tryEmitBundleFromSnapshots({
    required String source,
  }) async {
    if (_latestWorldsSnap == null ||
        _latestSequenceSnap == null ||
        _latestGameplaySnap == null) {
      return;
    }

    try {
      final bundle = _parseBundle(
        worldsDocs: _latestWorldsSnap!.docs,
        sequenceData: _latestSequenceSnap!.data(),
        gameplayData: _latestGameplaySnap!.data(),
      );

      await _applyFreshBundle(bundle, source: source);
    } catch (e, st) {
      _logError('Live update parse failed', e, st);
    }
  }

  Future<void> _applyFreshBundle(
      MemoryWorldBundle bundle, {
        required String source,
      }) async {
    final String nextHash = _bundleHash(bundle);
    final String currentHash =
    _cachedBundle == null ? '' : _bundleHash(_cachedBundle!);

    _cachedBundle = bundle;
    await _saveBundleToLocalCache(bundle);

    if (nextHash != currentHash) {
      _log('Emitting fresh bundle from $source');
      if (!_bundleUpdatesController.isClosed) {
        _bundleUpdatesController.add(bundle);
      }
    } else {
      _log('Bundle unchanged from $source');
    }
  }

  MemoryWorldBundle _parseBundle({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> worldsDocs,
    required Map<String, dynamic>? sequenceData,
    required Map<String, dynamic>? gameplayData,
  }) {
    if (sequenceData == null) {
      throw StateError('memory_match_config/sequence missing or null');
    }
    if (gameplayData == null) {
      throw StateError('memory_match_config/gameplay_defaults missing or null');
    }

    final List<MemoryWorldConfig> worlds = worldsDocs
        .map((doc) => MemoryWorldConfig.fromMap(doc.data()))
        .where((world) => world.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (worlds.isEmpty) {
      throw StateError('memory_match_worlds query returned zero enabled docs');
    }

    return MemoryWorldBundle(
      worlds: worlds,
      sequence: MemoryWorldSequenceConfig.fromMap(sequenceData),
      gameplay: MemoryGameplayDefaults.fromMap(gameplayData),
    );
  }

  Future<void> _saveBundleToLocalCache(MemoryWorldBundle bundle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'worlds': bundle.worlds.map((e) => e.toMap()).toList(),
        'sequence': bundle.sequence.toMap(),
        'gameplay': bundle.gameplay.toMap(),
      };
      await prefs.setString(_cacheKey, jsonEncode(payload));
      _log('Saved bundle to local cache');
    } catch (e, st) {
      _logError('Failed to save local cache', e, st);
    }
  }

  Future<MemoryWorldBundle?> _loadBundleFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final rawWorlds = decoded['worlds'];
      final rawSequence = decoded['sequence'];
      final rawGameplay = decoded['gameplay'];

      if (rawWorlds is! List ||
          rawSequence is! Map<String, dynamic> ||
          rawGameplay is! Map<String, dynamic>) {
        return null;
      }

      final worlds = rawWorlds
          .whereType<Map>()
          .map((e) => MemoryWorldConfig.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.id.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      if (worlds.isEmpty) {
        return null;
      }

      return MemoryWorldBundle(
        worlds: worlds,
        sequence: MemoryWorldSequenceConfig.fromMap(rawSequence),
        gameplay: MemoryGameplayDefaults.fromMap(rawGameplay),
      );
    } catch (e, st) {
      _logError('Failed to load local cache', e, st);
      return null;
    }
  }

  String _bundleHash(MemoryWorldBundle bundle) {
    final payload = jsonEncode(<String, dynamic>{
      'worlds': bundle.worlds.map((e) => e.toMap()).toList(),
      'sequence': bundle.sequence.toMap(),
      'gameplay': bundle.gameplay.toMap(),
    });
    return payload;
  }

  void _log(String message) {
    debugPrint('MemoryWorldConfigRepository: $message');
  }

  void _logError(String message, Object error, StackTrace st) {
    debugPrint('MemoryWorldConfigRepository: $message -> $error');
    debugPrint('$st');
  }

  MemoryWorldBundle _buildFallbackBundle() {
    const worlds = <MemoryWorldConfig>[
      MemoryWorldConfig(
        id: 'fruits',
        title: 'Fruits World',
        worldTitle: 'Fruits World',
        emoji: '🍎',
        worldGradientHex: <String>['#FFF176', '#FFB74D', '#FF7043'],
        tileGradientHex: <String>['#FFE082', '#FFCC80'],
        tileAccentHex: '#E65100',
        glowColorHex: '#66FFB74D',
        itemPool: <String>[
          '🍎',
          '🍌',
          '🍇',
          '🍊',
          '🍓',
          '🥭',
          '🍍',
          '🍉',
          '🍒',
          '🥝',
          '🍐',
          '🍑',
          '🍋',
          '🫐',
          '🥥',
          '🍈',
          '🍏',
          '🍅',
          '🍆',
          '🌽',
          '🥕',
          '🥑',
          '🥒',
          '🍠',
        ],
        mixedSourceWorldIds: <String>[],
        maxUniqueItems: 64,
        enabled: true,
        sortOrder: 10,
      ),
      MemoryWorldConfig(
        id: 'animals',
        title: 'Animals World',
        worldTitle: 'Animals World',
        emoji: '🐶',
        worldGradientHex: <String>['#B9F6CA', '#66BB6A', '#26A69A'],
        tileGradientHex: <String>['#C8E6C9', '#A5D6A7'],
        tileAccentHex: '#1B5E20',
        glowColorHex: '#664CAF50',
        itemPool: <String>[
          '🐶',
          '🐱',
          '🐭',
          '🐹',
          '🐰',
          '🦊',
          '🐻',
          '🐼',
          '🐨',
          '🦁',
          '🐯',
          '🐸',
          '🐵',
          '🐔',
          '🐧',
          '🐴',
          '🐮',
          '🐷',
          '🐙',
          '🦋',
          '🐘',
          '🦓',
          '🦒',
          '🐢',
        ],
        mixedSourceWorldIds: <String>[],
        maxUniqueItems: 64,
        enabled: true,
        sortOrder: 20,
      ),
      MemoryWorldConfig(
        id: 'vehicles',
        title: 'Vehicles World',
        worldTitle: 'Vehicles World',
        emoji: '🚗',
        worldGradientHex: <String>['#B3E5FC', '#42A5F5', '#3949AB'],
        tileGradientHex: <String>['#E3F2FD', '#90CAF9'],
        tileAccentHex: '#0D47A1',
        glowColorHex: '#665E92F3',
        itemPool: <String>[
          '🚚',
          '🛻',
          '🛺',
          '🚗',
          '🚧',
          '🏗️',
          '🚜',
          '🚑',
          '🚛',
          '🚐',
          '🚓',
          '🚒',
          '🚌',
          '🚎',
          '🚙',
          '🚘',
          '🚖',
          '🚍',
          '🚂',
          '🚁',
          '🛵',
          '🚲',
          '🚠',
          '🚡',
        ],
        mixedSourceWorldIds: <String>[],
        maxUniqueItems: 64,
        enabled: true,
        sortOrder: 30,
      ),
      MemoryWorldConfig(
        id: 'mixed_all',
        title: 'Mixed World',
        worldTitle: 'Mixed World',
        emoji: '🧩',
        worldGradientHex: <String>['#EDE7F6', '#B39DDB', '#7E57C2'],
        tileGradientHex: <String>['#F3E5F5', '#D1C4E9'],
        tileAccentHex: '#5E35B1',
        glowColorHex: '#667E57C2',
        itemPool: <String>[],
        mixedSourceWorldIds: <String>['fruits', 'animals', 'vehicles'],
        maxUniqueItems: 96,
        enabled: true,
        sortOrder: 40,
      ),
    ];

    const sequence = MemoryWorldSequenceConfig(
      initialSections: <MemoryWorldSequenceSection>[
        MemoryWorldSequenceSection(
          startLevel: 1,
          endLevel: 10,
          worldId: 'fruits',
        ),
        MemoryWorldSequenceSection(
          startLevel: 11,
          endLevel: 20,
          worldId: 'animals',
        ),
        MemoryWorldSequenceSection(
          startLevel: 21,
          endLevel: 30,
          worldId: 'vehicles',
        ),
      ],
      rotationStartLevel: 31,
      rotationWorldIds: <String>['fruits', 'animals', 'vehicles', 'mixed_all'],
      levelsPerWorldSection: 10,
      fallbackWorldId: 'fruits',
    );

    const gameplay = MemoryGameplayDefaults(
      gridRules: <MemoryGridRule>[
        MemoryGridRule(startLevel: 1, endLevel: 10, columns: 4, rows: 4),
        MemoryGridRule(startLevel: 11, endLevel: 25, columns: 4, rows: 4),
        MemoryGridRule(startLevel: 26, endLevel: 30, columns: 5, rows: 4),
        MemoryGridRule(startLevel: 31, endLevel: null, columns: 8, rows: 8),
      ],

      // ✅ ADD THIS NEW BLOCK (this was missing)
      previewRules: <MemoryPreviewRule>[
        MemoryPreviewRule(startLevel: 1, endLevel: 30, previewSeconds: 2.0),
        MemoryPreviewRule(startLevel: 31, endLevel: null, previewSeconds: 3.0),
      ],

      previewSecondsBase: 2.0,
      previewSecondsStepPerLevel: 0.0,
      previewSecondsMin: 2.0,

      flipBackMsBase: 800,
      flipBackMsStepPerLevel: 12,
      flipBackMsMin: 450,

      rewardCoinsBase: 10,
      rewardCoinsPerLevel: 3,

      rewardLevelEvery: 0,
      rewardLevelExtraCoins: 25,
      rewardLevelPreviewBonusSeconds: 0.0,

      speedLevelEvery: 0,
      speedLevelPreviewOverrideSeconds: 0.0,
      speedLevelExtraCoins: 35,

      memoryProEvery: 0,
      memoryProPreviewMaxSeconds: 0.0,
      memoryProExtraCoins: 50,
    );

    return const MemoryWorldBundle(
      worlds: worlds,
      sequence: sequence,
      gameplay: gameplay,
    );
  }

  Future<void> dispose() async {
    await _worldsSub?.cancel();
    await _sequenceSub?.cancel();
    await _gameplaySub?.cancel();
    await _bundleUpdatesController.close();
  }
}