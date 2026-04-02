import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../games/memory_match/domain/memory_diy_game_config.dart';

class MemoryDiyRepository {
  MemoryDiyRepository._();

  static final MemoryDiyRepository instance = MemoryDiyRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _firestore.collection('users').doc(uid).collection('custom_games');
  }

  String get _currentUid {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be logged in to save DIY games.');
    }
    return uid;
  }

  Future<String> saveDraft(MemoryDiyGameConfig config) async {
    final String uid = _currentUid;
    final CollectionReference<Map<String, dynamic>> collection = _collection(uid);
    final String gameId = config.id.isNotEmpty ? config.id : collection.doc().id;

    final DocumentReference<Map<String, dynamic>> docRef = collection.doc(gameId);
    final DocumentSnapshot<Map<String, dynamic>> existing = await docRef.get();

    final Map<String, dynamic> data = config
        .copyWith(
      id: gameId,
      ownerUid: uid,
    )
        .toMap();

    data['updatedAt'] = FieldValue.serverTimestamp();

    if (existing.exists) {
      final Map<String, dynamic>? previous = existing.data();
      data['createdAt'] = previous?['createdAt'] ?? FieldValue.serverTimestamp();
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data, SetOptions(merge: true));
    return gameId;
  }

  Stream<List<MemoryDiyGameConfig>> watchDrafts() {
    final String uid = _currentUid;

    return _collection(uid)
        .where('gameType', isEqualTo: 'memory')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return MemoryDiyGameConfig.fromMap(data);
      }).toList(growable: false);
    });
  }

  Future<MemoryDiyGameConfig?> getById(String id) async {
    final String uid = _currentUid;
    final DocumentSnapshot<Map<String, dynamic>> doc =
    await _collection(uid).doc(id).get();

    if (!doc.exists) return null;

    final Map<String, dynamic> data = doc.data()!;
    data['id'] = doc.id;
    return MemoryDiyGameConfig.fromMap(data);
  }

  Future<void> deleteDraft(String id) async {
    final String uid = _currentUid;
    await _collection(uid).doc(id).delete();
  }
}