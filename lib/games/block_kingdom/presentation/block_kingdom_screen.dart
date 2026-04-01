import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../platform/audio/sound_service.dart';
import '../../../platform/player/services/player_stats_service.dart';
import '../../../platform/profile/services/profile_service.dart';
import '../../../platform/play_access/data/play_access_service.dart';
import '../domain/block_mode.dart';
import '../progression/data/block_level_catalog.dart';
import '../progression/data/block_progression_service.dart';
import 'controller/block_controller.dart';
import 'effects/block_place_effect.dart';
import 'effects/line_clear_sweep_effect.dart';
import 'widgets/banner_widget.dart';
import 'widgets/board_widget.dart';
import 'widgets/piece_widget.dart';
import 'widgets/tray_widget.dart';
import 'widgets/time_trial_overlay.dart';

class BlockKingdomScreen extends StatefulWidget {
  const BlockKingdomScreen({
    super.key,
    this.mode = BlockMode.endless,
    this.initialLevelNumber = 1,
  });

  final BlockMode mode;
  final int initialLevelNumber;

  @override
  State<BlockKingdomScreen> createState() => _BlockKingdomScreenState();
}

class _BlockKingdomScreenState extends State<BlockKingdomScreen> {
  BlockController? _controller;
  final GlobalKey _boardKey = GlobalKey();

  bool _isPreparing = true;
  bool _dialogShown = false;
  bool _resolutionHandled = false;
  int _lastFeedbackVersion = 0;

  Timer? _timeTrialTimer;

