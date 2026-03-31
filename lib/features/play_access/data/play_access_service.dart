import 'package:flutter/widgets.dart';

import '../domain/play_access_approval_request.dart';
import '../domain/play_access_config.dart';
import '../domain/play_access_daily_state.dart';
import '../domain/play_access_guard_result.dart';
import 'play_access_repository.dart';

class PlayAccessService with WidgetsBindingObserver {
  PlayAccessService._();

  static final PlayAccessService instance = PlayAccessService._();

  final PlayAccessRepository _repository = PlayAccessRepository.instance;

  PlayAccessConfig? _config;
  PlayAccessDailyState? _todayState;

  String? _activeGameId;
  int _activeLevelNumber = 0;
  DateTime? _activeStartedAt;
  DateTime? _lastInteractionAt;
  bool _isForeground = false;
  bool _sessionRunning = false;
  bool _levelCompletionRecorded = false;

  static const Duration _idleThreshold = Duration(seconds: 75);

  bool _initialized = false;

  bool get isSessionRunning => _sessionRunning;
  String? get activeGameId => _activeGameId;
  PlayAccessConfig? get config => _config;
  PlayAccessDailyState? get todayState => _todayState;

  Future<void> initialize() async {
    if (!_initialized) {
      WidgetsBinding.instance.addObserver(this);
      _initialized = true;
    }
    await _repository.ensureInitialized();
    await refresh();
  }

  Future<void> refresh() async {
    _config = await _repository.getConfig();
    _todayState = await _repository.getTodayState();
  }

  Future<PlayAccessGuardResult> canStartPlay({
    required String gameId,
  }) async {
    await refresh();

    final config = _config ?? PlayAccessConfig.initial();
    final state = _todayState ??
        PlayAccessDailyState.initial(
          dateKey: _repository.todayDateKey(),
        );

    if (!config.enabled) {
      return PlayAccessGuardResult.allowed(
        shouldWarn: false,
        minutesRemaining: config.dailyFreeMinutes,
        levelsRemaining: config.dailyFreeLevels,
      );
    }

    final totalAllowedMinutes =
        config.dailyFreeMinutes + state.extraMinutesGranted;
    final totalAllowedLevels =
        config.dailyFreeLevels + state.extraLevelsGranted;

    final usedMinutes = (state.activePlaySeconds / 60).floor();
    final remainingMinutes = (totalAllowedMinutes - usedMinutes).clamp(0, 9999);
    final remainingLevels =
    (totalAllowedLevels - state.completedLevels).clamp(0, 9999);

    if (remainingMinutes <= 0) {
      return PlayAccessGuardResult.blocked(
        reason: PlayAccessBlockReason.dailyMinutesReached,
        minutesRemaining: remainingMinutes,
        levelsRemaining: remainingLevels,
      );
    }

    if (remainingLevels <= 0) {
      return PlayAccessGuardResult.blocked(
        reason: PlayAccessBlockReason.dailyLevelsReached,
        minutesRemaining: remainingMinutes,
        levelsRemaining: remainingLevels,
      );
    }

    final shouldWarn = remainingMinutes <= config.warningBeforeMinutes ||
        remainingLevels <= config.warningBeforeLevels;

    return PlayAccessGuardResult.allowed(
      shouldWarn: shouldWarn,
      minutesRemaining: remainingMinutes,
      levelsRemaining: remainingLevels,
    );
  }

  Future<void> beginGameplaySession({
    required String gameId,
    required int levelNumber,
  }) async {
    await refresh();

    _activeGameId = gameId;
    _activeLevelNumber = levelNumber;
    _activeStartedAt = DateTime.now();
    _lastInteractionAt = _activeStartedAt;
    _isForeground = true;
    _sessionRunning = true;
    _levelCompletionRecorded = false;
  }

  void recordUserInteraction() {
    if (!_sessionRunning) return;
    _lastInteractionAt = DateTime.now();
  }

  Future<void> pauseGameplaySession() async {
    if (!_sessionRunning) return;
    await _commitElapsedActiveTime();
    _isForeground = false;
  }

  Future<void> resumeGameplaySession() async {
    if (!_sessionRunning) return;
    _activeStartedAt = DateTime.now();
    _lastInteractionAt = _activeStartedAt;
    _isForeground = true;
  }

  Future<void> endGameplaySession({
    required bool completedLevel,
  }) async {
    if (!_sessionRunning) return;

    await _commitElapsedActiveTime();

    if (completedLevel && !_levelCompletionRecorded) {
      await _repository.incrementCompletedLevels(by: 1);
      _levelCompletionRecorded = true;
    }

    await refresh();

    _activeGameId = null;
    _activeLevelNumber = 0;
    _activeStartedAt = null;
    _lastInteractionAt = null;
    _isForeground = false;
    _sessionRunning = false;
  }

  Future<PlayAccessApprovalRequest> requestExtraPlay({
    required String gameId,
    required int levelNumber,
  }) async {
    await refresh();

    final config = _config ?? PlayAccessConfig.initial();
    final state = _todayState ??
        PlayAccessDailyState.initial(
          dateKey: _repository.todayDateKey(),
        );

    if (state.approvalsUsed >= config.maxApprovalsPerDay) {
      throw const PlayAccessRequestException(
        code: 'approvals_exhausted',
        message: 'No more approvals are available for today.',
      );
    }

    final destination = await _repository.resolveEmailApprovalDestination(
      config: config,
    );

    if (destination == null || destination.trim().isEmpty) {
      throw const PlayAccessRequestException(
        code: 'missing_parent_email',
        message:
        'No parent email is configured. Add a parent email or enable login-email fallback.',
      );
    }

    return _repository.createOrReuseApprovalRequest(
      gameId: gameId,
      levelNumber: levelNumber,
      channel: 'email',
      destination: destination,
      grantMinutes: config.approvalGrantMinutes,
      grantLevels: config.approvalGrantLevels,
    );
  }

  Future<PlayAccessApprovalRequest?> getLatestPendingRequest() {
    return _repository.getLatestPendingRequest();
  }
  Future<void> _commitElapsedActiveTime() async {
    if (!_sessionRunning || !_isForeground) return;

    final startedAt = _activeStartedAt;
    final lastInteraction = _lastInteractionAt;
    if (startedAt == null || lastInteraction == null) return;

    final now = DateTime.now();

    if (now.difference(lastInteraction) > _idleThreshold) {
      final activeUntil = lastInteraction;
      final seconds = activeUntil.difference(startedAt).inSeconds;
      if (seconds > 0) {
        await _repository.addActivePlaySeconds(seconds);
      }
      _activeStartedAt = now;
      _lastInteractionAt = now;
      return;
    }

    final seconds = now.difference(startedAt).inSeconds;
    if (seconds > 0) {
      await _repository.addActivePlaySeconds(seconds);
    }

    _activeStartedAt = now;
    _lastInteractionAt = now;
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_sessionRunning) {
          await resumeGameplaySession();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_sessionRunning) {
          await pauseGameplaySession();
        }
        break;
    }
  }
  Future<bool> verifyOtpForRequest({
    required String requestId,
    required String otp,
  }) async {
    final ok = await _repository.verifyAndConsumeOtpForRequest(
      requestId: requestId,
      otp: otp,
    );
    await refresh();
    return ok;
  }
}
