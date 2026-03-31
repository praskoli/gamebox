import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/navigation/main_bottom_nav_screen.dart';
import '../../../game_engine/catalog/game_routes.dart';
import '../../../game_engine/map_engine/world_map_section_data.dart';
import '../../../game_engine/map_engine/world_map_section_theme.dart';
import '../../../game_engine/map_engine/widgets/progress_path_painter.dart';
import '../../../game_engine/map_engine/widgets/segmented_world_map_background.dart';
import '../../../platform/play_access/data/play_access_service.dart';
import '../../../platform/play_access/data/play_pause_message_library.dart';
import '../../../platform/play_access/domain/play_access_approval_request.dart';
import '../../../platform/play_access/data/play_access_repository.dart';
import '../../../platform/play_access/domain/play_access_guard_result.dart';
import '../../../platform/play_access/presentation/widgets/animated_play_pause_message_card.dart';
import '../data/memory_map_section_registry.dart';
import '../data/memory_world_registry.dart';
import '../domain/memory_level.dart';
import 'memory_world_map_view_model.dart';

class MemoryWorldMapScreen extends StatelessWidget {
  const MemoryWorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemoryWorldMapViewModel(
        worldId: MemoryWorldRegistry.fruitsWorldId,
      )..initialize(),
      child: const _MemoryWorldMapView(),
    );
  }
}

class _MemoryWorldMapView extends StatefulWidget {
  const _MemoryWorldMapView();

  @override
  State<_MemoryWorldMapView> createState() => _MemoryWorldMapViewState();
}

