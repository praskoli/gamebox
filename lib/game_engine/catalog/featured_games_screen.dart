import 'package:flutter/material.dart';

import '../../games/block_kingdom/domain/block_mode.dart';
import '../../platform/play_access/data/play_access_service.dart';
import '../catalog/game_registry.dart';
import '../services/game_launcher.dart';
import '../ui/block_mode_selection_sheet.dart';
import '../ui/play_access_gate_sheet.dart';
class FeaturedGamesScreen extends StatelessWidget {
  const FeaturedGamesScreen({super.key});

  Future<void> _handleGameTap(
      BuildContext context,
      String gameId,
      ) async {
    await PlayAccessService.instance.initialize();

    final guardResult = await PlayAccessService.instance.canStartPlay(
      gameId: gameId,
    );

    if (guardResult.shouldWarn || !guardResult.canStart) {
      final gatePassed = await PlayAccessGateSheet.show(
        context: context,
        gameId: gameId,
        levelNumber: 1,
        guardResult: guardResult,
      );

      if (!gatePassed) return;
    }

    if (!context.mounted) return;

    if (gameId == 'block_kingdom') {
      final mode = await BlockModeSelectionSheet.show(context);
      if (mode == null || !context.mounted) return;

      await GameLauncher.launch(
        context,
        gameId,
        blockMode: mode,
      );
      return;
    }

    await GameLauncher.launch(
      context,
      gameId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = GameRegistry.getAll();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        const _HeaderCard(),
        const SizedBox(height: 20),
        const _SectionTitle(
          title: 'Featured Games',
          subtitle:
          'Pick a polished challenge, unlock rewards, and flow through safe parent-approved game sessions.',
        ),
        const SizedBox(height: 12),
        ...games.map(
              (game) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _GameCard(
              gameId: game.id,
              title: game.title,
              icon: game.icon,
              color: game.color,
              onTap: () => _handleGameTap(context, game.id),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final String gameId;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.gameId,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  bool get _isBlockKingdom => gameId == 'block_kingdom';
  bool get _isSortPuzzle => gameId == 'sort_puzzle';
  @override
  Widget build(BuildContext context) {
    final accent2 = HSLColor.fromColor(color)
        .withLightness((HSLColor.fromColor(color).lightness + 0.08).clamp(0, 1))
        .toColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.10),
              accent2.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: color.withOpacity(0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_isBlockKingdom || _isSortPuzzle)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _isBlockKingdom ? '3 Modes' : '5 Variants',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: color,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isBlockKingdom
                        ? 'Kingdom, Endless, and Time Trial in one polished block adventure.'
                        : _isSortPuzzle
                        ? 'Play Bird, Ball, Color, Water, and Sand sorting challenges in one game.'
                        : 'Jump in instantly, play smoothly, and grow your player rewards.',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13.6,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isBlockKingdom
                        ? 'Choose'
                        : _isSortPuzzle
                        ? 'Sort'
                        : 'Play',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: color,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9), Color(0xFF5B67F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.sports_esports_rounded, color: Colors.white, size: 34),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pick a featured game and jump into a polished, reward-ready session.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeaderChip(
                icon: Icons.verified_rounded,
                label: 'Safe Access Flow',
              ),
              _HeaderChip(
                icon: Icons.workspace_premium_rounded,
                label: 'Gamified Modes',
              ),
              _HeaderChip(
                icon: Icons.bolt_rounded,
                label: 'XP + Coins',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13.5,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}