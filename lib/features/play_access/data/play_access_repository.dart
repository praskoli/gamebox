import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/play_access_approval_request.dart';
import '../domain/play_access_config.dart';
import '../domain/play_access_daily_state.dart';

class PlayAccessRequestException implements Exception {
  const PlayAccessRequestException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'PlayAccessRequestException($code): $message';
}

class PlayAccessRepository {
  PlayAccessRepository._();

  static final PlayAccessRepository instance = PlayAccessRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Random _random = Random.secure();

  static const Duration _otpValidity = Duration(minutes: 10);
  static const Duration _resendCooldown = Duration(minutes: 2);

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const PlayAccessRequestException(
        code: 'not_authenticated',
        message: 'Please sign in again and retry.',
      );
    }
    return uid;
  }

  String todayDateKey({DateTime? now}) {
    final local = (now ?? DateTime.now()).toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  DocumentReference<Map<String, dynamic>> get _configRef => _firestore
      .collection('users')
      .doc(_uid)
      .collection('play_access')
      .doc('config')
      .collection('docs')
      .doc('main');

  DocumentReference<Map<String, dynamic>> _dailyRef(String dateKey) => _firestore
      .collection('users')
      .doc(_uid)
      .collection('play_access')
      .doc('daily_state')
      .collection('docs')
      .doc(dateKey);

  CollectionReference<Map<String, dynamic>> get _requestsCollection => _firestore
      .collection('users')
      .doc(_uid)
      .collection('play_access')
      .doc('approval_requests')
      .collection('docs');

  CollectionReference<Map<String, dynamic>> get _mailCollection =>
      _firestore.collection('mail');

  Future<void> ensureInitialized() async {
    final configSnap = await _configRef.get();
    if (!configSnap.exists) {
      await _configRef.set(
        PlayAccessConfig.initial().toMap(),
        SetOptions(merge: true),
      );
    }

    final dateKey = todayDateKey();
    final dailySnap = await _dailyRef(dateKey).get();
    if (!dailySnap.exists) {
      await _dailyRef(dateKey).set(
        PlayAccessDailyState.initial(dateKey: dateKey).toMap(),
        SetOptions(merge: true),
      );
    }
  }

  Future<PlayAccessConfig> getConfig() async {
    await ensureInitialized();
    final snap = await _configRef.get();
    return PlayAccessConfig.fromMap(snap.data() ?? <String, dynamic>{});
  }

  Future<PlayAccessDailyState> getTodayState() async {
    await ensureInitialized();
    final dateKey = todayDateKey();
    final snap = await _dailyRef(dateKey).get();
    final map = snap.data();
    if (map == null) {
      return PlayAccessDailyState.initial(dateKey: dateKey);
    }
    return PlayAccessDailyState.fromMap(map);
  }

  Future<void> updateConfig(PlayAccessConfig config) async {
    await ensureInitialized();
    await _configRef.set(config.toMap(), SetOptions(merge: true));
  }

  Future<PlayAccessDailyState> addActivePlaySeconds(int seconds) async {
    await ensureInitialized();
    final dateKey = todayDateKey();

    return _firestore.runTransaction((tx) async {
      final ref = _dailyRef(dateKey);
      final snap = await tx.get(ref);
      final current = snap.exists && snap.data() != null
          ? PlayAccessDailyState.fromMap(snap.data()!)
          : PlayAccessDailyState.initial(dateKey: dateKey);

      final next = current.copyWith(
        activePlaySeconds: current.activePlaySeconds + seconds.clamp(0, 86400),
        lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      tx.set(ref, next.toMap(), SetOptions(merge: true));
      return next;
    });
  }

  Future<PlayAccessDailyState> incrementCompletedLevels({
    int by = 1,
  }) async {
    await ensureInitialized();
    final dateKey = todayDateKey();

    return _firestore.runTransaction((tx) async {
      final ref = _dailyRef(dateKey);
      final snap = await tx.get(ref);
      final current = snap.exists && snap.data() != null
          ? PlayAccessDailyState.fromMap(snap.data()!)
          : PlayAccessDailyState.initial(dateKey: dateKey);

      final next = current.copyWith(
        completedLevels: current.completedLevels + by.clamp(0, 100),
        lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      tx.set(ref, next.toMap(), SetOptions(merge: true));
      return next;
    });
  }

  Future<PlayAccessApprovalRequest?> getLatestPendingRequest() async {
    final snap = await _requestsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAtEpochMs', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return PlayAccessApprovalRequest.fromMap(snap.docs.first.data());
  }

  Future<PlayAccessApprovalRequest?> getLatestPendingEmailRequest({
    required String destination,
  }) async {
    return null;
  }

  Future<PlayAccessApprovalRequest> createOrReuseApprovalRequest({
    required String gameId,
    required int levelNumber,
    required String channel,
    required String destination,
    required int grantMinutes,
    required int grantLevels,
  }) async {
    await ensureInitialized();

    final normalizedDestination = destination.trim().toLowerCase();
    if (channel != 'email' || !normalizedDestination.contains('@')) {
      throw const PlayAccessRequestException(
        code: 'email_required',
        message: 'A valid parent email is required for OTP approval.',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final requestId = _requestsCollection.doc().id;
    final request = PlayAccessApprovalRequest(
      requestId: requestId,
      status: 'pending',
      gameId: gameId,
      levelNumber: levelNumber,
      channel: 'email',
      destination: destination.trim(),
      destinationMasked: _maskDestination(destination),
      otpCode: _generateOtp(),
      createdAtEpochMs: now,
      expiresAtEpochMs: now + _otpValidity.inMilliseconds,
      usedAtEpochMs: 0,
      grantMinutes: grantMinutes,
      grantLevels: grantLevels,
      resendAvailableAtEpochMs: now + _resendCooldown.inMilliseconds,
    );

    await _persistApprovalRequestAndMail(
      request: request,
      destinationNormalized: normalizedDestination,
    );

    return request;
  }

  Future<void> _persistApprovalRequestAndMail({
    required PlayAccessApprovalRequest request,
    required String destinationNormalized,
  }) async {
    try {
      final batch = _firestore.batch();

      batch.set(
        _requestsCollection.doc(request.requestId),
        {
          ...request.toMap(),
          'destinationNormalized': destinationNormalized,
          'otpLength': 6,
          'otpValidityMinutes': _otpValidity.inMinutes,
          'resendCooldownSeconds': _resendCooldown.inSeconds,
        },
        SetOptions(merge: true),
      );

      batch.set(
        _mailCollection.doc(request.requestId),
        _mailPayloadForOtp(request),
        SetOptions(merge: true),
      );

      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const PlayAccessRequestException(
          code: 'mail_permission_denied',
          message:
          'Email request could not be queued. Please allow app writes to the mail collection.',
        );
      }

      throw PlayAccessRequestException(
        code: e.code,
        message: e.message ?? 'Unable to create approval request right now.',
      );
    }
  }

  Map<String, dynamic> _mailPayloadForOtp(PlayAccessApprovalRequest request) {
    return {
      'to': [request.destination],
      'message': {
        'subject': 'GameBox OTP for extra play',
        'text':
        'Your GameBox OTP is ${request.otpCode}. It is valid for 10 minutes.',
        'html':
        '<p>Your <b>GameBox OTP</b> is <b>${request.otpCode}</b>.</p><p>It is valid for <b>10 minutes</b>.</p>',
      },
      'meta': {
        'type': 'play_access_otp',
        'uid': _uid,
        'requestId': request.requestId,
        'gameId': request.gameId,
        'levelNumber': request.levelNumber,
      },
      'createdAtEpochMs': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<bool> verifyAndConsumeOtp(String otp) async {
    await ensureInitialized();
    final cleanOtp = otp.trim();
    if (cleanOtp.isEmpty) return false;

    final dateKey = todayDateKey();

    final pendingDocs = await _requestsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAtEpochMs', descending: true)
        .limit(10)
        .get();

    DocumentReference<Map<String, dynamic>>? matchRef;
    PlayAccessApprovalRequest? match;

    for (final doc in pendingDocs.docs) {
      final request = PlayAccessApprovalRequest.fromMap(doc.data());
      if (request.otpCode == cleanOtp && !request.isExpired) {
        matchRef = doc.reference;
        match = request;
        break;
      }
    }

    if (matchRef == null || match == null) {
      return false;
    }

    return _firestore.runTransaction((tx) async {
      final latestRequestSnap = await tx.get(matchRef!);
      if (!latestRequestSnap.exists || latestRequestSnap.data() == null) {
        return false;
      }

      final latestRequest =
      PlayAccessApprovalRequest.fromMap(latestRequestSnap.data()!);

      if (!latestRequest.isPending ||
          latestRequest.isExpired ||
          latestRequest.otpCode != cleanOtp) {
        return false;
      }

      final dailyRef = _dailyRef(dateKey);
      final dailySnap = await tx.get(dailyRef);
      final current = dailySnap.exists && dailySnap.data() != null
          ? PlayAccessDailyState.fromMap(dailySnap.data()!)
          : PlayAccessDailyState.initial(dateKey: dateKey);

      final nextDaily = current.copyWith(
        extraMinutesGranted:
        current.extraMinutesGranted + latestRequest.grantMinutes,
        extraLevelsGranted:
        current.extraLevelsGranted + latestRequest.grantLevels,
        approvalsUsed: current.approvalsUsed + 1,
        lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      tx.set(dailyRef, nextDaily.toMap(), SetOptions(merge: true));
      tx.set(
        matchRef!,
        latestRequest
            .copyWith(
          status: 'consumed',
          usedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        )
            .toMap(),
        SetOptions(merge: true),
      );

      return true;
    });
  }
  Future<bool> verifyAndConsumeOtpForRequest({
    required String requestId,
    required String otp,
  }) async {
    await ensureInitialized();

    final cleanOtp = otp.trim();
    if (cleanOtp.isEmpty || requestId.trim().isEmpty) return false;

    final dateKey = todayDateKey();
    final requestRef = _requestsCollection.doc(requestId);

    return _firestore.runTransaction((tx) async {
      final requestSnap = await tx.get(requestRef);
      if (!requestSnap.exists || requestSnap.data() == null) {
        return false;
      }

      final request = PlayAccessApprovalRequest.fromMap(requestSnap.data()!);

      if (!request.isPending) return false;
      if (request.isExpired) return false;
      if (request.otpCode != cleanOtp) return false;

      final dailyRef = _dailyRef(dateKey);
      final dailySnap = await tx.get(dailyRef);

      final current = dailySnap.exists && dailySnap.data() != null
          ? PlayAccessDailyState.fromMap(dailySnap.data()!)
          : PlayAccessDailyState.initial(dateKey: dateKey);

      final nextDaily = current.copyWith(
        extraMinutesGranted:
        current.extraMinutesGranted + request.grantMinutes,
        extraLevelsGranted:
        current.extraLevelsGranted + request.grantLevels,
        approvalsUsed: current.approvalsUsed + 1,
        lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
      );

      tx.set(dailyRef, nextDaily.toMap(), SetOptions(merge: true));
      tx.set(
        requestRef,
        request.copyWith(
          status: 'consumed',
          usedAtEpochMs: DateTime.now().millisecondsSinceEpoch,
        ).toMap(),
        SetOptions(merge: true),
      );

      return true;
    });
  }
  Future<String?> resolveEmailApprovalDestination({
    required PlayAccessConfig config,
  }) async {
    final user = _auth.currentUser;
    final authEmail = user?.email?.trim() ?? '';

    final profileDoc = await _firestore.collection('users').doc(_uid).get();
    final profileData = profileDoc.data() ?? <String, dynamic>{};

    final temporaryEmail =
    (profileData['temporaryEmail'] ?? '').toString().trim().toLowerCase();
    final approvalEmail =
    (profileData['approvalEmail'] ?? '').toString().trim().toLowerCase();
    final loginEmail =
    (profileData['loginEmail'] ?? '').toString().trim().toLowerCase();

    if (_isValidEmail(temporaryEmail)) {
      return temporaryEmail;
    }

    if (_isValidEmail(approvalEmail)) {
      return approvalEmail;
    }

    if (_isValidEmail(loginEmail)) {
      return loginEmail;
    }

    if (_isValidEmail(config.parentEmail)) {
      return config.parentEmail.trim().toLowerCase();
    }

    if (config.fallbackToLoginEmail && _isValidEmail(authEmail)) {
      return authEmail.toLowerCase();
    }

    return null;
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
  }

  String _generateOtp() {
    final value = 100000 + _random.nextInt(900000);
    return '$value';
  }

  String _maskDestination(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.contains('@')) {
      final parts = trimmed.split('@');
      final name = parts.first;
      final domain = parts.last;
      if (name.length <= 2) return '***@$domain';
      return '${name.substring(0, 2)}***@$domain';
    }

    if (trimmed.length <= 4) return '****';
    return '${trimmed.substring(0, 2)}******${trimmed.substring(trimmed.length - 2)}';
  }
}