  final List<_OverlayEntryData> _overlayEntries = <_OverlayEntryData>[];

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _timeTrialTimer?.cancel();
    final activeController = _controller;
    if (activeController != null) {
      PlayAccessService.instance.endGameplaySession(
        completedLevel: false,
      );
    }
    super.dispose();
  }

  Future<void> _prepare({int? forceLevelNumber}) async {
    setState(() {
      _isPreparing = true;
      _dialogShown = false;
      _resolutionHandled = false;
      _overlayEntries.clear();
      _lastFeedbackVersion = 0;
    });

    try {
      //int startLevel = forceLevelNumber ?? widget.initialLevelNumber;
      int startLevel = 15; // 🔥 test level
      if (widget.mode == BlockMode.kingdom) {
        final progress = await BlockProgressionService.instance.getProgress();
        startLevel = progress.lastPlayedLevel.clamp(
          1,
          BlockLevelCatalog.maxKingdomLevel,
        );
      }

      final controller = BlockController(
        mode: widget.mode,
        initialLevelNumber: startLevel,
      )..start();

      _controller = controller;

      await PlayAccessService.instance.beginGameplaySession(
        gameId: 'block_kingdom',
        levelNumber: controller.currentLevelNumber,
      );

      _configureTimer();
      SoundService.instance.playGameStart();
    } catch (e, st) {
      debugPrint('BLOCK PREPARE ERROR -> $e');
      debugPrint('$st');
    } finally {
      if (!mounted) return;
      setState(() {
        _isPreparing = false;
      });
    }
  }

  void _configureTimer() {
    _timeTrialTimer?.cancel();

    if (widget.mode != BlockMode.timeTrial) return;

    _timeTrialTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isPreparing || _dialogShown) return;

      final controller = _controller;
      if (controller == null) return;

      controller.tickTimer();
      _checkResolutionAndShowDialog();
    });
  }

  Future<void> _restartSession({int? levelNumber}) async {
    _timeTrialTimer?.cancel();
    await PlayAccessService.instance.endGameplaySession(
      completedLevel: false,
    );
    await _prepare(forceLevelNumber: levelNumber);
  }

  Future<void> _startNextKingdomLevel() async {
    final controller = _controller;
    if (controller == null) return;

    final nextLevel = (controller.currentLevelNumber + 1).clamp(
      1,
      BlockLevelCatalog.maxKingdomLevel,
    );

    await PlayAccessService.instance.endGameplaySession(
      completedLevel: true,
    );

    if (nextLevel > BlockLevelCatalog.maxKingdomLevel) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    await _prepare(forceLevelNumber: nextLevel);
  }

  void _scheduleBoardRectUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _boardKey.currentContext;
      if (ctx == null) return;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;

      final offset = box.localToGlobal(Offset.zero);
      _controller?.attachBoardRect(offset & box.size);
    });
  }

  Future<void> _applyRewards({
    required bool success,
  }) async {
    final controller = _controller;
    if (controller == null) return;

    final score = controller.engine.session.score;
    int xp = 0;
    int coins = 0;

    switch (widget.mode) {
      case BlockMode.endless:
        xp = (score ~/ 10).clamp(5, 999999);
        coins = (score ~/ 5).clamp(3, 999999);
        break;
      case BlockMode.kingdom:
        if (success) {
          xp = controller.levelDefinition.rewardXp + (score ~/ 40);
          coins = controller.levelDefinition.rewardCoins + (score ~/ 70);
        }
        break;
      case BlockMode.timeTrial:
        if (success) {
          final timeBonus = (controller.engine.session.remainingSeconds ~/ 5);
          xp = controller.levelDefinition.rewardXp + timeBonus;
          coins = controller.levelDefinition.rewardCoins + (timeBonus ~/ 2);
        }
        break;
    }

    if (coins > 0 || xp > 0) {
      await ProfileService.instance.addGameCompletionRewards(
        coins: coins,
        xp: xp,
      );
    }

    await PlayerStatsService.instance.recordGameCompletion(
      gameId: 'block_kingdom',
      xp: xp,
      coins: coins,
      levelNumber: controller.currentLevelNumber,
      score: score,
    );

    if (widget.mode == BlockMode.kingdom && success) {
      await BlockProgressionService.instance.completeLevel(
        levelNumber: controller.currentLevelNumber,
        score: score,
      );
    } else if (widget.mode == BlockMode.kingdom) {
      await BlockProgressionService.instance.setLastPlayedLevel(
        controller.currentLevelNumber,
      );
    }
  }

  void _consumeFeedback() {
    final controller = _controller;
    if (controller == null) return;

    final feedback = controller.latestFeedback;
    final rect = controller.boardRect;
    final cellSize = controller.boardCellSize;

    if (feedback == null ||
        rect == null ||
        cellSize <= 0 ||
        feedback.eventId == _lastFeedbackVersion) {
      return;
    }

    _lastFeedbackVersion = feedback.eventId;

    final placedOffsets = feedback.placedCells
        .map(
          (cell) => Offset(
        rect.left + (cell.col * cellSize),
        rect.top + (cell.row * cellSize),
      ),
    )
        .toList();

    final clearedOffsets = feedback.clearedCells
        .map(
          (cell) => Offset(
        rect.left + (cell.col * cellSize),
        rect.top + (cell.row * cellSize),
      ),
    )
        .toList();

    _overlayEntries.add(
      _OverlayEntryData(
        id: UniqueKey().toString(),
        widget: BlockPlaceEffect(
          cellPositions: placedOffsets,
          cellSize: cellSize,
        ),
      ),
    );

    if (feedback.clearedRows.isNotEmpty || feedback.clearedCols.isNotEmpty) {
      _overlayEntries.add(
        _OverlayEntryData(
          id: UniqueKey().toString(),
          widget: LineClearSweepEffect(
            boardRect: rect,
            cellSize: cellSize,
            rows: feedback.clearedRows,
            cols: feedback.clearedCols,
          ),
        ),
      );
    }

    if (clearedOffsets.isNotEmpty) {
      _overlayEntries.add(
        _OverlayEntryData(
          id: UniqueKey().toString(),
          widget: BlockPlaceEffect(
            cellPositions: clearedOffsets,
            cellSize: cellSize,
            emphasizeClear: true,
          ),
        ),
      );
    }

    _overlayEntries.add(
      _OverlayEntryData(
        id: UniqueKey().toString(),
        widget: _CelebrationTextEffect(
          center: rect.center,
          primaryText: feedback.primaryText,
          secondaryText: feedback.secondaryText,
          highlight: feedback.crossedMilestone,
          combo: feedback.combo,
        ),
      ),
    );

    if (feedback.scoreGain > 0) {
      _overlayEntries.add(
        _OverlayEntryData(
          id: UniqueKey().toString(),
          widget: _FloatingScoreEffect(
            position: Offset(rect.right - 96, rect.top + 12),
            text: '+${feedback.scoreGain}',
            highlight: feedback.crossedMilestone,
          ),
        ),
      );
    }

    Future.delayed(const Duration(milliseconds: 760), () {
      if (!mounted) return;
      setState(() {
        _overlayEntries.clear();
      });
    });
  }

  Future<void> _showSuccessDialog() async {
    final controller = _controller;
    if (controller == null) return;

    final score = controller.engine.session.score;
    await _applyRewards(success: true);

    if (!mounted) return;

    final isKingdom = widget.mode == BlockMode.kingdom;
    final isTimeTrial = widget.mode == BlockMode.timeTrial;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            isTimeTrial ? 'Time Trial Cleared' : 'Victory!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatChip(
                icon: Icons.workspace_premium_rounded,
                label: 'Final Score',
                value: '$score',
              ),
              const SizedBox(height: 10),
              _StatChip(
                icon: Icons.flag_rounded,
                label: isKingdom ? 'Level' : 'Challenge',
                value: '${controller.currentLevelNumber}',
              ),
              const SizedBox(height: 10),
              _StatChip(
                icon: Icons.card_giftcard_rounded,
                label: 'Reward',
                value: controller.rewardLabel,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('Exit'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (isKingdom) {
                  await _startNextKingdomLevel();
                } else {
                  await _restartSession();
                }
              },
              child: Text(isKingdom ? 'Next Level' : 'Play Again'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFailureDialog() async {
    final controller = _controller;
    if (controller == null) return;

    await _applyRewards(success: widget.mode == BlockMode.endless);

    if (!mounted) return;

    final score = controller.engine.session.score;
    final title = switch (widget.mode) {
      BlockMode.endless => 'Kingdom Full',
      BlockMode.kingdom => 'Level Missed',
      BlockMode.timeTrial => 'Time Trial Failed',
    };

    final subtitle = switch (widget.mode) {
      BlockMode.endless => 'The board is full. Ready for another run?',
      BlockMode.kingdom =>
      'You were close. Retry the level and keep the kingdom growing.',
      BlockMode.timeTrial =>
      'The clock won this one. Retry and finish before time runs out.',
    };

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              _StatChip(
                icon: Icons.emoji_events_rounded,
                label: 'Score',
                value: '$score',
              ),
              const SizedBox(height: 10),
              _StatChip(
                icon: Icons.flag_rounded,
                label: widget.mode == BlockMode.timeTrial
                    ? 'Challenge'
                    : widget.mode == BlockMode.kingdom
                    ? 'Level'
                    : 'Run',
                value: '${controller.currentLevelNumber}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('Exit'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _restartSession(
                  levelNumber: widget.mode == BlockMode.kingdom
                      ? controller.currentLevelNumber
                      : controller.currentLevelNumber,
                );
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _checkResolutionAndShowDialog() {
    final controller = _controller;
    if (controller == null || _dialogShown || _resolutionHandled) return;

    switch (controller.sessionOutcome) {
      case BlockSessionOutcome.none:
        return;
      case BlockSessionOutcome.success:
        _resolutionHandled = true;
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await PlayAccessService.instance.endGameplaySession(
            completedLevel: true,
          );
          await _showSuccessDialog();
          if (!mounted) return;
          controller.clearSessionOutcome();
          _dialogShown = false;
        });
        break;
      case BlockSessionOutcome.failure:
        _resolutionHandled = true;
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await PlayAccessService.instance.endGameplaySession(
            completedLevel: false,
          );
          await _showFailureDialog();
          if (!mounted) return;
          controller.clearSessionOutcome();
          _dialogShown = false;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBoardRectUpdate();

    if (_isPreparing || _controller == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B1220),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final controller = _controller!;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        _scheduleBoardRectUpdate();
        _consumeFeedback();
        _checkResolutionAndShowDialog();

        final draggingPiece = controller.draggingPiece;
        final dragCellSize = controller.dragVisualCellSize;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1220),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0B1220),
                  Color(0xFF111A2F),
                  Color(0xFF1A2340),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  const _AmbientParticles(),
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      BannerWidget(
                        primaryText: controller.banner,
                        secondaryText: controller.secondaryBanner,
                        color: controller.bannerColor,
                        score: controller.engine.session.score,
                        scorePulse: controller.scorePulse,
                        scoreGain: controller.lastScoreGain,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: BoardWidget(
                                key: _boardKey,
                                controller: controller,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                        child: TrayWidget(controller: controller),
                      ),
                    ],
                  ),
                  if (controller.showTimer)
                    TimeTrialOverlay(
                      timerText: controller.timerLabel,
                      isUrgent: controller.engine.session.remainingSeconds <= 10,
                    ),
                  ..._overlayEntries.map((e) => e.widget),
                  if (draggingPiece != null)
                    Positioned(
                      left: controller.dragLeft,
                      top: controller.dragTop,
                      child: IgnorePointer(
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 90),
                          curve: Curves.easeOutBack,
                          scale: 1.18,
                          child: Material(
                            color: Colors.transparent,
                            child: PieceWidget(
                              piece: draggingPiece,
                              cellSize: dragCellSize,
                              active: true,
                              opacity: 0.98,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverlayEntryData {
  final String id;
  final Widget widget;

  const _OverlayEntryData({
    required this.id,
    required this.widget,
  });
}

class _CelebrationTextEffect extends StatefulWidget {
  final Offset center;
  final String primaryText;
  final String secondaryText;
  final bool highlight;
  final int combo;

  const _CelebrationTextEffect({
    required this.center,
    required this.primaryText,
    required this.secondaryText,
    required this.highlight,
    required this.combo,
  });

  @override
  State<_CelebrationTextEffect> createState() => _CelebrationTextEffectState();
}

class _CelebrationTextEffectState extends State<_CelebrationTextEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _move;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _move = Tween<double>(begin: 10, end: -18).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.08).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accent;
    double scaleBoost = 1.0;

    if (widget.combo >= 5) {
      accent = const Color(0xFFFFE37A);
      scaleBoost = 1.4;
    } else if (widget.combo == 4) {
      accent = const Color(0xFF96FFD0);
      scaleBoost = 1.3;
    } else if (widget.combo == 3) {
      accent = const Color(0xFF6EE7FF);
      scaleBoost = 1.2;
    } else if (widget.combo == 2) {
      accent = const Color(0xFFFFD37A);
      scaleBoost = 1.1;
    } else {
      accent = widget.highlight
          ? const Color(0xFFFFE37A)
          : const Color(0xFFFFD37A);
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Positioned(
            left: widget.center.dx - 120,
            top: widget.center.dy + _move.value - 20,
            child: Opacity(
              opacity: 1 - (_controller.value * 0.15),
              child: Transform.scale(
                scale: _scale.value * scaleBoost,
                child: SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      Text(
                        widget.primaryText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accent,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: accent.withOpacity(0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      if (widget.secondaryText.isNotEmpty)
                        Text(
                          widget.secondaryText,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingScoreEffect extends StatefulWidget {
  final Offset position;
  final String text;
  final bool highlight;

  const _FloatingScoreEffect({
    required this.position,
    required this.text,
    required this.highlight,
  });

  @override
  State<_FloatingScoreEffect> createState() => _FloatingScoreEffectState();
}

class _FloatingScoreEffectState extends State<_FloatingScoreEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dy;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();

    _dy = Tween<double>(begin: 18, end: -16).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.highlight
        ? const Color(0xFFFFE37A)
        : const Color(0xFF84FFD2);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Positioned(
            left: widget.position.dx,
            top: widget.position.dy + _dy.value,
            child: Opacity(
              opacity: _fade.value,
              child: Text(
                widget.text,
                style: TextStyle(
                  color: color,
                  fontSize: widget.highlight ? 22 : 18,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AmbientParticles extends StatefulWidget {
  const _AmbientParticles();

  @override
  State<_AmbientParticles> createState() => _AmbientParticlesState();
}

class _AmbientParticlesState extends State<_AmbientParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_AmbientDot> _dots = List<_AmbientDot>.generate(
    20,
        (index) => _AmbientDot(
      seed: index + 1,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _AmbientParticlesPainter(
              dots: _dots,
              t: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _AmbientDot {
  final int seed;

  const _AmbientDot({required this.seed});

  double x(double t) => ((seed * 47) % 100) / 100;
  double y(double t) => ((((seed * 29) % 100) / 100) + (t * 0.08)) % 1.2;
  double radius() => 1.6 + (seed % 3) * 0.8;
  double opacity() => 0.08 + ((seed % 5) * 0.02);
}

class _AmbientParticlesPainter extends CustomPainter {
  final List<_AmbientDot> dots;
  final double t;

  const _AmbientParticlesPainter({
    required this.dots,
    required this.t,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final paint = Paint()
        ..color = const Color(0xFF9DD6FF).withOpacity(dot.opacity())
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final dx = dot.x(t) * size.width;
      final dy = dot.y(t) * size.height;
      canvas.drawCircle(Offset(dx, dy), dot.radius(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientParticlesPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFFFFD36B), size: 18),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}