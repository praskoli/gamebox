import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gamebox/games/sort_puzzle/creator/models/sort_puzzle_creator_draft.dart';

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
      throw StateError('User must be logged in to save DIY sort puzzles.');
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
    final String docId = draft.id.isNotEmpty ? draft.id : collection.doc().id;

    final DocumentReference<Map<String, dynamic>> docRef = collection.doc(docId);
    final DocumentSnapshot<Map<String, dynamic>> existing = await docRef.get();

    final Map<String, dynamic> data = draft
        .copyWith(
      id: docId,
      ownerUid: uid,
      creatorName: draft.creatorName.trim().isEmpty
          ? 'Arena Builder'
          : draft.creatorName.trim(),
    )
        .toJson();

    data['id'] = docId;
    data['ownerUid'] = uid;
    data['creatorName'] =
    draft.creatorName.trim().isEmpty ? 'Arena Builder' : draft.creatorName.trim();
    data['gameType'] = 'sort_puzzle';
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (existing.exists) {
      final Map<String, dynamic>? previous = existing.data();
      data['createdAt'] = previous?['createdAt'] ?? FieldValue.serverTimestamp();
      data['status'] = previous?['status'] ?? 'draft';
      data['submittedAt'] = previous?['submittedAt'];
      data['reviewedAt'] = previous?['reviewedAt'];
      data['reviewedBy'] = previous?['reviewedBy'] ?? '';
      data['rejectionReason'] = previous?['rejectionReason'] ?? '';
      data['communityVisible'] = previous?['communityVisible'] ?? false;
      data['approvedAt'] = previous?['approvedAt'];
      data['playCount'] = previous?['playCount'] ?? 0;
      data['likesCount'] = previous?['likesCount'] ?? 0;
    } else {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['status'] = 'draft';
      data['submittedAt'] = null;
      data['reviewedAt'] = null;
      data['reviewedBy'] = '';
      data['rejectionReason'] = '';
      data['communityVisible'] = false;
      data['approvedAt'] = null;
      data['playCount'] = 0;
      data['likesCount'] = 0;
    }

    await docRef.set(data, SetOptions(merge: true));
    return docId;
  }

  Future<void> submitForReview(SortPuzzleCreatorDraft draft) async {
    final String uid = _currentUid;
    final String docId = await saveDraft(
      draft.copyWith(
        ownerUid: uid,
        status: 'pending_review',
      ),
    );

    await _collection(uid).doc(docId).set(
      <String, dynamic>{
        'id': docId,
        'ownerUid': uid,
        'gameType': 'sort_puzzle',
        'creatorName':
        draft.creatorName.trim().isEmpty ? 'Arena Builder' : draft.creatorName.trim(),
        'status': 'pending_review',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': '',
        'communityVisible': false,
      },
      SetOptions(merge: true),
    );
  }

  Stream<List<SortPuzzleCreatorDraft>> watchProjectsByStatus(String status) {
    return _firestore
        .collectionGroup('custom_games')
        .where('gameType', isEqualTo: 'sort_puzzle')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<SortPuzzleCreatorDraft> items = snapshot.docs
          .map((doc) => SortPuzzleCreatorDraft.fromFirestore(doc.data(), doc.id))
          .toList(growable: false);

      items.sort((a, b) {
        final DateTime aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items;
    });
  }

  Future<bool> canSubmitMoreGames() async {
    final String uid = _currentUid;
    final AggregateQuerySnapshot snapshot = await _collection(uid)
        .where('gameType', isEqualTo: 'sort_puzzle')
        .where('status', whereIn: const <String>['pending_review', 'approved'])
        .count()
        .get();
    return (snapshot.count ?? 0) < 2;
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

  Future<void> approveProject(SortPuzzleCreatorDraft draft) async {
    final bool isAdmin = await isCurrentUserAdminReviewer();
    if (!isAdmin) {
      throw StateError('Only admin reviewers can approve sort projects.');
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
        'creatorName':
        draft.creatorName.trim().isEmpty ? 'Arena Builder' : draft.creatorName.trim(),
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
      throw StateError('Only admin reviewers can reject sort projects.');
    }

    final DocumentReference<Map<String, dynamic>> docRef = _firestore
        .collection('users')
        .doc(draft.ownerUid)
        .collection('custom_games')
        .doc(draft.id);

    await docRef.set(
      <String, dynamic>{
        'status': 'rejected',
        'communityVisible': false,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _currentEmail,
        'rejectionReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'gameType': 'sort_puzzle',
      },
      SetOptions(merge: true),
    );
  }
}