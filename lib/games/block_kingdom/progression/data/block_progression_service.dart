import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'block_level_catalog.dart';

class BlockKingdomProgress {
  const BlockKingdomProgress({
    required this.highestUnlockedLevel,
    required this.lastPlayedLevel,
    required this.bestScoresByLevel,
  });

  final int highestUnlockedLevel;
  final int lastPlayedLevel;
  final Map<String, int> bestScoresByLevel;

  factory BlockKingdomProgress.initial() {
    return const BlockKingdomProgress(
      highestUnlockedLevel: 1,
      lastPlayedLevel: 1,
      bestScoresByLevel: <String, int>{},
    );
  }

  factory BlockKingdomProgress.fromMap(Map<String, dynamic>? map) {
    final rawScores = (map?['bestScoresByLevel'] as Map?) ?? const {};

    return BlockKingdomProgress(
      highestUnlockedLevel:
      ((map?['highestUnlockedLevel'] as num?)?.toInt() ?? 1).clamp(
        1,
        BlockLevelCatalog.maxKingdomLevel,
      ),
      lastPlayedLevel:
      ((map?['lastPlayedLevel'] as num?)?.toInt() ?? 1).clamp(
        1,
        BlockLevelCatalog.maxKingdomLevel,
      ),
      bestScoresByLevel: rawScores.map<String, int>(
            (key, value) => MapEntry(
          key.toString(),
          (value as num?)?.toInt() ?? 0,
        ),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'highestUnlockedLevel': highestUnlockedLevel,
      'lastPlayedLevel': lastPlayedLevel,
      'bestScoresByLevel': bestScoresByLevel,
    };
  }
}

class BlockProgressionService {
  BlockProgressionService._();

  static final BlockProgressionService instance = BlockProgressionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> get _docRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user found.');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('game_progress')
        .doc('block_kingdom');
  }

  Future<BlockKingdomProgress> getProgress() async {
    final snap = await _docRef.get();
    if (!snap.exists || snap.data() == null) {
      final initial = BlockKingdomProgress.initial();
      await _docRef.set(initial.toMap(), SetOptions(merge: true));
      return initial;
    }
    return BlockKingdomProgress.fromMap(snap.data());
  }

  Future<void> setLastPlayedLevel(int levelNumber) async {
    await _docRef.set(
      {
        'lastPlayedLevel': levelNumber.clamp(1, BlockLevelCatalog.maxKingdomLevel),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> completeLevel({
    required int levelNumber,
    required int score,
  }) async {
    final current = await getProgress();
    final nextUnlocked = (levelNumber + 1).clamp(1, BlockLevelCatalog.maxKingdomLevel);

    final existingBest = current.bestScoresByLevel['$levelNumber'] ?? 0;
    final updatedScores = Map<String, int>.from(current.bestScoresByLevel)
      ..['$levelNumber'] = score > existingBest ? score : existingBest;

    await _docRef.set(
      {
        'highestUnlockedLevel': nextUnlocked > current.highestUnlockedLevel
            ? nextUnlocked
            : current.highestUnlockedLevel,
        'lastPlayedLevel': nextUnlocked,
        'bestScoresByLevel': updatedScores,
      },
      SetOptions(merge: true),
    );
  }
}