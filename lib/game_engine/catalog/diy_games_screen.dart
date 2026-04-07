import 'package:flutter/material.dart';

import '../../features/memory_match/data/memory_diy_repository.dart';
import '../../features/memory_match/presentation/memory_diy_builder_screen.dart';
import '../../features/memory_match/presentation/memory_diy_review_screen.dart';

class DiyGamesScreen extends StatelessWidget {
  const DiyGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<bool>(
        future: MemoryDiyRepository.instance.isCurrentUserAdminReviewer(),
        builder: (context, snapshot) {
          final bool isAdmin = snapshot.data ?? false;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const _DiyHeroBanner(),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Create Your Own Game',
                subtitle:
                'Start with Memory Match and build your own themed puzzle.',
              ),
              const SizedBox(height: 14),
              const _MemoryMatchDiyCard(),
              if (snapshot.connectionState == ConnectionState.waiting) ...[
                const SizedBox(height: 18),
                const _AdminLoadingCard(),
              ] else if (isAdmin) ...[
                const SizedBox(height: 24),
                const _SectionHeader(
                  title: 'Review Studio',
                  subtitle:
                  'Visible only to configured DIY review admins.',
                ),
                const SizedBox(height: 14),
                const _AdminReviewCard(),
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
            'Build your own game using fun templates. Start with Memory Match and create themed puzzles like Fruits, Vehicles, Ocean, Animals and more.',
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MemoryDiyBuilderScreen(),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFF7ED),
                Color(0xFFEEF2FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
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
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFEF4444),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Memory Match',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create your own themed memory puzzle',
                            style: TextStyle(
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
                  children: const [
                    _TagChip(label: 'Fruits'),
                    _TagChip(label: 'Vehicles'),
                    _TagChip(label: 'Ocean'),
                    _TagChip(label: 'Animals'),
                    _TagChip(label: 'Birds'),
                    _TagChip(label: 'Mixed'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose category, set your grid, preview your items, then play instantly.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF374151),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B67F1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Open',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
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

class _AdminReviewCard extends StatelessWidget {
  const _AdminReviewCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MemoryDiyReviewScreen(),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFECFDF5),
                Color(0xFFEEF2FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
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
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF16A34A),
                            Color(0xFF5B67F1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Studio',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Approve or reject submitted DIY projects',
                            style: TextStyle(
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
                  children: const [
                    _TagChip(label: 'Pending'),
                    _TagChip(label: 'Approved'),
                    _TagChip(label: 'Rejected'),
                    _TagChip(label: 'Admin'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Open the control room, play submitted projects, and review them before approval.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF374151),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
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
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Checking admin review access...',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
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
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
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