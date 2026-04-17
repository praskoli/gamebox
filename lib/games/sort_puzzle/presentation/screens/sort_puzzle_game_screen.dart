import 'package:flutter/material.dart';
import '../../../../platform/audio/sound_service.dart';
import '../../domain/sort_level.dart';
import '../../domain/sort_puzzle_scoring.dart';
import '../../domain/sort_puzzle_variant.dart';
import '../../engine/sort_puzzle_engine_impl.dart';
import '../controller/sort_puzzle_controller.dart';
import '../views/ball_sort_game_view.dart';
import '../views/bird_sort_game_view.dart';
import '../views/color_sort_game_view.dart';
import '../views/sand_sort_game_view.dart';
import '../views/water_sort_game_view.dart';

class SortPuzzleGameScreen extends StatefulWidget {
  const SortPuzzleGameScreen({
    super.key,
    required this.level,
  });

  final SortLevel level;

  @override
  State<SortPuzzleGameScreen> createState() => _SortPuzzleGameScreenState();
}

class _SortPuzzleGameScreenState extends State<SortPuzzleGameScreen> {
  late final SortPuzzleController _controller;

  bool _winSheetShown = false;
  bool _failSheetShown = false;

  @override
  void initState() {
    super.initState();
    _controller = SortPuzzleController(
      engine: const SortPuzzleEngineImpl(),
      level: widget.level,
    )..initialize();
  }

  @override
  void dispose() {
    _controller.disposeSession();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        if (!_controller.isSolved) {
          _winSheetShown = false;
        }

        if (!_controller.isMoveLimitReached && !_controller.isTimeExpired) {
          _failSheetShown = false;
        }

        if (_controller.isBlocked) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_controller.blockMessage ?? 'Play blocked'),
                ),
              ),
            ),
          );
        }

        _handleSolvedState(context);
        _handleFailedState(context);

        switch (widget.level.variant) {
          case SortPuzzleVariant.bird:
            return BirdSortGameView(
              level: widget.level,
              controller: _controller,
            );
          case SortPuzzleVariant.ball:
            return BallSortGameView(
              level: widget.level,
              controller: _controller,
            );
          case SortPuzzleVariant.color:
            return ColorSortGameView(
              level: widget.level,
              controller: _controller,
            );
          case SortPuzzleVariant.water:
            return WaterSortGameView(
              level: widget.level,
              controller: _controller,
            );
          case SortPuzzleVariant.sand:
            return SandSortGameView(
              level: widget.level,
              controller: _controller,
            );
        }
      },
    );
  }

  int _earnedStars() {
    return SortPuzzleScoring.calculateStars(
      level: widget.level,
      moveCount: _controller.session.moveCount,
      elapsed: _controller.session.elapsed,
      solved: _controller.isSolved,
    );
  }

  void _handleSolvedState(BuildContext context) {
    final bool shouldShow =
        _controller.isSolved &&
            _controller.session.moveCount > 0 &&
            !_winSheetShown;

    if (!shouldShow) return;

    _winSheetShown = true;
    final int stars = _earnedStars();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Puzzle Complete',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.level.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Moves: ${_controller.session.moveCount}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time: ${_formatDuration(_controller.session.elapsed)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(
                        3,
                            (int index) => Padding(
                          padding: EdgeInsets.only(right: index == 2 ? 0 : 4),
                          child: Icon(
                            index < stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFFFC93C),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(this.context).pop(stars);
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _handleFailedState(BuildContext context) {
    final bool failed = !_controller.isSolved &&
        (_controller.isMoveLimitReached || _controller.isTimeExpired);

    if (!failed || _failSheetShown) return;

    _failSheetShown = true;

    SoundService.instance.playGameOver();

    final bool moveFailed = _controller.isMoveLimitReached;
    final String title = moveFailed ? 'Out of Moves' : 'Time’s Up';
    final String subtitle = moveFailed
        ? 'You reached the move limit before completing the puzzle.'
        : 'The timer ended before the puzzle was completed.';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      moveFailed ? Icons.flag_rounded : Icons.timer_off_rounded,
                      color: const Color(0xFFFF8A16),
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Moves: ${_controller.session.moveCount}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time: ${_formatDuration(_controller.session.elapsed)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(this.context).pop();
                            },
                            child: const Text('Back'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _controller.restart();
                            },
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (mounted &&
          !_controller.isMoveLimitReached &&
          !_controller.isTimeExpired) {
        _failSheetShown = false;
      }
    });
  }

  String _formatDuration(Duration d) {
    final String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}