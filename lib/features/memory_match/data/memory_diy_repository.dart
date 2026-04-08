import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../games/memory_match/domain/memory_diy_game_config.dart';

class MemoryDiyRepository {
  MemoryDiyRepository._();

  static final MemoryDiyRepository instance = MemoryDiyRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _adminConfigCollection = 'app_config';
  static const String _adminConfigDocId = 'diy_review_admins';
  static const String _fallbackAdminEmail = 'koli.prasanth.rao@gmail.com';

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

  String get _currentEmail {
    final String? email = _auth.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      throw StateError('User must be logged in with an email account.');
    }
    return email.trim().toLowerCase();
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
      data['status'] = previous?['status'] ?? 'draft';
      data['submittedAt'] = previous?['submittedAt'];
      data['reviewedAt'] = previous?['reviewedAt'];
      data['reviewedBy'] = previous?['reviewedBy'] ?? '';
      data['rejectionReason'] = previous?['rejectionReason'] ?? '';
      data['creatorName'] = (data['creatorName'] ?? '').toString().trim().isNotEmpty
          ? data['creatorName']
          : (previous?['creatorName'] ?? 'Arena Builder');
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['status'] = 'draft';
      data['submittedAt'] = null;
      data['reviewedAt'] = null;
      data['reviewedBy'] = '';
      data['rejectionReason'] = '';
      data['creatorName'] = (data['creatorName'] ?? '').toString().trim().isNotEmpty
          ? data['creatorName']
          : 'Arena Builder';
    }

    await docRef.set(data, SetOptions(merge: true));
    return gameId;
  }

  Future<void> submitForReview(MemoryDiyGameConfig config) async {
    final String uid = _currentUid;

    final String gameId = await saveDraft(
      config.copyWith(
        ownerUid: uid,
        status: 'pending_review',
      ),
    );

    await _collection(uid).doc(gameId).set(
      <String, dynamic>{
        'id': gameId,
        'ownerUid': uid,
        'gameType': 'memory',
        'creatorName': config.creatorName.trim().isEmpty
            ? 'Arena Builder'
            : config.creatorName.trim(),
        'status': 'pending_review',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': '',
      },
      SetOptions(merge: true),
    );
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

  Future<bool> isCurrentUserAdminReviewer() async {
    final String currentEmail = _currentEmail;
    final String currentUid = _currentUid;

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection(_adminConfigCollection)
          .doc(_adminConfigDocId)
          .get();

      final Map<String, dynamic>? data = doc.data();

      final dynamic rawAllowedEmails = data?['allowedEmails'];
      final dynamic rawAllowedUids = data?['allowedUids'];

      final List<String> allowedEmails;
      if (rawAllowedEmails is List) {
        allowedEmails = rawAllowedEmails
            .map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      } else if (rawAllowedEmails is String && rawAllowedEmails.trim().isNotEmpty) {
        allowedEmails = <String>[rawAllowedEmails.trim().toLowerCase()];
      } else {
        allowedEmails = <String>[_fallbackAdminEmail];
      }

      final List<String> allowedUids;
      if (rawAllowedUids is List) {
        allowedUids = rawAllowedUids
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
      } else if (rawAllowedUids is String && rawAllowedUids.trim().isNotEmpty) {
        allowedUids = <String>[rawAllowedUids.trim()];
      } else {
        allowedUids = const <String>[];
      }

      return allowedUids.contains(currentUid) || allowedEmails.contains(currentEmail);
    } catch (_) {
      return currentEmail == _fallbackAdminEmail;
    }
  }

  Stream<List<MemoryDiyGameConfig>> watchProjectsByStatus(String status) {
    return _firestore
        .collectionGroup('custom_games')
        .where('gameType', isEqualTo: 'memory')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<MemoryDiyGameConfig> items = snapshot.docs.map((doc) {
        final Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return MemoryDiyGameConfig.fromMap(data);
      }).toList();

      items.sort((a, b) {
        final DateTime aTime =
            a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items;
    });
  }

  Future<void> approveProject(MemoryDiyGameConfig config) async {
    final bool isAdmin = await isCurrentUserAdminReviewer();
    if (!isAdmin) {
      throw StateError('Only admin reviewers can approve projects.');
    }

    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(config.ownerUid)
        .collection('custom_games')
        .doc(config.id);

    await docRef.set(
      <String, dynamic>{
        'status': 'approved',
        'communityVisible': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _currentEmail,
        'rejectionReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'creatorName': config.creatorName.trim().isEmpty
            ? 'Arena Builder'
            : config.creatorName.trim(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> rejectProject(
      MemoryDiyGameConfig config, {
        required String reason,
      }) async {
    final bool isAdmin = await isCurrentUserAdminReviewer();
    if (!isAdmin) {
      throw StateError('Only admin reviewers can reject projects.');
    }

    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(config.ownerUid)
        .collection('custom_games')
        .doc(config.id);

    await docRef.set(
      <String, dynamic>{
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _currentEmail,
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
        'creatorName': config.creatorName.trim().isEmpty
            ? 'Arena Builder'
            : config.creatorName.trim(),
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> canSubmitMoreGames() async {
    final String uid = _currentUid;

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(uid)
        .where('gameType', isEqualTo: 'memory')
        .where('status', whereIn: ['pending_review', 'approved'])
        .get();

    return snapshot.docs.length < 2;
  }
}