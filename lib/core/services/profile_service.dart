import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../enums/app_mode.dart';
import '../models/player_profile.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
      final existing = PlayerProfile.fromMap(doc.data()!);

      final merged = existing.copyWith(
        email: existing.email.isNotEmpty ? existing.email : (user.email ?? ''),
        loginEmail: existing.loginEmail.isNotEmpty
            ? existing.loginEmail
            : (user.email ?? ''),
        approvalEmail: existing.approvalEmail,
        temporaryEmail: existing.temporaryEmail,
        photoUrl:
        existing.photoUrl.isNotEmpty ? existing.photoUrl : (user.photoURL ?? ''),
        mobileNumber: existing.mobileNumber.isNotEmpty
            ? existing.mobileNumber
            : (user.phoneNumber ?? ''),
        provider: existing.provider.isNotEmpty
            ? existing.provider
            : _resolveProvider(user),
        updatedAt: DateTime.now(),
      );

      await docRef.set(merged.toMap(), SetOptions(merge: true));
      return merged;
    }

    final now = DateTime.now();
    final profile = PlayerProfile(
      uid: user.uid,
      displayName: _resolveDisplayName(user),
      email: user.email ?? '',
      loginEmail: user.email ?? '',
      approvalEmail: user.email ?? '',
      temporaryEmail: '',
      mobileNumber: user.phoneNumber ?? '',
      photoUrl: user.photoURL ?? '',
      provider: _resolveProvider(user),
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

  Future<PlayerProfile> saveProfile({
    required String displayName,
    required String mobileNumber,
    required String approvalEmail,
    required String temporaryEmail,
    required String loginEmail,
    String? photoUrl,
  }) async {
    final profile = await getProfile();

    final updated = profile.copyWith(
      displayName: displayName.trim(),
      mobileNumber: mobileNumber.trim(),
      approvalEmail: approvalEmail.trim().toLowerCase(),
      temporaryEmail: temporaryEmail.trim().toLowerCase(),
      loginEmail: loginEmail.trim().toLowerCase(),
      photoUrl: photoUrl ?? profile.photoUrl,
      updatedAt: DateTime.now(),
    );

    await _usersRef.doc(profile.uid).set(
      updated.toMap(),
      SetOptions(merge: true),
    );

    return updated;
  }

  Future<String> uploadAvatarBytes(Uint8List bytes) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    final ref = _storage.ref().child('profile_photos/${user.uid}/avatar.jpg');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return ref.getDownloadURL();
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

    if (user.isAnonymous) {
      return 'Player';
    }

    return 'Player';
  }

  String _resolveProvider(User user) {
    if (user.isAnonymous) return 'guest';

    final providers = user.providerData
        .map((e) => e.providerId.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (providers.isEmpty) return 'unknown';
    return providers.first;
  }
}