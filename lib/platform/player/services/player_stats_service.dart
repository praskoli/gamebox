import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../platform../../models/game_player_stats.dart';

class PlayerStatsService {
  PlayerStatsService._();

  static final PlayerStatsService instance = PlayerStatsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _statsRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('game_stats');
  }

  Future<GamePlayerStats> getStats(String gameId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final doc = await _statsRef(user.uid).doc(gameId).get();
    return GamePlayerStats.fromMap(gameId, doc.data());
  }

  Future<void> recordGameCompletion({
    required String gameId,
    required int xp,
    required int coins,
    required int levelNumber,
    required int score,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final docRef = _statsRef(user.uid).doc(gameId);
    final existing = await docRef.get();
    final current = GamePlayerStats.fromMap(gameId, existing.data());

    final updated = current.copyWith(
      gamesPlayed: current.gamesPlayed + 1,
      totalXp: current.totalXp + xp,
      totalCoins: current.totalCoins + coins,
      highestLevel: levelNumber > current.highestLevel
          ? levelNumber
          : current.highestLevel,
      bestScore: score > current.bestScore ? score : current.bestScore,
      lastPlayedAt: DateTime.now(),
    );

    await docRef.set(updated.toMap(), SetOptions(merge: true));
  }
}