import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/scene_model.dart';
import '../domain/story_model.dart';
import 'story_moderation_service.dart';

class StoryBundle {
  const StoryBundle({
    required this.story,
    required this.scenes,
  });

  final StoryModel story;
  final List<SceneModel> scenes;
}

class StoryRepository {
  StoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    StoryModerationService? moderationService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _moderationService = moderationService ?? const StoryModerationService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StoryModerationService _moderationService;

  static const String _storiesCollection = 'stories';
  static const String _adminConfigCollection = 'app_config';
  static const String _adminConfigDocId = 'diy_review_admins';
  static const String _fallbackAdminEmail = 'koli.prasanth.rao@gmail.com';

  CollectionReference<Map<String, dynamic>> get _stories =>
      _firestore.collection(_storiesCollection);

  String get _currentUid {
    final String? uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be logged in to manage stories.');
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

  String get _currentCreatorName {
    final User? user = _auth.currentUser;
    final String? displayName = user?.displayName;
    if (displayName != null && displayName.trim().isNotEmpty) {
      return displayName.trim();
    }
    return _currentEmail.split('@').first;
  }

  Future<String> saveDraft({
    required StoryModel story,
    required List<SceneModel> scenes,
  }) async {
    final String uid = _currentUid;
    final String email = _currentEmail;
    final String storyId = story.id.trim().isEmpty ? _stories.doc().id : story.id;
    final DocumentReference<Map<String, dynamic>> storyRef = _stories.doc(storyId);
    final CollectionReference<Map<String, dynamic>> scenesRef =
    storyRef.collection('scenes');

    final SceneModel? coverScene = scenes.cast<SceneModel?>().firstWhere(
          (SceneModel? scene) =>
      scene != null && scene.imageUrl.trim().isNotEmpty,
      orElse: () => null,
    );

    final StoryModel normalizedStory = story.copyWith(
      id: storyId,
      ownerUid: uid,
      ownerEmail: email,
      creatorName: story.creatorName.trim().isEmpty
          ? _currentCreatorName
          : story.creatorName.trim(),
      coverImagePath: coverScene?.imagePath ?? '',
      coverImageUrl: coverScene?.imageUrl ?? '',
      contentType: 'story',
      sourceType: story.sourceType.trim().isEmpty ? 'diy' : story.sourceType,
      isModerated: scenes.every((SceneModel scene) => scene.isModerated),
    );

    final WriteBatch batch = _firestore.batch();
    final Map<String, dynamic> storyData = normalizedStory.toMap();

    storyData['updatedAt'] = FieldValue.serverTimestamp();

    // Important:
    // Do NOT pre-read storyRef.get() here.
    // That read is what was causing PERMISSION_DENIED on first save.
    //
    // We write safe defaults every time with merge. This avoids the failing read.
    storyData['createdAt'] = normalizedStory.createdAt == null
        ? FieldValue.serverTimestamp()
        : Timestamp.fromDate(normalizedStory.createdAt!);

    storyData['status'] =
    normalizedStory.status.trim().isEmpty ? 'draft' : normalizedStory.status.trim();

    storyData['submittedAt'] = normalizedStory.submittedAt == null
        ? null
        : Timestamp.fromDate(normalizedStory.submittedAt!);

    storyData['reviewedAt'] = normalizedStory.reviewedAt == null
        ? null
        : Timestamp.fromDate(normalizedStory.reviewedAt!);

    storyData['reviewedBy'] = normalizedStory.reviewedBy;
    storyData['rejectionReason'] = normalizedStory.rejectionReason;
    storyData['previewReadyAt'] = normalizedStory.previewReadyAt == null
        ? null
        : Timestamp.fromDate(normalizedStory.previewReadyAt!);

    storyData['communityVisible'] = normalizedStory.communityVisible;

    batch.set(storyRef, storyData, SetOptions(merge: true));

    for (int index = 0; index < scenes.length; index++) {
      final SceneModel scene = scenes[index].copyWith(
        id: scenes[index].id.trim().isEmpty
            ? 'scene_${(index + 1).toString().padLeft(2, '0')}'
            : scenes[index].id,
        storyId: storyId,
        order: index,
        caption: SceneModel.generateCaption(scenes[index].narration),
        durationSeconds:
        SceneModel.calculateDurationSeconds(scenes[index].narration),
      );

      final Map<String, dynamic> data = scene.toMap();
      data['updatedAt'] = FieldValue.serverTimestamp();
      data['createdAt'] = scene.createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(scene.createdAt!);

      batch.set(scenesRef.doc(scene.id), data, SetOptions(merge: true));
    }

    await batch.commit();
    return storyId;
  }

  Future<void> savePreviewReady({
    required StoryModel story,
    required List<SceneModel> scenes,
  }) async {
    final String storyId = await saveDraft(story: story, scenes: scenes);
    await _stories.doc(storyId).set(
      <String, dynamic>{
        'status': 'preview_ready',
        'previewReadyAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> submitForReview({
    required StoryModel story,
    required List<SceneModel> scenes,
  }) async {
    final StoryModerationSummary moderation = await _moderateAll(
      story: story,
      scenes: scenes,
    );

    if (!moderation.canSubmit) {
      throw StateError(moderation.reason);
    }

    final String storyId = await saveDraft(story: story, scenes: moderation.scenes);
    final DocumentReference<Map<String, dynamic>> storyRef = _stories.doc(storyId);
    final CollectionReference<Map<String, dynamic>> scenesRef =
    storyRef.collection('scenes');

    final WriteBatch batch = _firestore.batch();

    batch.set(
      storyRef,
      <String, dynamic>{
        'status': 'pending_review',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': '',
        'isModerated': true,
      },
      SetOptions(merge: true),
    );

    for (final SceneModel scene in moderation.scenes) {
      batch.set(
        scenesRef.doc(scene.id),
        <String, dynamic>{
          'status': scene.status,
          'flagReason': scene.flagReason,
          'isModerated': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<StoryBundle?> getStoryBundle(String storyId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc =
    await _stories.doc(storyId).get();
    if (!doc.exists) return null;

    final StoryModel story = StoryModel.fromMap(
      <String, dynamic>{
        ...?doc.data(),
        'id': doc.id,
      },
    );

    final QuerySnapshot<Map<String, dynamic>> sceneSnapshot = await _stories
        .doc(storyId)
        .collection('scenes')
        .orderBy('order')
        .get();

    final List<SceneModel> scenes =
    sceneSnapshot.docs.map((QueryDocumentSnapshot<Map<String, dynamic>> sceneDoc) {
      return SceneModel.fromMap(
        <String, dynamic>{
          ...sceneDoc.data(),
          'id': sceneDoc.id,
          'storyId': storyId,
        },
      );
    }).toList(growable: false);

    return StoryBundle(story: story, scenes: scenes);
  }

  Stream<List<StoryModel>> watchMyStories() {
    final String uid = _currentUid;
    return _stories
        .where('ownerUid', isEqualTo: uid)
        .where('contentType', isEqualTo: 'story')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
          StoryModel.fromMap(<String, dynamic>{...doc.data(), 'id': doc.id}))
          .toList(growable: false);
    });
  }

  Stream<List<StoryModel>> watchPublishedStories() {
    return _stories
        .where('contentType', isEqualTo: 'story')
        .where('communityVisible', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
          StoryModel.fromMap(<String, dynamic>{...doc.data(), 'id': doc.id}))
          .toList(growable: false);
    });
  }

  Stream<List<StoryModel>> watchStoriesByStatus(String status) {
    return _stories
        .where('contentType', isEqualTo: 'story')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      final List<StoryModel> items = snapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
          StoryModel.fromMap(<String, dynamic>{...doc.data(), 'id': doc.id}))
          .toList(growable: false);

      items.sort((StoryModel a, StoryModel b) {
        final DateTime aTime =
            a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime =
            b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items;
    });
  }

