import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/memory_progress.dart';

class MemoryProgressRepository {
  MemoryProgressRepository._();

  static final MemoryProgressRepository instance =
  MemoryProgressRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DocumentReference<Map<String, dynamic>> _doc(String worldId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('memory_worlds')
        .doc(worldId);
  }

  Future<MemoryProgress> getProgress(String worldId) async {
    final ref = _doc(worldId);
    final snap = await ref.get();

    if (!snap.exists || snap.data() == null) {
      final initial = MemoryProgress.initial(worldId);
      await ref.set(initial.toMap(), SetOptions(merge: true));
      return initial;
    }

    return MemoryProgress.fromMap(snap.data()!);
  }

  Future<void> saveLevelResult({
    required String worldId,
    required int levelNumber,
    required int score,
    required int stars,
  }) async {
    final current = await getProgress(worldId);

    final bestScores = Map<int, int>.from(current.bestScores);
    final starsByLevel = Map<int, int>.from(current.starsByLevel);
    final completed = List<int>.from(current.completedLevels);

    final existingBest = bestScores[levelNumber] ?? 0;
    if (score > existingBest) {
      bestScores[levelNumber] = score;
    }

    final sanitizedStars = stars.clamp(1, 3);
    final existingStars = starsByLevel[levelNumber] ?? 0;
    if (sanitizedStars > existingStars) {
      starsByLevel[levelNumber] = sanitizedStars;
    }

    if (!completed.contains(levelNumber)) {
      completed.add(levelNumber);
      completed.sort();
    }

    final nextUnlockedCandidate = levelNumber + 1;
    final nextUnlocked = nextUnlockedCandidate > current.unlockedLevel
        ? nextUnlockedCandidate
        : current.unlockedLevel;

    final updated = current.copyWith(
      unlockedLevel: nextUnlocked,
      bestScores: bestScores,
      starsByLevel: starsByLevel,
      completedLevels: completed,
    );

    await _doc(worldId).set(updated.toMap(), SetOptions(merge: true));
  }
}