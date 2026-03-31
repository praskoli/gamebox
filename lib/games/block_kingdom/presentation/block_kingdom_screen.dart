import 'package:flutter/material.dart';

import '../../../platform/audio/sound_service.dart';
import '../../../platform/player/services/player_stats_service.dart';
import '../../../platform/profile/services/profile_service.dart';
import 'controller/block_controller.dart';
import 'effects/block_place_effect.dart';
import 'effects/line_clear_sweep_effect.dart';
import 'widgets/banner_widget.dart';
import 'widgets/board_widget.dart';
import 'widgets/piece_widget.dart';
import 'widgets/tray_widget.dart';

class BlockKingdomScreen extends StatefulWidget {
  const BlockKingdomScreen({super.key});

  @override
  State<BlockKingdomScreen> createState() => _BlockKingdomScreenState();
}

class _BlockKingdomScreenState extends State<BlockKingdomScreen> {
  final BlockController controller = BlockController();
  final GlobalKey _boardKey = GlobalKey();

  bool _rewarded = false;
  bool _dialogShown = false;
  int _lastFeedbackVersion = 0;

  final List<_OverlayEntryData> _overlayEntries = <_OverlayEntryData>[];

  @override
  void initState() {
    super.initState();
    controller.start();
    SoundService.instance.playGameStart();
  }

  Future<void> _handleGameOver() async {
    if (_rewarded) return;
    _rewarded = true;

    final score = controller.engine.session.score;
    final xp = (score ~/ 10).clamp(5, 999999);
    final coins = (score ~/ 5).clamp(3, 999999);

    try {
      await ProfileService.instance.addGameCompletionRewards(
        coins: coins,
        xp: xp,
      );

      await PlayerStatsService.instance.recordGameCompletion(
        gameId: 'block_kingdom',
        xp: xp,
        coins: coins,
        levelNumber: 1,
        score: score,
      );
    } catch (_) {
      // Keep gameplay stable even if writes fail.
    }
  }

  void _scheduleBoardRectUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _boardKey.currentContext;
      if (ctx == null) return;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;

      final offset = box.localToGlobal(Offset.zero);
      controller.attachBoardRect(offset & box.size);
    });
  }

  void _checkGameOverAndShowDialog() {
    if (!controller.engine.session.isGameOver || _dialogShown) return;

    _dialogShown = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _handleGameOver();
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final score = controller.engine.session.score;
          final xp = (score ~/ 10).clamp(5, 999999);
          final coins = (score ~/ 5).clamp(3, 999999);

          return AlertDialog(
            backgroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Kingdom Full',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatChip(
                  icon: Icons.emoji_events_rounded,
                  label: 'Final Score',
                  value: '$score',
                ),
                const SizedBox(height: 10),
                _StatChip(
                  icon: Icons.bolt_rounded,
                  label: 'XP Earned',
                  value: '+$xp',
                ),
                const SizedBox(height: 10),
                _StatChip(
                  icon: Icons.monetization_on_rounded,
                  label: 'Coins Earned',
                  value: '+$coins',
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
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.restart();
                  _rewarded = false;
                  _dialogShown = false;
                  _lastFeedbackVersion = 0;
                  _overlayEntries.clear();
                  SoundService.instance.playGameStart();
                },
                child: const Text('Play Again'),
              ),
            ],
          );
        },
      );
    });
  }

  void _consumeFeedback() {
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
            position: Offset(rect.right - 90, rect.top + 12),
            text: '+${feedback.scoreGain}',
            highlight: feedback.crossedMilestone,
          ),
        ),
      );
    }

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _overlayEntries.clear();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleBoardRectUpdate();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        _scheduleBoardRectUpdate();
        _consumeFeedback();
        _checkGameOverAndShowDialog();

        final draggingPiece = controller.draggingPiece;
        final dragCellSize = controller.dragVisualCellSize;

        return Scaffold(
          backgroundColor: const Color(0xFF07090F),
          body: SafeArea(
            child: Stack(
              children: [
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