  Future<void> approveStory(StoryModel story) async {
    final bool isAdmin = await isCurrentUserAdminReviewer();
    if (!isAdmin) {
      throw StateError('Only admin reviewers can approve stories.');
    }

    await _stories.doc(story.id).set(
      <String, dynamic>{
        'status': 'published',
        'communityVisible': true,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _currentEmail,
        'rejectionReason': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'isModerated': true,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> rejectStory(
      StoryModel story, {
        required String reason,
      }) async {
    final bool isAdmin = await isCurrentUserAdminReviewer();
    if (!isAdmin) {
      throw StateError('Only admin reviewers can reject stories.');
    }

    await _stories.doc(story.id).set(
      <String, dynamic>{
        'status': 'rejected',
        'communityVisible': false,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': _currentEmail,
        'rejectionReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> deleteStory(String storyId) async {
    final StoryBundle? bundle = await getStoryBundle(storyId);
    if (bundle == null) return;

    if (bundle.story.ownerUid != _currentUid) {
      throw StateError('You can only delete your own story.');
    }

    final WriteBatch batch = _firestore.batch();
    final CollectionReference<Map<String, dynamic>> sceneRef =
    _stories.doc(storyId).collection('scenes');
    final QuerySnapshot<Map<String, dynamic>> scenes = await sceneRef.get();

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in scenes.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_stories.doc(storyId));
    await batch.commit();
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
            .map((dynamic e) => e.toString().trim().toLowerCase())
            .where((String e) => e.isNotEmpty)
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
            .map((dynamic e) => e.toString().trim())
            .where((String e) => e.isNotEmpty)
            .toList(growable: false);
      } else if (rawAllowedUids is String && rawAllowedUids.trim().isNotEmpty) {
        allowedUids = <String>[rawAllowedUids.trim()];
      } else {
        allowedUids = const <String>[];
      }

      return allowedUids.contains(currentUid) ||
          allowedEmails.contains(currentEmail);
    } catch (_) {
      return currentEmail == _fallbackAdminEmail;
    }
  }

  Future<StoryModerationSummary> _moderateAll({
    required StoryModel story,
    required List<SceneModel> scenes,
  }) async {
    final ModerationResult titleResult =
    await _moderationService.moderateStoryTitle(story.title);

    if (titleResult.shouldBlockSubmit) {
      return StoryModerationSummary(
        canSubmit: false,
        reason: titleResult.reason,
        scenes: scenes,
      );
    }

    final List<SceneModel> moderatedScenes = <SceneModel>[];

    for (int index = 0; index < scenes.length; index++) {
      SceneModel scene = scenes[index];

      final ModerationResult sceneTitleResult =
      await _moderationService.moderateSceneTitle(scene.title);
      if (sceneTitleResult.shouldBlockSubmit) {
        return StoryModerationSummary(
          canSubmit: false,
          reason: 'Scene ${index + 1}: ${sceneTitleResult.reason}',
          scenes: scenes,
        );
      }

      final ModerationResult narrationResult =
      await _moderationService.moderateNarration(scene.narration);
      if (narrationResult.shouldBlockSubmit) {
        return StoryModerationSummary(
          canSubmit: false,
          reason: 'Scene ${index + 1}: ${narrationResult.reason}',
          scenes: scenes,
        );
      }

      final bool isImageFlagged =
          scene.status == 'flagged' && scene.imageUrl.trim().isNotEmpty;

      final String mergedReason = <String>[
        if (isImageFlagged && scene.flagReason.trim().isNotEmpty)
          scene.flagReason.trim(),
        if (sceneTitleResult.isFlagged && sceneTitleResult.reason.trim().isNotEmpty)
          sceneTitleResult.reason.trim(),
        if (narrationResult.isFlagged && narrationResult.reason.trim().isNotEmpty)
          narrationResult.reason.trim(),
      ].join(' • ');

      scene = scene.copyWith(
        status: isImageFlagged ? 'flagged' : 'ready',
        flagReason: mergedReason,
        isModerated: true,
      );

      moderatedScenes.add(scene);
    }

    return StoryModerationSummary(
      canSubmit: true,
      scenes: moderatedScenes,
    );
  }
}

class StoryModerationSummary {
  const StoryModerationSummary({
    required this.canSubmit,
    required this.scenes,
    this.reason = '',
  });

  final bool canSubmit;
  final List<SceneModel> scenes;
  final String reason;
}