import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/parent_unlock_config.dart';
import '../domain/parent_unlock_request.dart';
import '../domain/parent_unlock_state.dart';

class ParentUnlockRepository {
  ParentUnlockRepository._();

  static final ParentUnlockRepository instance = ParentUnlockRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('No authenticated user.');
    }
    return uid;
  }

  DocumentReference<Map<String, dynamic>> get _configRef => _firestore
      .collection('users')
      .doc(_uid)
      .collection('parent_control')
      .doc('config')
      .collection('docs')
      .doc('main');

  DocumentReference<Map<String, dynamic>> get _stateRef => _firestore
      .collection('users')
      .doc(_uid)
      .collection('parent_control')
      .doc('state')
      .collection('docs')
      .doc('main');

  DocumentReference<Map<String, dynamic>> get _requestRef => _firestore
      .collection('users')
      .doc(_uid)
      .collection('parent_control')
      .doc('requests')
      .collection('docs')
      .doc('memory_match');

  Future<void> ensureInitialized() async {
    final batch = _firestore.batch();

    final configSnap = await _configRef.get();
    if (!configSnap.exists) {
      batch.set(_configRef, ParentUnlockConfig.initial().toMap(), SetOptions(merge: true));
    }

    final stateSnap = await _stateRef.get();
    if (!stateSnap.exists) {
      batch.set(_stateRef, ParentUnlockState.initial().toMap(), SetOptions(merge: true));
    }

    final requestSnap = await _requestRef.get();
    if (!requestSnap.exists) {
      batch.set(_requestRef, ParentUnlockRequest.initial().toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<ParentUnlockConfig> getConfig() async {
    await ensureInitialized();
    final snap = await _configRef.get();
    return ParentUnlockConfig.fromMap(snap.data() ?? <String, dynamic>{});
  }

  Future<ParentUnlockState> getState() async {
    await ensureInitialized();
    final snap = await _stateRef.get();
    return ParentUnlockState.fromMap(snap.data() ?? <String, dynamic>{});
  }

  Future<ParentUnlockRequest> getRequest() async {
    await ensureInitialized();
    final snap = await _requestRef.get();
    return ParentUnlockRequest.fromMap(snap.data() ?? <String, dynamic>{});
  }

  Future<void> updateConfig(ParentUnlockConfig config) async {
    await ensureInitialized();
    await _configRef.set(config.toMap(), SetOptions(merge: true));
  }

  Future<bool> validateParentPin(String inputPin) async {
    final config = await getConfig();
    return config.parentPin == inputPin.trim();
  }

  Future<void> requestUnlock({
    required String worldId,
    required int levelNumber,
  }) async {
    await ensureInitialized();

    final current = await getRequest();
    if (current.isPending) return;

    await _requestRef.set(
      ParentUnlockRequest(
        status: 'pending',
        requestedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        resolvedAtEpochMs: 0,
        requestedWorldId: worldId,
        requestedLevelNumber: levelNumber,
      ).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> approveRequest({int? tokenCount}) async {
    await ensureInitialized();

    final config = await getConfig();
    final state = await getState();
    final int grant = (tokenCount ?? config.tokensPerApproval).clamp(1, 50);

    await _firestore.runTransaction((tx) async {
      final currentStateSnap = await tx.get(_stateRef);
      final currentRequestSnap = await tx.get(_requestRef);

      final currentState = ParentUnlockState.fromMap(
        currentStateSnap.data() ?? <String, dynamic>{},
      );
      final currentRequest = ParentUnlockRequest.fromMap(
        currentRequestSnap.data() ?? <String, dynamic>{},
      );

      tx.set(
        _stateRef,
        currentState
            .copyWith(tokensRemaining: currentState.tokensRemaining + grant)
            .toMap(),
        SetOptions(merge: true),
      );

      tx.set(
        _requestRef,
        currentRequest
            .copyWith(
          status: 'approved',
          resolvedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        )
            .toMap(),
        SetOptions(merge: true),
      );
    });
  }

  Future<void> rejectRequest() async {
    await ensureInitialized();
    final current = await getRequest();

    await _requestRef.set(
      current
          .copyWith(
        status: 'rejected',
        resolvedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
      )
          .toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> clearRequest() async {
    await ensureInitialized();
    await _requestRef.set(
      ParentUnlockRequest.initial().toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> grantTokens(int amount) async {
    await ensureInitialized();
    final safeAmount = amount.clamp(1, 100);
    final state = await getState();

    await _stateRef.set(
      state.copyWith(tokensRemaining: state.tokensRemaining + safeAmount).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<bool> consumeOneTokenIfAvailable() async {
    await ensureInitialized();

    return _firestore.runTransaction((tx) async {
      final stateSnap = await tx.get(_stateRef);
      final state = ParentUnlockState.fromMap(stateSnap.data() ?? <String, dynamic>{});

      if (state.tokensRemaining <= 0) {
        return false;
      }

      tx.set(
        _stateRef,
        state.copyWith(tokensRemaining: state.tokensRemaining - 1).toMap(),
        SetOptions(merge: true),
      );

      return true;
    });
  }
}