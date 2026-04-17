import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../creator/models/sort_puzzle_creator_draft.dart';

class SortPuzzleRepository {
  SortPuzzleRepository._();

  static final SortPuzzleRepository instance = SortPuzzleRepository._();

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
      throw StateError('User must be logged in to save Sort Puzzle projects.');
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

  Future<String> saveDraft(SortPuzzleCreatorDraft draft) async {
    final String uid = _currentUid;
    final CollectionReference<Map<String, dynamic>> collection = _collection(uid);
    final String projectId = draft.id.isNotEmpty ? draft.id : collection.doc().id;

    final DocumentReference<Map<String, dynamic>> docRef = collection.doc(projectId);
    final DocumentSnapshot<Map<String, dynamic>> existing = await docRef.get();

    final Map<String, dynamic> data = draft
        .copyWith(
      id: projectId,
      ownerUid: uid,
    )
        .toJson();

    data['updatedAt'] = FieldValue.serverTimestamp();

    if (existing.exists) {
      final Map<String, dynamic>? previous = existing.data();
      data['createdAt'] = previous?['createdAt'] ?? FieldValue.serverTimestamp();
      data['status'] = previous?['status'] ?? 'draft';
      data['submittedAt'] = previous?['submittedAt'];
      data['reviewedAt'] = previous?['reviewedAt'];
      data['reviewedBy'] = previous?['reviewedBy'] ?? '';
      data['rejectionReason'] = previous?['rejectionReason'] ?? '';
      data['approvedAt'] = previous?['approvedAt'];
      data['communityVisible'] = previous?['communityVisible'] ?? false;
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
      data['approvedAt'] = null;
      data['communityVisible'] = false;
      data['creatorName'] = (data['creatorName'] ?? '').toString().trim().isNotEmpty
          ? data['creatorName']
          : 'Arena Builder';
    }

    await docRef.set(data, SetOptions(merge: true));
    return projectId;
  }

  Future<void> submitForReview(SortPuzzleCreatorDraft draft) async {
    final String uid = _currentUid;

    final String projectId = await saveDraft(
      draft.copyWith(
        ownerUid: uid,
        status: 'pending_review',
      ),
    );

    await _collection(uid).doc(projectId).set(
      <String, dynamic>{
        'id': projectId,
        'ownerUid': uid,
        'gameType': 'sort_puzzle',
        'creatorName': draft.creatorName.trim().isEmpty
            ? 'Arena Builder'
            : draft.creatorName.trim(),
        'status': 'pending_review',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': '',
        'communityVisible': false,
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<SortPuzzleCreatorDraft>> watchDrafts() {
    final String uid = _currentUid;

    return _collection(uid)
        .where('gameType', isEqualTo: 'sort_puzzle')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
        final Map<String, dynamic> data = doc.data();
        return SortPuzzleCreatorDraft.fromFirestore(data, doc.id);
      }).toList(growable: false);
    });
  }

  Future<SortPuzzleCreatorDraft?> getById(String id) async {
    final String uid = _currentUid;
    final DocumentSnapshot<Map<String, dynamic>> doc =
    await _collection(uid).doc(id).get();

    if (!doc.exists) return null;

    return SortPuzzleCreatorDraft.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> deleteDraft(String id) async {
    final String uid = _currentUid;
    await _collection(uid).doc(id).delete();
  }

  Future<bool> isCurrentUserAdminReviewer() async {
    try {
      final String currentUid = _auth.currentUser?.uid?.trim() ?? '';
      final String currentEmail =
          _auth.currentUser?.email?.trim().toLowerCase() ?? '';

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
      } else if (rawAllowedEmails is String &&
          rawAllowedEmails.trim().isNotEmpty) {
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
      } else if (rawAllowedUids is String &&
          rawAllowedUids.trim().isNotEmpty) {
        allowedUids = <String>[rawAllowedUids.trim()];
      } else {
        allowedUids = const <String>[];
      }

      if (currentUid.isNotEmpty && allowedUids.contains(currentUid)) {
        return true;
      }

      if (currentEmail.isNotEmpty && allowedEmails.contains(currentEmail)) {
        return true;
      }

      return false;
    } catch (_) {
      final String fallbackEmail =
          _auth.currentUser?.email?.trim().toLowerCase() ?? '';
      return fallbackEmail == _fallbackAdminEmail;
    }
  }

  Stream<List<SortPuzzleCreatorDraft>> watchProjectsByStatus(String status) {
    return _firestore
        .collectionGroup('custom_games')
        .where('gameType', isEqualTo: 'sort_puzzle')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<SortPuzzleCreatorDraft> items = snapshot.docs.map((doc) {
        return SortPuzzleCreatorDraft.fromFirestore(doc.data(), doc.id);
      }).toList(growable: false);

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

  Future<void> approveProject(SortPuzzleCreatorDraft draft) async {
    final bool isAdmin = await isCurrentUserAdminReviewer();
    if (!isAdmin) {
      throw StateError('Only admin reviewers can approve projects.');
    }

    if (draft.ownerUid.trim().isEmpty) {
      throw StateError('Project owner UID is missing.');
    }

    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(draft.ownerUid)
        .collection('custom_games')
        .doc(draft.id);

    await docRef.set(
      <String, dynamic>{
        'status': 'approved',
        'communityVisible': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _currentEmail,
        'rejectionReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'creatorName': draft.creatorName.trim().isEmpty
            ? 'Arena Builder'
            : draft.creatorName.trim(),
        'gameType': 'sort_puzzle',
      },
      SetOptions(merge: true),
    );
  }

  Future<void> rejectProject(
      SortPuzzleCreatorDraft draft, {
        required String reason,
      }) async {
    final bool isAdmin = await isCurrentUserAdminReviewer();
    if (!isAdmin) {
      throw StateError('Only admin reviewers can reject projects.');
    }

    if (draft.ownerUid.trim().isEmpty) {
      throw StateError('Project owner UID is missing.');
    }

    await _firestore
        .collection('users')
        .doc(draft.ownerUid)
        .collection('custom_games')
        .doc(draft.id)
        .set(
      <String, dynamic>{
        'status': 'rejected',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _currentEmail,
        'rejectionReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'creatorName': draft.creatorName.trim().isEmpty
            ? 'Arena Builder'
            : draft.creatorName.trim(),
        'gameType': 'sort_puzzle',
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> canSubmitMoreGames() async {
    final String uid = _currentUid;

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _collection(uid)
        .where('gameType', isEqualTo: 'sort_puzzle')
        .where('status', whereIn: ['pending_review', 'approved'])
        .get();

    return snapshot.docs.length < 2;
  }
}