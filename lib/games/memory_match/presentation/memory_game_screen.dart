import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../platform/play_access/domain/play_pause_message.dart';
import '../../../platform/play_access/presentation/widgets/animated_play_pause_message_card.dart';
import '../../../platform/play_access/presentation/widgets/game_break_overlay.dart';
import 'memory_game_view_model.dart';
import 'widgets/animated_counter.dart';
import 'widgets/memory_tile.dart';

class MemoryGameScreen extends StatelessWidget {
  const MemoryGameScreen({
    super.key,
    required this.worldId,
    required this.levelNumber,
  });

  final String worldId;
  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MemoryGameViewModel(
        worldId: worldId,
        levelNumber: levelNumber,
      )..initialize(),
      child: const _MemoryGameView(),
    );
  }
}

class _MemoryGameView extends StatelessWidget {
  const _MemoryGameView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemoryGameViewModel>();

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = vm.theme;
    final level = vm.level;
    final spacing = level.columns >= 8 ? 6.0 : 12.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text('${theme.worldTitle} • Level ${level.levelNumber}'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.tileGradientStart.withOpacity(0.16),
                        theme.tileGradientEnd.withOpacity(0.16),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _HudItem(
                              label: 'Moves',
                              value: '${vm.moves}',
                              icon: Icons.swap_horiz_rounded,
                              color: const Color(0xFF14B8A6),
                            ),
                          ),
                          Expanded(
                            child: _HudItem(
                              label: 'Matches',
                              value: '${vm.matchesFound}/${vm.totalPairs}',
                              icon: Icons.favorite_rounded,
                              color: const Color(0xFFEC4899),
                            ),
                          ),
                          Expanded(
                            child: _HudItem(
                              label: 'Time',
                              value: '${vm.secondsElapsed}s',
                              icon: Icons.timer_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          Expanded(
                            child: _AnimatedScoreCard(
                              value: vm.score,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _LevelTag(
                              label: vm.specialLevelLabel,
                              icon: Icons.auto_awesome_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _LevelTag(
                              label: vm.comboCount > 1
                                  ? 'Combo ${vm.comboCount}x'
                                  : 'Combo Ready',
                              icon: Icons.local_fire_department_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (vm.isParentControlEnabled)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_clock_rounded,
                          color: Color(0xFF5B67F1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Parent mode: ${vm.tokensRemaining} token${vm.tokensRemaining == 1 ? '' : 's'} available',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (vm.isPreviewing)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7D6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.visibility_rounded,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            level.isMemoryProLevel
                                ? 'Memory Pro: memorize quickly.'
                                : 'Memorize the tiles before they flip back.',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!vm.isPreviewing && level.isSpeedLevel)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Speed Level: no preview, trust your memory!',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: vm.cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: level.columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final card = vm.cards[index];
                        return MemoryTile(
                          key: ValueKey(card.id),
                          card: card,
                          themePack: theme,
                          isWrong: vm.isWrongCard(card.id),
                          isJustMatched: vm.isJustMatchedCard(card.id),
                          onTap: () => vm.onTapCard(index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            IgnorePointer(
              ignoring: true,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 112),
                  child: _FloatingPoints(
                    tick: vm.pointsBurstTick,
                    points: vm.lastPointsAward,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: true,
              child: _ReactionOverlay(
                tick: vm.reactionTick,
                reaction: vm.reaction,
              ),
            ),
            if (vm.showSoftPauseReminder && vm.softPauseMessage != null)
              Positioned(
                left: 16,
                right: 16,
                top: 110,
                child: AnimatedPlayPauseMessageCard(
                  message: vm.softPauseMessage!,
                  primaryActionLabel: 'Got it',
                  onPrimaryAction: vm.dismissSoftPauseReminder,
                  showClose: true,
                  onClose: vm.dismissSoftPauseReminder,
                ),
              ),
            if (vm.isLevelLocked)
              GameBreakOverlay(
                seed: vm.pauseMessageSeed,
                isBreakRequired: false,
                onPrimaryAction: () => vm.requestUnlockFromParent(),
                onSecondaryAction: () => Navigator.of(context).pop(),
              ),
            if (vm.isCompleted)
              _CelebrationOverlay(
                playerName: vm.playerProfile?.displayName ?? 'Champion',
                levelNumber: vm.level.levelNumber,
                stars: vm.earnedStars,
                score: vm.score,
                moves: vm.moves,
                coins: vm.coinsEarned,
                xp: vm.xpEarned,
                rewardAnimationTick: vm.rewardAnimationTick,
                onContinue: () => Navigator.of(context).pop(true),
              ),
          ],
        ),
      ),
    );
  }
}

class _HudItem extends StatelessWidget {
  const _HudItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            value,
            key: ValueKey(value),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelTag extends StatelessWidget {
  const _LevelTag({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5B67F1)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedScoreCard extends StatelessWidget {
  const _AnimatedScoreCard({
    required this.value,
  });

  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.stars_rounded,
          size: 20,
          color: Color(0xFF5B67F1),
        ),
        const SizedBox(height: 6),
        const Text(
          'Points',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.75, end: 1).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: Text(
            '$value',
            key: ValueKey(value),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Color(0xFF5B67F1),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingPoints extends StatelessWidget {
  const _FloatingPoints({
    required this.tick,
    required this.points,
  });

  final int tick;
  final int points;

  @override
  Widget build(BuildContext context) {
    if (tick == 0 || points <= 0) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey(tick),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, value, child) {
        final opacity = (1 - value).clamp(0.0, 1.0);
        final dy = value * 36;

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, -dy),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF5B67F1),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x225B67F1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '+$points',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReactionOverlay extends StatelessWidget {
  const _ReactionOverlay({
    required this.tick,
    required this.reaction,
  });

  final int tick;
  final MemoryReactionData? reaction;

  @override
  Widget build(BuildContext context) {
    if (reaction == null) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 170),
        child: TweenAnimationBuilder<double>(
          key: ValueKey(tick),
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 850),
          builder: (context, value, child) {
            final opacity = (1 - value).clamp(0.0, 1.0);
            final dy = value * 42;
            final scale = 0.85 + (0.20 * (1 - value));

            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -dy),
                child: Transform.rotate(
                  angle: (value - 0.5) * 0.05,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 120,
                        maxWidth: 260,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            reaction!.color,
                            reaction!.color.withOpacity(0.82),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: reaction!.color.withOpacity(0.30),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        '${reaction!.emoji} ${reaction!.text}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CelebrationOverlay extends StatefulWidget {
  const _CelebrationOverlay({
    required this.playerName,
    required this.levelNumber,
    required this.stars,
    required this.score,
    required this.moves,
    required this.coins,
    required this.xp,
    required this.rewardAnimationTick,
    required this.onContinue,
  });

  final String playerName;
  final int levelNumber;
  final int stars;
  final int score;
  final int moves;
  final int coins;
  final int xp;
  final int rewardAnimationTick;
  final VoidCallback onContinue;

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _cardScale;
  late final Animation<double> _trophyScale;
  late final Animation<double> _fade;
  late final List<_ConfettiDot> _dots;

  @override
  void initState() {
    super.initState();
    _dots = List.generate(18, (i) => _ConfettiDot.seeded(i));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _cardScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _trophyScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final praiseMessages = [
      'Amazing memory!',
      'Fantastic job!',
      'You nailed it!',
      'Brilliant match!',
      'YAY!!!!!!!!',
      'HURRRRRRAYYYYYYY!',
      'What a smart play!',
    ];
    final praise = praiseMessages[
    (widget.levelNumber + widget.stars + widget.moves) %
        praiseMessages.length];

    return Material(
      color: Colors.black.withOpacity(0.35),
      child: Stack(
        children: [
          ..._dots.map(
                (dot) => AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = _controller.value;
                return Positioned(
                  left: dot.left + (dot.dx * progress),
                  top: dot.top + (dot.dy * progress),
                  child: Opacity(
                    opacity: (1 - progress * 0.7).clamp(0, 1),
                    child: Transform.rotate(
                      angle: progress * 5,
                      child: Container(
                        width: dot.size,
                        height: dot.size,
                        decoration: BoxDecoration(
                          color: dot.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _cardScale,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x24000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _trophyScale,
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFF1B2),
                                Colors.orange.shade300,
                              ],
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33F59E0B),
                                blurRadius: 18,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            size: 54,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '🎉 ${widget.playerName} completed Level ${widget.levelNumber}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        praise,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                              (index) => TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.4,
                              end: index < widget.stars ? 1 : 0.8,
                            ),
                            duration:
                            Duration(milliseconds: 350 + (index * 120)),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Padding(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(
                                    index < widget.stars
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 34,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _MiniResultStat(
                                  icon: Icons.stars_rounded,
                                  value: '${widget.score}',
                                  label: 'Points',
                                  color: const Color(0xFF5B67F1),
                                ),
                                _MiniResultStat(
                                  icon: Icons.swap_horiz_rounded,
                                  value: '${widget.moves}',
                                  label: 'Moves',
                                  color: const Color(0xFF14B8A6),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedCounter(
                                  key: ValueKey(
                                    'coins_${widget.rewardAnimationTick}_${widget.coins}',
                                  ),
                                  label: 'Coins',
                                  value: widget.coins,
                                  icon: Icons.monetization_on_rounded,
                                  color: const Color(0xFFF59E0B),
                                  prefix: '+',
                                ),
                                const SizedBox(width: 10),
                                AnimatedCounter(
                                  key: ValueKey(
                                    'xp_${widget.rewardAnimationTick}_${widget.xp}',
                                  ),
                                  label: 'XP',
                                  value: widget.xp,
                                  icon: Icons.bolt_rounded,
                                  color: const Color(0xFF22C55E),
                                  prefix: '+',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: widget.onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5B67F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Continue Adventure 🚀',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MiniResultStat extends StatelessWidget {
  const _MiniResultStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _ConfettiDot {
  const _ConfettiDot({
    required this.left,
    required this.top,
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
  });

  final double left;
  final double top;
  final double dx;
  final double dy;
  final double size;
  final Color color;

  factory _ConfettiDot.seeded(int i) {
    final colors = [
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF22C55E),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
    ];

    return _ConfettiDot(
      left: 40 + ((i * 17) % 280).toDouble(),
      top: 100 + ((i * 13) % 180).toDouble(),
      dx: ((i % 5) - 2) * 18.0,
      dy: 160 + ((i % 4) * 24).toDouble(),
      size: 8 + (i % 5).toDouble(),
      color: colors[i % colors.length],
    );
  }
}