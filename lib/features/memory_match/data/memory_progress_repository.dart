import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/memory_progress.dart';

class MemoryProgressRepository {
  MemoryProgressRepository._();

  static final MemoryProgressRepository instance =
  MemoryProgressRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, MemoryProgress> _fallbackCache =
  <String, MemoryProgress>{};

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
    final String safeWorldId = worldId.trim().isEmpty ? 'fruits' : worldId.trim();

    final cached = _fallbackCache[safeWorldId];
    if (cached != null) {
      return cached;
    }

    try {
      final ref = _doc(safeWorldId);
      final snap = await ref.get();

      if (!snap.exists || snap.data() == null) {
        final initial = MemoryProgress.initial(safeWorldId);
        _fallbackCache[safeWorldId] = initial;
        await ref.set(initial.toMap(), SetOptions(merge: true));
        return initial;
      }

      final progress = MemoryProgress.fromMap(snap.data()!);
      _fallbackCache[safeWorldId] = progress;
      return progress;
    } catch (_) {
      final fallback = MemoryProgress.initial(safeWorldId);
      _fallbackCache[safeWorldId] = fallback;
      return fallback;
    }
  }

  Future<void> saveLevelResult({
    required String worldId,
    required int levelNumber,
    required int score,
    required int stars,
  }) async {
    final String safeWorldId = worldId.trim().isEmpty ? 'fruits' : worldId.trim();
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;
    final int safeScore = score < 0 ? 0 : score;
    final int sanitizedStars = stars.clamp(1, 3);

    final current = await getProgress(safeWorldId);

    final bestScores = Map<int, int>.from(current.bestScores);
    final starsByLevel = Map<int, int>.from(current.starsByLevel);
    final completed = List<int>.from(current.completedLevels);

    final existingBest = bestScores[safeLevel] ?? 0;
    if (safeScore > existingBest) {
      bestScores[safeLevel] = safeScore;
    }

    final existingStars = starsByLevel[safeLevel] ?? 0;
    if (sanitizedStars > existingStars) {
      starsByLevel[safeLevel] = sanitizedStars;
    }

    if (!completed.contains(safeLevel)) {
      completed.add(safeLevel);
      completed.sort();
    }

    final int nextUnlockedCandidate = safeLevel + 1;
    final int nextUnlocked = nextUnlockedCandidate > current.unlockedLevel
        ? nextUnlockedCandidate
        : current.unlockedLevel;

    final updated = current.copyWith(
      unlockedLevel: nextUnlocked < 1 ? 1 : nextUnlocked,
      bestScores: bestScores,
      starsByLevel: starsByLevel,
      completedLevels: completed,
    );

    _fallbackCache[safeWorldId] = updated;

    try {
      await _doc(safeWorldId).set(updated.toMap(), SetOptions(merge: true));
    } catch (_) {
      // keep local session-safe fallback; do not break gameplay
    }
  }
}