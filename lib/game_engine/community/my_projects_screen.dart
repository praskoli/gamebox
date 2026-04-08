import 'package:flutter/material.dart';

import '../../features/memory_match/data/memory_diy_repository.dart';
import '../../games/memory_match/domain/memory_diy_game_config.dart';

class MyProjectsScreen extends StatelessWidget {
  const MyProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF6F7FF),
              Color(0xFFF3F0FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<List<MemoryDiyGameConfig>>(
          stream: MemoryDiyRepository.instance.watchDrafts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Project hub failed to load:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final items = snapshot.data!;

            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _HeroCard(),
                  SizedBox(height: 18),
                  _EmptyProjectsCard(),
                ],
              );
            }

            final draft = items.where((e) => e.isDraft).toList();
            final pending = items.where((e) => e.isPendingReview).toList();
            final approved = items.where((e) => e.isApproved).toList();
            final rejected = items.where((e) => e.isRejected).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _HeroCard(),
                const SizedBox(height: 18),
                _QuickStatsRow(
                  total: items.length,
                  drafts: draft.length,
                  approved: approved.length,
                  pending: pending.length,
                ),
                const SizedBox(height: 18),
                _Section(
                  title: '⚡ Draft Zone',
                  subtitle: 'Shape your next hit before launch.',
                  items: draft,
                  accent: const Color(0xFF5B67F1),
                  emptyLabel: 'No drafts waiting in your lab.',
                ),
                _Section(
                  title: '🚀 Under Review',
                  subtitle: 'Your builds are waiting for arena approval.',
                  items: pending,
                  accent: const Color(0xFFF59E0B),
                  emptyLabel: 'Nothing is under review right now.',
                ),
                _Section(
                  title: '🏆 Live in Arena',
                  subtitle: 'These builds are already out in the wild.',
                  items: approved,
                  accent: const Color(0xFF22C55E),
                  emptyLabel: 'No approved arena builds yet.',
                ),
                _Section(
                  title: '🛠 Needs Rework',
                  subtitle: 'Tune these builds and send them back stronger.',
                  items: rejected,
                  accent: const Color(0xFFEF4444),
                  emptyLabel: 'No rejected builds. Nice work.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3158FF),
            Color(0xFF9333EA),
          ],
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
      child: const Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '🎮 Build Vault\nTrack your drafts, launches, and creator journey.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.total,
    required this.drafts,
    required this.approved,
    required this.pending,
  });

  final int total;
  final int drafts;
  final int approved;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: 'Builds',
            value: '$total',
            color: const Color(0xFF5B67F1),
            icon: Icons.grid_view_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Drafts',
            value: '$drafts',
            color: const Color(0xFF7C3AED),
            icon: Icons.edit_note_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Live',
            value: '$approved',
            color: const Color(0xFF22C55E),
            icon: Icons.verified_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniStatCard(
            label: 'Review',
            value: '$pending',
            color: const Color(0xFFF59E0B),
            icon: Icons.hourglass_top_rounded,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF161A2D),
            Color(0xFF101425),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2A3160)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB9C0FF),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.accent,
    required this.emptyLabel,
  });

  final String title;
  final String subtitle;
  final List<MemoryDiyGameConfig> items;
  final Color accent;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            _EmptySectionCard(
              label: emptyLabel,
              accent: accent,
            )
          else
            ...items.map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProjectCard(
                  config: e,
                  accent: accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.config,
    required this.accent,
  });

  final MemoryDiyGameConfig config;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final statusText = _statusLabel(config);
    final badgeLabel = _badgeLabel(config);
    final icon = _statusIcon(config);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF161A2D),
            Color(0xFF101425),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent,
                    accent.withOpacity(0.72),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
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
                    config.title.isEmpty ? 'Untitled Build' : config.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoPill(
                        label: '${config.gridColumns} x ${config.gridRows}',
                        icon: Icons.grid_view_rounded,
                      ),
                      _InfoPill(
                        label: statusText,
                        icon: Icons.verified_rounded,
                      ),
                      _InfoPill(
                        label: badgeLabel,
                        icon: Icons.bolt_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _statusMessage(config),
                    style: const TextStyle(
                      color: Color(0xFFB9C0FF),
                      fontWeight: FontWeight.w700,
                      height: 1.35,
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

  String _statusLabel(MemoryDiyGameConfig config) {
    if (config.isDraft) return 'Draft';
    if (config.isPendingReview) return 'Review';
    if (config.isApproved) return 'Live';
    if (config.isRejected) return 'Rework';
    return config.status;
  }

  String _badgeLabel(MemoryDiyGameConfig config) {
    if (config.isDraft) return 'In Lab';
    if (config.isPendingReview) return 'Queued';
    if (config.isApproved) return 'Arena Ready';
    if (config.isRejected) return 'Tune Up';
    return 'Custom';
  }

  IconData _statusIcon(MemoryDiyGameConfig config) {
    if (config.isDraft) return Icons.edit_note_rounded;
    if (config.isPendingReview) return Icons.hourglass_top_rounded;
    if (config.isApproved) return Icons.rocket_launch_rounded;
    if (config.isRejected) return Icons.build_circle_rounded;
    return Icons.extension_rounded;
  }

  String _statusMessage(MemoryDiyGameConfig config) {
    if (config.isDraft) {
      return 'Your build is still cooking. Polish it and launch when ready.';
    }
    if (config.isPendingReview) {
      return 'This one is waiting for approval before it enters the arena.';
    }
    if (config.isApproved) {
      return 'Live in the arena. Time to earn cheers and climb the ranks.';
    }
    if (config.isRejected) {
      return 'Needs another pass. Rework it and send it back stronger.';
    }
    return 'Custom build ready.';
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171D39),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF2F386C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFFCCD3FF)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProjectsCard extends StatelessWidget {
  const _EmptyProjectsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF161A2D),
            Color(0xFF101425),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A3160)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF7DA2FF),
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'No builds in your vault yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first custom game and start your rise in the arena.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB9C0FF),
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}