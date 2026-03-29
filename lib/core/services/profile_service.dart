import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../enums/app_mode.dart';
import '../models/player_profile.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  Future<PlayerProfile> ensureProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final docRef = _usersRef.doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return PlayerProfile.fromMap(doc.data()!);
    }

    final now = DateTime.now();
    final profile = PlayerProfile(
      uid: user.uid,
      displayName: _resolveDisplayName(user),
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
      currentMode: AppMode.normal,
      coins: 100,
      xp: 0,
      level: 1,
      streakDays: 1,
      gamesPlayed: 0,
      dailyRewardClaimedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(profile.toMap(), SetOptions(merge: true));
    return profile;
  }

  Future<PlayerProfile> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final doc = await _usersRef.doc(user.uid).get();
    if (!doc.exists || doc.data() == null) {
      return ensureProfile();
    }

    return PlayerProfile.fromMap(doc.data()!);
  }

  Future<void> updateMode(AppMode mode) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user found.');

    await _usersRef.doc(user.uid).set({
      'currentMode': mode.key,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<PlayerProfile> claimDailyReward({
    required int coins,
    required int xp,
  }) async {
    final profile = await getProfile();

    final updated = profile.copyWith(
      coins: profile.coins + coins,
      xp: profile.xp + xp,
      dailyRewardClaimedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final leveled = _applyLevelFormula(updated);

    await _usersRef.doc(profile.uid).set(
      leveled.toMap(),
      SetOptions(merge: true),
    );

    return leveled;
  }

  Future<PlayerProfile> addGameCompletionRewards({
    required int coins,
    required int xp,
  }) async {
    final profile = await getProfile();

    final updated = profile.copyWith(
      coins: profile.coins + coins,
      xp: profile.xp + xp,
      gamesPlayed: profile.gamesPlayed + 1,
      updatedAt: DateTime.now(),
    );

    final leveled = _applyLevelFormula(updated);

    await _usersRef.doc(profile.uid).set(
      leveled.toMap(),
      SetOptions(merge: true),
    );

    return leveled;
  }

  PlayerProfile _applyLevelFormula(PlayerProfile profile) {
    final computedLevel = (profile.xp ~/ 100) + 1;
    return profile.copyWith(level: computedLevel);
  }

  String _resolveDisplayName(User user) {
    final raw = (user.displayName ?? '').trim();
    if (raw.isNotEmpty) return raw;
    final email = (user.email ?? '').trim();
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'Player';
  }
}