class _MemoryWorldMapViewState extends State<_MemoryWorldMapView>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final PlayAccessService _playAccessService = PlayAccessService.instance;

  int? _lastScrolledHighlight;
  bool _didCompleteAnyLevel = false;

  static const double _topPaddingForNodes = 180;
  static const double _nodeSpacing = 102.0;
  static const double _topHeaderReserved = 220.0;
  static const double _sectionTopInset = 30.0;
  static const double _sectionBottomInset = 88.0;

  static const double _trainVisualWidth = 132;
  static const double _trainVisualHeight = 92;

  late final AnimationController _trainMoveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final AnimationController _trainBounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  )..repeat(reverse: true);

  final AudioPlayer _trainAudioPlayer = AudioPlayer();

  Animation<double>? _trainProgressAnimation;
  double _trainProgress = 0.0;
  int _lastTrainTargetIndex = 0;
  bool _trainInitialized = false;

  @override
  void initState() {
    super.initState();
    unawaited(_playAccessService.initialize());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemoryWorldMapViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.error != null || vm.theme == null || vm.progress == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memory Match')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(vm.error ?? 'Failed to load world'),
          ),
        ),
      );
    }

    final theme = vm.theme!;
    final levels = vm.levels;
    final totalHeight =
        _topPaddingForNodes + (levels.length * _nodeSpacing) + 340;
    final sections = _buildSections(levels);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighlighted(vm.highlightLevel);
    });

    final pathPoints = _buildNodeCenters(levels);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTrainWithProgress(vm, pathPoints);
    });

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_didCompleteAnyLevel);
        return false;
      },
      child: Scaffold(
        body: Container(
          color: theme.backgroundBottom,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: SizedBox(
                      height: totalHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SegmentedWorldMapBackground(
                              sections: sections,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: ProgressPathPainter(points: pathPoints),
                              ),
                            ),
                          ),
                          if (pathPoints.isNotEmpty) ..._buildTrain(pathPoints),
                          ..._buildNodes(context, vm),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 10,
                  child: _TopWorldCard(
                    title: theme.worldTitle,
                    emoji: theme.worldEmoji,
                    unlockedLevel: vm.progress!.unlockedLevel,
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 22,
                  child: _RoundBackButton(
                    onTap: () => Navigator.of(context).pop(_didCompleteAnyLevel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<WorldMapSectionData> _buildSections(List<MemoryLevel> levels) {
    if (levels.isEmpty) return const [];

    final sections = <WorldMapSectionData>[];
    final totalSections =
        ((levels.last.levelNumber - 1) ~/
            MemoryMapSectionRegistry.levelsPerSection) +
            1;

    for (var sectionIndex = 0; sectionIndex < totalSections; sectionIndex++) {
      final startLevel =
          (sectionIndex * MemoryMapSectionRegistry.levelsPerSection) + 1;
      final endLevel =
          startLevel + MemoryMapSectionRegistry.levelsPerSection - 1;

      final firstIndex = levels.indexWhere((e) => e.levelNumber == startLevel);
      if (firstIndex == -1) continue;

      final visible = levels
          .where((e) => e.levelNumber >= startLevel && e.levelNumber <= endLevel)
          .toList();

      if (visible.isEmpty) continue;

      final top =
      (_yForIndex(firstIndex) - _sectionTopInset).clamp(0.0, double.infinity);
      final bottom =
          _yForIndex(firstIndex + visible.length - 1) + _sectionBottomInset;

      sections.add(
        WorldMapSectionData(
          sectionIndex: sectionIndex,
          startLevel: startLevel,
          endLevel: endLevel,
          top: top,
          height: bottom - top,
          theme: MemoryMapSectionRegistry.themeForSection(sectionIndex),
        ),
      );
    }

    return sections;
  }

  List<Offset> _buildNodeCenters(List<MemoryLevel> levels) {
    return List<Offset>.generate(
      levels.length,
          (index) => Offset(
        _xForIndex(index) + _nodeSizeForLevel(levels[index].levelNumber) / 2,
        _yForIndex(index) + _nodeSizeForLevel(levels[index].levelNumber) / 2,
      ),
      growable: false,
    );
  }

  void _scrollToHighlighted(int? levelNumber) {
    if (!_scrollController.hasClients || levelNumber == null) return;
    if (_lastScrolledHighlight == levelNumber) return;

    final vm = context.read<MemoryWorldMapViewModel>();
    final levels = vm.levels;

    final localIndex = levels.indexWhere((e) => e.levelNumber == levelNumber);
    if (localIndex == -1) return;

    _lastScrolledHighlight = levelNumber;

    final rawTarget =
        _topPaddingForNodes + (localIndex * _nodeSpacing) - _topHeaderReserved;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = rawTarget.clamp(0.0, maxExtent);

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
    );
  }

  List<Widget> _buildNodes(
      BuildContext context,
      MemoryWorldMapViewModel vm,
      ) {
    final levels = vm.levels;
    final items = <Widget>[];

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i];
      final nodeSize = _nodeSizeForLevel(level.levelNumber);
      final x = _xForIndex(i);
      final y = _yForIndex(i);

      final unlocked = vm.isUnlocked(level.levelNumber);
      final completed = vm.isCompleted(level.levelNumber);
      final stars = vm.starsFor(level.levelNumber);
      final isHighlighted = vm.highlightLevel == level.levelNumber;
      final isMilestone =
          level.levelNumber % MemoryMapSectionRegistry.levelsPerSection == 0;

      final sectionTheme = MemoryMapSectionRegistry.themeForSection(
        (level.levelNumber - 1) ~/ MemoryMapSectionRegistry.levelsPerSection,
      );

      items.add(
        Positioned(
          left: x,
          top: y,
          child: _LevelNode(
            level: level,
            size: nodeSize,
            unlocked: unlocked,
            completed: completed,
            stars: stars,
            isHighlighted: isHighlighted,
            isMilestone: isMilestone,
            nodeAccentColor: sectionTheme.nodeAccentColor,
            onTap: unlocked
                ? () async {
              await _handleLevelTap(context, vm, level);
            }
                : null,
          ),
        ),
      );
    }

    return items;
  }

  Future<void> _handleLevelTap(
      BuildContext context,
      MemoryWorldMapViewModel vm,
      MemoryLevel level,
      ) async {
    var guard = await _playAccessService.canStartPlay(
      gameId: 'memory_match',
    );

    if (!guard.canStart) {
      final unlocked = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => _PlayAccessBlockedDialog(
          level: level,
          guard: guard,
          playAccessService: _playAccessService,
        ),
      );

      if (unlocked != true || !context.mounted) {
        return;
      }

      guard = await _playAccessService.canStartPlay(
        gameId: 'memory_match',
      );

      if (!guard.canStart) {
        return;
      }
    }

    if (guard.shouldWarn) {
      final proceed = await _showPlayAccessWarningDialog(context, guard);
      if (proceed != true || !context.mounted) {
        return;
      }
    }

    final result = await Navigator.of(context).pushNamed(
      GameRoutes.memoryGame,
      arguments: {
        'worldId': vm.worldId,
        'levelNumber': level.levelNumber,
      },
    );

    if (result == true) {
      _didCompleteAnyLevel = true;
      await vm.refreshAfterLevelComplete();
    }
  }

  Future<bool?> _showPlayAccessWarningDialog(
      BuildContext context,
      PlayAccessGuardResult guard,
      ) {
    final message = PlayPauseMessageLibrary.pickBreakMessage(
      guard.minutesRemaining + guard.levelsRemaining,
    );

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedPlayPauseMessageCard(
            message: message,
            primaryActionLabel: 'Play Now',
            secondaryActionLabel: 'Take a Break',
            onPrimaryAction: () => Navigator.of(context).pop(true),
            onSecondaryAction: () => Navigator.of(context).pop(false),
          ),
        );
      },
    );
  }

  String _blockedReasonText(PlayAccessGuardResult guard) {
    switch (guard.reason) {
      case PlayAccessBlockReason.dailyMinutesReached:
        return 'Today’s play time is complete. Take a healthy break or ask for bonus time.';
      case PlayAccessBlockReason.dailyLevelsReached:
        return 'You’ve completed today’s free levels. Ask for bonus time if needed.';
      case PlayAccessBlockReason.approvalsExhausted:
        return 'No more approvals available for today.';
      case PlayAccessBlockReason.none:
        return 'Play is currently available.';
    }
  }

  double _nodeSizeForLevel(int levelNumber) {
    return levelNumber % MemoryMapSectionRegistry.levelsPerSection == 0 ? 78 : 66;
  }

  double _xForIndex(int index) {
    const positions = [92.0, 216.0, 62.0, 238.0, 112.0, 204.0];
    return positions[index % positions.length];
  }

  double _yForIndex(int index) {
    return _topPaddingForNodes + (index * _nodeSpacing);
  }

  void _syncTrainWithProgress(
      MemoryWorldMapViewModel vm,
      List<Offset> pathPoints,
      ) {
    if (pathPoints.isEmpty || vm.levels.isEmpty) return;

    final targetIndex = _lastVisibleUnlockedIndex(vm);

    if (!_trainInitialized) {
      _trainInitialized = true;
      _lastTrainTargetIndex = targetIndex;
      _trainProgress = 0.0;

      if (targetIndex > 0) {
        _animateTrainTo(targetIndex);
      } else {
        setState(() {
          _trainProgress = 0.0;
        });
      }
      return;
    }

    if (targetIndex != _lastTrainTargetIndex) {
      _animateTrainTo(targetIndex);
    }
  }

  int _lastVisibleUnlockedIndex(MemoryWorldMapViewModel vm) {
    for (int i = vm.levels.length - 1; i >= 0; i--) {
      if (vm.isUnlocked(vm.levels[i].levelNumber)) {
        return i;
      }
    }

    for (int i = 0; i < vm.levels.length; i++) {
      if (vm.isUnlocked(vm.levels[i].levelNumber)) {
        return i;
      }
    }

    return 0;
  }

  Future<void> _animateTrainTo(int targetIndex) async {
    if (!mounted) return;

    final end = targetIndex.toDouble();
    final start = _trainProgress;

    if ((end - start).abs() < 0.001) {
      _lastTrainTargetIndex = targetIndex;
      return;
    }

    _lastTrainTargetIndex = targetIndex;

    final distance = (end - start).abs();
    final duration = Duration(
      milliseconds: (2600 + (distance * 800)).round().clamp(2600, 8500),
    );

    _trainProgressAnimation = Tween<double>(
      begin: start,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: _trainMoveController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _trainMoveController.duration = duration;
    _trainMoveController.stop();
    _trainMoveController.reset();

    await _playTrainWhistle();

    _trainMoveController.forward().whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _trainProgress = end;
      });
    });

    setState(() {});
  }

  Future<void> _playTrainWhistle() async {
    try {
      await _trainAudioPlayer.stop();
      await _trainAudioPlayer.play(
        AssetSource('sounds/trainwhistle.mp3'),
        volume: 1.0,
      );
    } catch (_) {}
  }

  List<Widget> _buildTrain(List<Offset> pathPoints) {
    return [
      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _trainMoveController,
              _trainBounceController,
            ]),
            builder: (context, child) {
              final metrics = _trainMetrics(pathPoints);
              final bounceY =
                  -5.0 * math.sin(_trainBounceController.value * math.pi);
              final trainX = metrics.position.dx - (_trainVisualWidth / 2);
              final trainY =
                  metrics.position.dy - (_trainVisualHeight / 2) + bounceY;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: trainX,
                    top: trainY,
                    child: Transform.rotate(
                      angle: metrics.angle,
                      child: const _TrainMarker(
                        width: _trainVisualWidth,
                        height: _trainVisualHeight,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ];
  }

  _TrainMetrics _trainMetrics(List<Offset> pathPoints) {
    if (pathPoints.isEmpty) {
      return const _TrainMetrics(
        position: Offset.zero,
        angle: 0,
      );
    }

    if (pathPoints.length == 1) {
      return _TrainMetrics(
        position: pathPoints.first,
        angle: -math.pi / 2,
      );
    }

    final currentProgress = _trainProgressAnimation?.value ?? _trainProgress;
    final maxProgress = (pathPoints.length - 1).toDouble();
    final clampedProgress = currentProgress.clamp(0.0, maxProgress);

    final lowerIndex = clampedProgress.floor();
    final upperIndex = clampedProgress.ceil().clamp(0, pathPoints.length - 1);
    final segmentT = clampedProgress - lowerIndex;

    final from = pathPoints[lowerIndex];
    final to = pathPoints[upperIndex];

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;

    final position = Offset(
      from.dx + (dx * segmentT),
      from.dy + (dy * segmentT),
    );

    double angle;
    if (dx.abs() < 0.001 && dy.abs() < 0.001) {
      final fallbackFromIndex = lowerIndex > 0 ? lowerIndex - 1 : lowerIndex;
      final fallbackToIndex =
      lowerIndex < pathPoints.length - 1 ? lowerIndex + 1 : lowerIndex;

      final fallbackFrom = pathPoints[fallbackFromIndex];
      final fallbackTo = pathPoints[fallbackToIndex];

      angle = math.atan2(
        fallbackTo.dy - fallbackFrom.dy,
        fallbackTo.dx - fallbackFrom.dx,
      );
    } else {
      angle = math.atan2(dy, dx);
    }

    return _TrainMetrics(
      position: position,
      angle: angle,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _trainMoveController.dispose();
    _trainBounceController.dispose();
    _trainAudioPlayer.dispose();
    super.dispose();
  }
}

class _PlayAccessBlockedDialog extends StatefulWidget {
  const _PlayAccessBlockedDialog({
    required this.level,
    required this.guard,
    required this.playAccessService,
  });

  final MemoryLevel level;
  final PlayAccessGuardResult guard;
  final PlayAccessService playAccessService;

  @override
  State<_PlayAccessBlockedDialog> createState() =>
      _PlayAccessBlockedDialogState();
}

class _PlayAccessBlockedDialogState extends State<_PlayAccessBlockedDialog> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _cooldownTicker;

  bool _isRequesting = false;
  bool _isVerifying = false;
  bool _needsProfileSetup = false;

  String? _validationText;
  late String _statusText;

  PlayAccessApprovalRequest? _currentRequest;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _statusText = _blockedReasonText(widget.guard);
    unawaited(_loadPendingIfAny());
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingIfAny() async {
    final latest = await widget.playAccessService.getLatestPendingRequest();
    if (!mounted) return;

    if (latest != null && latest.isPending && !latest.isExpired) {
      setState(() {
        _currentRequest = latest;
        _cooldownSeconds = latest.resendRemainingSeconds;
        _statusText =
        'Approval code will be sent to ${latest.destinationMasked}.';
      });

      if (_cooldownSeconds > 0) {
        _startCooldown();
      }
    }
  }

  void _startCooldown() {
    _cooldownTicker?.cancel();

    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      int remaining =
          _currentRequest?.resendRemainingSeconds ?? _cooldownSeconds;

      if (remaining <= 0 && _cooldownSeconds > 0) {
        remaining = _cooldownSeconds - 1;
      }

      setState(() {
        _cooldownSeconds = remaining < 0 ? 0 : remaining;
      });

      if (_cooldownSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _goToProfile() {
    final navigator = Navigator.of(context);
    navigator.pop(false);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const MainBottomNavScreen(initialIndex: 3),
      ),
    );
  }

  Future<void> _handleRequestMorePlay() async {
    if (_needsProfileSetup) {
      _goToProfile();
      return;
    }

    if (_isRequesting) return;

    final hasActivePendingRequest = _currentRequest != null &&
        !_currentRequest!.isExpired &&
        _currentRequest!.isPending;

    if (hasActivePendingRequest && _cooldownSeconds > 0) {
      return;
    }

    setState(() {
      _isRequesting = true;
      _validationText = null;
      _statusText = 'Preparing approval request...';
      _needsProfileSetup = false;
    });

    try {
      final request = await widget.playAccessService.requestExtraPlay(
        gameId: 'memory_match',
        levelNumber: widget.level.levelNumber,
      );

      if (!mounted) return;

      setState(() {
        _isRequesting = false;
        _currentRequest = request;
        _cooldownSeconds = request.resendRemainingSeconds;
        _statusText =
        'Approval code will be sent to ${request.destinationMasked}. Check email and enter the 6-digit OTP.';
      });

      if (_cooldownSeconds > 0) {
        _startCooldown();
      }
    } on PlayAccessRequestException catch (e) {
      if (!mounted) return;

      setState(() {
        _isRequesting = false;
        _validationText = null;
        _needsProfileSetup = e.code == 'missing_parent_email';
        _statusText = e.code == 'missing_parent_email'
            ? 'No approval email is configured. Go to Profile and add Parent Approval Email or Temporary Email.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isRequesting = false;
        _statusText = 'Failed to send approval request. Please try again.';
        _validationText = null;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final cleanOtp = _otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(cleanOtp)) {
      setState(() {
        _validationText = 'Enter a valid 6-digit OTP.';
      });
      return;
    }

    final request = _currentRequest;
    if (request == null || !request.isPending || request.isExpired) {
      setState(() {
        _validationText = 'Request expired. Please request a new OTP.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _validationText = null;
    });

    try {
      final ok = await widget.playAccessService.verifyOtpForRequest(
        requestId: request.requestId,
        otp: cleanOtp,
      );

      if (!mounted) return;

      if (ok) {
        _cooldownTicker?.cancel();
        Navigator.of(context).pop(true);
        return;
      }

      setState(() {
        _isVerifying = false;
        _validationText = 'Invalid or expired OTP.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _validationText = 'Verification failed. Please try again.';
      });
    }
  }

  String _blockedReasonText(PlayAccessGuardResult guard) {
    switch (guard.reason) {
      case PlayAccessBlockReason.dailyMinutesReached:
        return 'Today’s play time is complete. Take a healthy break or ask for bonus time.';
      case PlayAccessBlockReason.dailyLevelsReached:
        return 'You’ve completed today’s free levels. Ask for bonus time if needed.';
      case PlayAccessBlockReason.approvalsExhausted:
        return 'No more approvals available for today.';
      case PlayAccessBlockReason.none:
        return 'Play is currently available.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final message =
    PlayPauseMessageLibrary.pickBonusMessage(widget.level.levelNumber);

    final otp = _otpController.text.trim();
    final canVerify = !_isVerifying && RegExp(r'^\d{6}$').hasMatch(otp);

    final hasActivePendingRequest = _currentRequest != null &&
        !_currentRequest!.isExpired &&
        _currentRequest!.isPending;

    final canRequest = !_isRequesting &&
        (!hasActivePendingRequest ||
            _cooldownSeconds <= 0 ||
            _needsProfileSetup);

    final String primaryButtonLabel = _isRequesting
        ? 'Requesting...'
        : _needsProfileSetup
        ? 'Go to Profile'
        : canRequest
        ? 'Request More Play'
        : 'Resend in ${_cooldownSeconds}s';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedPlayPauseMessageCard(
              message: message,
              primaryActionLabel: primaryButtonLabel,
              secondaryActionLabel: 'Not Now',
              onPrimaryAction: canRequest ? _handleRequestMorePlay : null,
              onSecondaryAction: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _statusText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  if (_currentRequest != null) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'OTP valid for 10 minutes.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: _goToProfile,
                      child: const Text('Change email in Profile'),
                    ),
                  ],
                  if (_needsProfileSetup) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _goToProfile,
                      child: const Text('Open Profile'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (_) {
                      if (_validationText != null) {
                        setState(() {
                          _validationText = null;
                        });
                      } else {
                        setState(() {});
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      border: const OutlineInputBorder(),
                      errorText: _validationText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canVerify ? _handleVerifyOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B67F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                        disabledForegroundColor: const Color(0xFF9CA3AF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isVerifying ? 'Verifying...' : 'Verify OTP',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopWorldCard extends StatelessWidget {
  const _TopWorldCard({
    required this.title,
    required this.emoji,
    required this.unlockedLevel,
  });

  final String title;
  final String emoji;
  final int unlockedLevel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 44),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$emoji $title',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unlocked till level $unlockedLevel',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundBackButton extends StatelessWidget {
  const _RoundBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.arrow_back_rounded),
        ),
      ),
    );
  }
}

class _LevelNode extends StatefulWidget {
  const _LevelNode({
    required this.level,
    required this.size,
    required this.unlocked,
    required this.completed,
    required this.stars,
    required this.isHighlighted,
    required this.isMilestone,
    required this.nodeAccentColor,
    required this.onTap,
  });

  final MemoryLevel level;
  final double size;
  final bool unlocked;
  final bool completed;
  final int stars;
  final bool isHighlighted;
  final bool isMilestone;
  final Color nodeAccentColor;
  final VoidCallback? onTap;

  @override
  State<_LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<_LevelNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  late final Animation<double> _pulse =
  Tween<double>(begin: 1, end: 1.10).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  late final Animation<double> _burst =
  Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isHighlighted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isHighlighted && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = !widget.unlocked
        ? const Color(0xFFBDBDBD)
        : widget.completed
        ? const Color(0xFF22C55E)
        : widget.nodeAccentColor;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final burstOpacity =
            widget.isHighlighted ? (1 - _burst.value) * 0.35 : 0.0;
            final burstScale = 1 + (_burst.value * 0.35);

            return Transform.scale(
              scale: widget.isHighlighted ? _pulse.value : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isHighlighted)
                    Opacity(
                      opacity: burstOpacity,
                      child: Transform.scale(
                        scale: burstScale,
                        child: Container(
                          width: widget.size + 10,
                          height: widget.size + 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: widget.unlocked
                              ? [color, color.withOpacity(0.86)]
                              : const [
                            Color(0xFFBDBDBD),
                            Color(0xFF9CA3AF),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border.all(
                          color: widget.isMilestone
                              ? const Color(0xFFFFD166)
                              : Colors.white,
                          width: widget.isMilestone ? 5 : 4,
                        ),
                        boxShadow: [
                          if (widget.isHighlighted)
                            BoxShadow(
                              color: color.withOpacity(0.45),
                              blurRadius: 18,
                              spreadRadius: 3,
                            ),
                          const BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (widget.isMilestone && widget.unlocked)
                            const Positioned(
                              top: 6,
                              child: Icon(
                                Icons.emoji_events_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          Center(
                            child: widget.unlocked
                                ? Padding(
                              padding: EdgeInsets.only(
                                top: widget.isMilestone ? 10 : 0,
                              ),
                              child: Text(
                                '${widget.level.levelNumber}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                  widget.isMilestone ? 18 : 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            )
                                : const Icon(
                              Icons.lock_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        if (widget.unlocked)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
                  (index) => Icon(
                index < widget.stars
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: widget.isMilestone ? 18 : 16,
                color: index < widget.stars
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _TrainMetrics {
  const _TrainMetrics({
    required this.position,
    required this.angle,
  });

  final Offset position;
  final double angle;
}

class _TrainMarker extends StatelessWidget {
  const _TrainMarker({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              width: width * 0.78,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: width * 0.02,
            top: height * 0.10,
            child: Container(
              width: width * 0.30,
              height: height * 0.42,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: width * 0.12,
                  height: height * 0.14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF93C5FD),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: width * 0.22,
            top: height * 0.22,
            child: Container(
              width: width * 0.48,
              height: height * 0.42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: width * 0.60,
            top: height * 0.28,
            child: Container(
              width: width * 0.18,
              height: height * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 3),
              ),
            ),
          ),
          Positioned(
            left: width * 0.16,
            top: height * 0.00,
            child: Container(
              width: width * 0.08,
              height: height * 0.22,
              decoration: BoxDecoration(
                color: const Color(0xFF4B5563),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            left: width * 0.14,
            top: -4,
            child: Container(
              width: width * 0.14,
              height: height * 0.16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.82),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18FFFFFF),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: width * 0.02,
            bottom: height * 0.02,
            child: _TrainWheel(size: height * 0.22),
          ),
          Positioned(
            left: width * 0.30,
            bottom: height * 0.02,
            child: _TrainWheel(size: height * 0.22),
          ),
          Positioned(
            left: width * 0.56,
            bottom: height * 0.02,
            child: _TrainWheel(size: height * 0.22),
          ),
        ],
      ),
    );
  }
}

class _TrainWheel extends StatelessWidget {
  const _TrainWheel({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.34,
          height: size * 0.34,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}