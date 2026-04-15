import 'package:flutter/material.dart';

import '../../features/memory_match/data/memory_diy_repository.dart';
import '../../features/memory_match/presentation/memory_diy_builder_screen.dart';
import '../../games/sort_puzzle/creator/screens/sort_puzzle_creator_home_screen.dart';
import 'diy_review_hub_screen.dart';

class DiyGamesScreen extends StatefulWidget {
  const DiyGamesScreen({super.key});

  @override
  State<DiyGamesScreen> createState() => _DiyGamesScreenState();
}

class _DiyGamesScreenState extends State<DiyGamesScreen> {
  late final Future<bool> _isAdminFuture;

  @override
  void initState() {
    super.initState();
    _isAdminFuture = MemoryDiyRepository.instance.isCurrentUserAdminReviewer();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<bool>(
        future: _isAdminFuture,
        builder: (context, snapshot) {
          final bool isAdmin = snapshot.data ?? false;
          final bool isLoading = snapshot.connectionState != ConnectionState.done;
          final Object? error = snapshot.error;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _DiyHeroBanner(),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Create Your Own Game',
                subtitle:
                'Build Memory Match or Sort Puzzle and turn your ideas into playable challenges.',
              ),
              const SizedBox(height: 14),
              const _MemoryMatchDiyCard(),
              const SizedBox(height: 14),
              const _SortPuzzleDiyCard(),
              if (isLoading) ...[
                const SizedBox(height: 18),
                const _AdminLoadingCard(),
              ] else if (error != null) ...[
                const SizedBox(height: 18),
                _AdminErrorCard(errorText: error.toString()),
              ] else if (isAdmin) ...[
                const SizedBox(height: 24),
                const _SectionHeader(
                  title: 'Review Studio',
                  subtitle: 'One shared review queue for all DIY submissions.',
                ),
                const SizedBox(height: 14),
                const _ReviewStudioCard(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DiyHeroBanner extends StatelessWidget {
  const _DiyHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5B67F1),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x225B67F1),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'DIY Game Studio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Build your own game using fun templates. Create Memory Match puzzles or design Sort Puzzle levels across Bird, Ball, Color, Water, and Sand styles.',
            style: TextStyle(
              color: Colors.white,
              height: 1.35,
              fontSize: 14,
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
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _MemoryMatchDiyCard extends StatelessWidget {
  const _MemoryMatchDiyCard();

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      gradient: const [Color(0xFFFFF7ED), Color(0xFFEEF2FF)],
      iconGradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
      icon: Icons.grid_view_rounded,
      title: 'Memory Match',
      subtitle: 'Create your own themed memory puzzle',
      tags: const ['Fruits', 'Vehicles', 'Ocean', 'Animals', 'Birds', 'Mixed'],
      description:
      'Choose category, set your grid, preview your items, then play instantly.',
      actionText: 'Open',
      actionColor: const Color(0xFF5B67F1),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MemoryDiyBuilderScreen(),
          ),
        );
      },
    );
  }
}

class _SortPuzzleDiyCard extends StatelessWidget {
  const _SortPuzzleDiyCard();

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      gradient: const [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
      iconGradient: const [Color(0xFF17A8FF), Color(0xFF7C5CFF)],
      icon: Icons.local_drink_rounded,
      title: 'Sort Puzzle',
      subtitle: 'Create your own sortable puzzle challenge',
      tags: const ['Bird', 'Ball', 'Color', 'Water', 'Sand'],
      description:
      'Choose a variant, design containers, test your level, and submit it to the studio.',
      actionText: 'Create',
      actionColor: const Color(0xFF17A8FF),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SortPuzzleCreatorHomeScreen(),
          ),
        );
      },
    );
  }
}

class _ReviewStudioCard extends StatelessWidget {
  const _ReviewStudioCard();

  @override
  Widget build(BuildContext context) {
    return _ActionCard(
      gradient: const [Color(0xFFECFDF5), Color(0xFFEEF2FF)],
      iconGradient: const [Color(0xFF16A34A), Color(0xFF5B67F1)],
      icon: Icons.shield_rounded,
      title: 'Review Studio',
      subtitle: 'One shared review hub for all DIY submissions',
      tags: const ['Pending', 'Approved', 'Rejected', 'All Games'],
      description:
      'Open one shared control room, then jump into the correct review screen based on the submitted game type.',
      actionText: 'Review',
      actionColor: const Color(0xFF16A34A),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const DiyReviewHubScreen(),
          ),
        );
      },
    );
  }
}

class _AdminLoadingCard extends StatelessWidget {
  const _AdminLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.0)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checking admin access',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Loading review studio...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminErrorCard extends StatelessWidget {
  const _AdminErrorCard({
    required this.errorText,
  });

  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Could not check admin access.\n$errorText',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF7F1D1D),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.gradient,
    required this.iconGradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.description,
    required this.actionText,
    required this.actionColor,
    required this.onTap,
  });

  final List<Color> gradient;
  final List<Color> iconGradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> tags;
  final String description;
  final String actionText;
  final Color actionColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: iconGradient),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((label) => _TagChip(label: label)).toList(),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF374151),
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: actionColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}