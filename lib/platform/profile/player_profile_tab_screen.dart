import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/home/home_view_model.dart';
import '../../app/routing/route_names.dart';
import '../../platform/player/presentation/player_stats_screen.dart';

class PlayerProfileTabScreen extends StatelessWidget {
  const PlayerProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = vm.profile;
        if (profile == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                vm.errorMessage ?? 'Profile not available.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final initials = _buildInitials(profile.displayName);
        final otpDestination = profile.preferredOtpDestination;

        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3158FF), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x443158FF),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white.withOpacity(0.16),
                      backgroundImage: profile.photoUrl.trim().isNotEmpty
                          ? NetworkImage(profile.photoUrl)
                          : null,
                      child: profile.photoUrl.trim().isEmpty
                          ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile.displayName.trim().isEmpty
                          ? 'Player'
                          : profile.displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      otpDestination.isEmpty
                          ? 'No approval portal linked'
                          : 'Approval portal: $otpDestination',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: otpDestination.isEmpty
                            ? const Color(0xFFFECACA)
                            : Colors.white.withOpacity(0.92),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroMiniStat(
                            title: 'Coins',
                            value: '${profile.coins}',
                            icon: Icons.monetization_on_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroMiniStat(
                            title: 'XP',
                            value: '${profile.xp}',
                            icon: Icons.bolt_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroMiniStat(
                            title: 'Streak',
                            value: '${profile.streakDays}',
                            icon: Icons.local_fire_department_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _CreatorSummaryCard(uid: profile.uid),
              const SizedBox(height: 18),
              const _SectionTitle(
                title: '⚡ Creator Hub',
                subtitle:
                'Launch builds, track your rise, and level up your legend.',
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.folder_copy_rounded,
                title: 'My Projects',
                subtitle:
                'Check drafts, approvals, and all your custom game builds.',
                onTap: () {
                  Navigator.pushNamed(context, RouteNames.myProjects);
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.bar_chart_rounded,
                title: 'Player Stats',
                subtitle:
                'Track XP, streaks, battles played, and your overall rise.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                      ChangeNotifierProvider<HomeViewModel>.value(
                        value: vm,
                        child: const PlayerStatsScreen(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
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

class _CreatorSummaryCard extends StatelessWidget {
  const _CreatorSummaryCard({
    required this.uid,
  });

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('custom_games')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];

        int totalProjects = docs.length;
        int approved = 0;
        int totalBattles = 0;
        int totalCheers = 0;

        for (final doc in docs) {
          final data = doc.data();
          if ((data['status'] ?? '') == 'approved') {
            approved += 1;
          }
          totalBattles += (data['playCount'] as num?)?.toInt() ?? 0;
          totalCheers += (data['likesCount'] as num?)?.toInt() ?? 0;
        }

        final List<String> badges = <String>[];
        if (approved >= 1) badges.add('First Published');
        if (totalBattles >= 5) badges.add('On Fire');
        if (totalCheers >= 3) badges.add('Crowd Favorite');

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF161A2D),
                Color(0xFF0F1324),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2A3160)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🏆 Creator Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your build journey inside the GameBox arena.',
                style: TextStyle(
                  color: Color(0xFFB9C0FF),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      title: 'Builds',
                      value: '$totalProjects',
                      icon: Icons.folder_copy_rounded,
                      color: const Color(0xFF7C9BFF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      title: 'Approved',
                      value: '$approved',
                      icon: Icons.verified_rounded,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      title: 'Battles',
                      value: '$totalBattles',
                      icon: Icons.sports_martial_arts_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      title: 'Cheers',
                      value: '$totalCheers',
                      icon: Icons.bolt_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Unlocked Badges',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              if (badges.isEmpty)
                const Text(
                  'Publish your first approved build to unlock neon badges.',
                  style: TextStyle(
                    color: Color(0xFFB9C0FF),
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: badges
                      .map(
                        (badge) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF232A56),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF3A46A5),
                        ),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Color(0xFFD8DEFF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroMiniStat extends StatelessWidget {
  const _HeroMiniStat({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171D39),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2F386C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFB9C0FF),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF161A2D),
              Color(0xFF101425),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2A3160)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: Colors.white,
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
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFB9C0FF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFFD8DEFF),
            ),
          ],
        ),
      ),
    );
  }
}