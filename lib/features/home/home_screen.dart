import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/enums/app_mode.dart';
import '../../core/models/daily_mission.dart';
import '../../core/models/game_tile_model.dart';
import '../../core/models/player_profile.dart';
import '../auth/google_sign_in_service.dart';
import '../games/game_routes.dart';
import 'home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await GoogleSignInService.instance.signOut();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel()..initialize(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FC),
        appBar: AppBar(
          title: const Text('GameBox'),
          actions: [
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (vm.errorMessage != null && vm.profile == null) {
                return _ErrorState(
                  message: vm.errorMessage!,
                  onRetry: vm.initialize,
                );
              }

              final profile = vm.profile;
              if (profile == null) {
                return _ErrorState(
                  message: 'Profile not found.',
                  onRetry: vm.initialize,
                );
              }

              return RefreshIndicator(
                onRefresh: vm.refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    _ProfileHeroCard(profile: profile),
                    const SizedBox(height: 16),
                    _ModeBanner(
                      mode: vm.currentMode,
                      onLearnMore: () => _showModeInfo(context),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Coins',
                            value: '${profile.coins}',
                            icon: Icons.monetization_on_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Level',
                            value: '${profile.level}',
                            icon: Icons.emoji_events_rounded,
                            color: const Color(0xFF5B67F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Streak',
                            value: '${profile.streakDays} day',
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Games',
                            value: '${profile.gamesPlayed}',
                            icon: Icons.sports_esports_rounded,
                            color: const Color(0xFF14B8A6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _XpCard(
                      xp: profile.xp,
                      level: profile.level,
                      progress: vm.xpProgress,
                    ),
                    const SizedBox(height: 16),
                    _DailyRewardCard(
                      canClaim: vm.canClaimDailyReward,
                      isClaiming: vm.isClaimingReward,
                      onClaim: vm.claimDailyReward,
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Daily Missions',
                      subtitle: 'Play and grow your rewards every day.',
                    ),
                    const SizedBox(height: 12),
                    ...vm.missions.map(_MissionCard.new),
                    const SizedBox(height: 20),
                    const _SectionTitle(
                      title: 'Featured Games',
                      subtitle: 'Start playing instantly in Normal Mode.',
                    ),
                    const SizedBox(height: 12),
                    ...vm.games.map(
                          (game) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _GameCard(
                          game: game,
                          onTap: () async {
                            if (game.isLocked || game.routeName.isEmpty) return;
                            final result = await Navigator.of(context).pushNamed(
                              game.routeName,
                            );
                            if (result == true) {
                              await vm.refresh();
                            }
                          },
                        ),
                      ),
                    ),
                    if (vm.errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        vm.errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showModeInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'GameBox Modes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const _ModeListTile(
                  title: 'Normal Mode',
                  subtitle: 'Default now. Play freely with light reminders.',
                  color: Color(0xFF5B67F1),
                  icon: Icons.sports_esports_rounded,
                ),
                const SizedBox(height: 10),
                const _ModeListTile(
                  title: 'Guided Mode',
                  subtitle: 'Coming later with rewards for healthy habits.',
                  color: Color(0xFF14B8A6),
                  icon: Icons.lightbulb_rounded,
                ),
                const SizedBox(height: 10),
                const _ModeListTile(
                  title: 'Premium Parent Mode',
                  subtitle: 'Coming later with family controls and reports.',
                  color: Color(0xFFF59E0B),
                  icon: Icons.family_restroom_rounded,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B67F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
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

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(profile.displayName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B67F1), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.18),
            backgroundImage:
            profile.photoUrl.trim().isNotEmpty ? NetworkImage(profile.photoUrl) : null,
            child: profile.photoUrl.trim().isEmpty
                ? Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, ${profile.displayName}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ready to play and grow today?',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.white.withOpacity(0.92),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _ModeBanner extends StatelessWidget {
  const _ModeBanner({
    required this.mode,
    required this.onLearnMore,
  });

  final AppMode mode;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF5B67F1).withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF5B67F1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mode.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mode.subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onLearnMore,
            child: const Text('See all'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  const _XpCard({
    required this.xp,
    required this.level,
    required this.progress,
  });

  final int xp;
  final int level;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final nextLevelXp = level * 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF5B67F1),
              ),
              const SizedBox(width: 8),
              Text(
                'XP Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$xp / $nextLevelXp',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF5B67F1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRewardCard extends StatelessWidget {
  const _DailyRewardCard({
    required this.canClaim,
    required this.isClaiming,
    required this.onClaim,
  });

  final bool canClaim;
  final bool isClaiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7D6), Color(0xFFFFF1B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: Color(0xFFF59E0B),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reward',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Claim +25 coins and +15 XP once every day.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: canClaim && !isClaiming ? onClaim : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isClaiming
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.white,
                ),
              )
                  : Text(
                canClaim ? 'Claim' : 'Claimed',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard(this.mission);

  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF14B8A6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (mission.isCompleted)
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF22C55E),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              height: 1.4,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: mission.progressValue,
              minHeight: 10,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF14B8A6)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${mission.progress}/${mission.target}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              Text(
                '+${mission.rewardCoins} coins • +${mission.rewardXp} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5B67F1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.onTap,
  });

  final GameTileModel game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: game.isLocked ? 0.65 : 1,
      child: InkWell(
        onTap: game.isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: game.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  game.icon,
                  color: game.color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: game.isLocked
                      ? const Color(0xFFE5E7EB)
                      : game.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  game.isLocked ? 'Locked' : 'Play',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: game.isLocked ? const Color(0xFF6B7280) : game.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeListTile extends StatelessWidget {
  const _ModeListTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13.2,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              size: 42,
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