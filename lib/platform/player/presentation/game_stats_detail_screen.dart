import 'package:flutter/material.dart';

import '../../../game_engine/catalog/game_registry.dart';
import '../models/game_player_stats.dart';
import '../services/player_stats_service.dart';

class GameStatsDetailScreen extends StatefulWidget {
  const GameStatsDetailScreen({
    super.key,
    required this.gameId,
  });

  final String gameId;

  @override
  State<GameStatsDetailScreen> createState() => _GameStatsDetailScreenState();
}

class _GameStatsDetailScreenState extends State<GameStatsDetailScreen> {
  late Future<GamePlayerStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = PlayerStatsService.instance.getStats(widget.gameId);
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = PlayerStatsService.instance.getStats(widget.gameId);
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final game = GameRegistry.get(widget.gameId);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(game.title),
      ),
      body: FutureBuilder<GamePlayerStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'Failed to load game stats.\n${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final stats = snapshot.data ?? GamePlayerStats.empty(widget.gameId);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _HeroCard(
                  title: game.title,
                  gameId: widget.gameId,
                  icon: game.icon,
                  color: game.color,
                  stats: stats,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightStatCard(
                        title: 'Best Score',
                        value: _formatNumber(stats.bestScore),
                        icon: Icons.stars_rounded,
                        color: const Color(0xFF5B67F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightStatCard(
                        title: 'Highest Level',
                        value: '${stats.highestLevel}',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightStatCard(
                        title: 'Games Played',
                        value: '${stats.gamesPlayed}',
                        icon: Icons.sports_esports_rounded,
                        color: const Color(0xFF14B8A6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightStatCard(
                        title: 'Total XP',
                        value: _formatNumber(stats.totalXp),
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Progress Snapshot',
                  subtitle: 'Your strongest milestones in this game.',
                ),
                const SizedBox(height: 12),
                _ProgressCard(
                  highestLevel: stats.highestLevel,
                  bestScore: stats.bestScore,
                  gamesPlayed: stats.gamesPlayed,
                  accentColor: game.color,
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Rewards Earned',
                  subtitle: 'Everything collected from this game so far.',
                ),
                const SizedBox(height: 12),
                _RewardsCard(
                  totalXp: stats.totalXp,
                  totalCoins: stats.totalCoins,
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Performance Summary',
                  subtitle: 'A clean breakdown of your overall activity.',
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  stats: stats,
                  accentColor: game.color,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _formatNumber(int value) {
    return value.toString();
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.gameId,
    required this.icon,
    required this.color,
    required this.stats,
  });

  final String title;
  final String gameId;
  final IconData icon;
  final Color color;
  final GamePlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final headline = _buildHeadline(stats);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            _shiftColor(color),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gameId,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.88),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            headline,
            style: const TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _buildSubheadline(stats),
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _buildHeadline(GamePlayerStats stats) {
    if (stats.gamesPlayed == 0) return 'Your journey starts here.';
    if (stats.highestLevel >= 25) return 'You are dominating this game.';
    if (stats.highestLevel >= 10) return 'Strong progress and climbing fast.';
    if (stats.gamesPlayed >= 5) return 'Momentum is building nicely.';
    return 'A promising start with growing momentum.';
  }

  String _buildSubheadline(GamePlayerStats stats) {
    if (stats.gamesPlayed == 0) {
      return 'Play a few rounds to unlock performance stats, rewards, and personal milestones.';
    }
    return 'Played ${stats.gamesPlayed} time${stats.gamesPlayed == 1 ? '' : 's'} • '
        'Reached level ${stats.highestLevel} • '
        'Best score ${stats.bestScore}';
  }

  Color _shiftColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final shifted = hsl.withHue((hsl.hue + 28) % 360).withLightness(
      (hsl.lightness + 0.06).clamp(0.0, 1.0),
    );
    return shifted.toColor();
  }
}

class _HighlightStatCard extends StatelessWidget {
  const _HighlightStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

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
            fontSize: 13.5,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.highestLevel,
    required this.bestScore,
    required this.gamesPlayed,
    required this.accentColor,
  });

  final int highestLevel;
  final int bestScore;
  final int gamesPlayed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final progressValue = highestLevel <= 0
        ? 0.0
        : (highestLevel / 50).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniProgressTile(
                  label: 'Highest Level',
                  value: '$highestLevel',
                  icon: Icons.flag_rounded,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniProgressTile(
                  label: 'Best Score',
                  value: '$bestScore',
                  icon: Icons.workspace_premium_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF14B8A6),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Level Progress Momentum',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Text(
                '${(progressValue * 100).round()}%',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            gamesPlayed == 0
                ? 'No completed sessions yet.'
                : 'You have already completed $gamesPlayed session${gamesPlayed == 1 ? '' : 's'} in this game.',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniProgressTile extends StatelessWidget {
  const _MiniProgressTile({
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsCard extends StatelessWidget {
  const _RewardsCard({
    required this.totalXp,
    required this.totalCoins,
  });

  final int totalXp;
  final int totalCoins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RewardTile(
              title: 'Total XP',
              value: '$totalXp',
              subtitle: 'Power gained',
              icon: Icons.bolt_rounded,
              color: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RewardTile(
              title: 'Total Coins',
              value: '$totalCoins',
              subtitle: 'Rewards earned',
              icon: Icons.monetization_on_rounded,
              color: const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.stats,
    required this.accentColor,
  });

  final GamePlayerStats stats;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final avgXp = stats.gamesPlayed == 0
        ? 0
        : (stats.totalXp / stats.gamesPlayed).round();
    final avgCoins = stats.gamesPlayed == 0
        ? 0
        : (stats.totalCoins / stats.gamesPlayed).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Games Played',
            value: '${stats.gamesPlayed}',
            icon: Icons.sports_esports_rounded,
            color: accentColor,
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Average XP per Session',
            value: '$avgXp',
            icon: Icons.bolt_rounded,
            color: const Color(0xFF22C55E),
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Average Coins per Session',
            value: '$avgCoins',
            icon: Icons.monetization_on_rounded,
            color: const Color(0xFFF59E0B),
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Highest Level Reached',
            value: '${stats.highestLevel}',
            icon: Icons.terrain_rounded,
            color: const Color(0xFF5B67F1),
          ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Best Score',
            value: '${stats.bestScore}',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}