import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockProgression {
  final int highestUnlockedLevel;
  final int lastPlayedLevel;
  final Map<String, int> bestScoresByLevel;

  const BlockProgression({
    required this.highestUnlockedLevel,
    required this.lastPlayedLevel,
    required this.bestScoresByLevel,
  });

  factory BlockProgression.initial() {
    return const BlockProgression(
      highestUnlockedLevel: 1,
      lastPlayedLevel: 1,
      bestScoresByLevel: {},
    );
  }

  BlockProgression copyWith({
    int? highestUnlockedLevel,
    int? lastPlayedLevel,
    Map<String, int>? bestScoresByLevel,
  }) {
    return BlockProgression(
      highestUnlockedLevel:
      highestUnlockedLevel ?? this.highestUnlockedLevel,
      lastPlayedLevel: lastPlayedLevel ?? this.lastPlayedLevel,
      bestScoresByLevel:
      bestScoresByLevel ?? this.bestScoresByLevel,
    );
  }
}

class BlockProgressionService {
  BlockProgressionService._();

  static final instance = BlockProgressionService._();

  final _firestore = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('game_progress')
          .doc('block_kingdom');

  // 🔹 LOAD PROGRESSION
  Future<BlockProgression> getProgress() async {
    try {
      final snap = await _doc.get();

      if (!snap.exists) {
        return BlockProgression.initial();
      }

      final data = snap.data()!;

      return BlockProgression(
        highestUnlockedLevel:
        (data['highestUnlockedLevel'] ?? 1) as int,
        lastPlayedLevel: (data['lastPlayedLevel'] ?? 1) as int,
        bestScoresByLevel:
        Map<String, int>.from(data['bestScoresByLevel'] ?? {}),
      );
    } catch (_) {
      // fallback → never block game
      return BlockProgression.initial();
    }
  }

  // 🔹 SAVE ON LEVEL COMPLETE
  Future<void> completeLevel({
    required int level,
    required int score,
  }) async {
    final progress = await getProgress();

    final newBestScores = Map<String, int>.from(progress.bestScoresByLevel);

    final key = level.toString();
    final existing = newBestScores[key] ?? 0;

    if (score > existing) {
      newBestScores[key] = score;
    }

    final newHighest =
    level >= progress.highestUnlockedLevel
        ? level + 1
        : progress.highestUnlockedLevel;

    await _doc.set({
      'highestUnlockedLevel': newHighest,
      'lastPlayedLevel': newHighest,
      'bestScoresByLevel': newBestScores,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 🔹 SAVE LAST PLAYED (on retry / exit)
  Future<void> setLastPlayed(int level) async {
    await _doc.set({
      'lastPlayedLevel': level,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}