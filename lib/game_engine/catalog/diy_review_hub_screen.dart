import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../features/memory_match/presentation/memory_diy_review_screen.dart';
import '../../games/sort_puzzle/creator/screens/sort_puzzle_review_screen.dart';

class DiyReviewHubScreen extends StatefulWidget {
  const DiyReviewHubScreen({super.key});

  @override
  State<DiyReviewHubScreen> createState() => _DiyReviewHubScreenState();
}

class _DiyReviewHubScreenState extends State<DiyReviewHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<String> _statuses = <String>[
    'pending_review',
    'approved',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _titleForStatus(String status) {
    switch (status) {
      case 'pending_review':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Projects';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF18122B),
        foregroundColor: Colors.white,
        title: const Text(
          'DIY Review Studio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _statuses
            .map(
              (status) => _ReviewGameTypeTab(
            status: status,
            title: _titleForStatus(status),
          ),
        )
            .toList(growable: false),
      ),
    );
  }
}

class _ReviewGameTypeTab extends StatelessWidget {
  const _ReviewGameTypeTab({
    required this.status,
    required this.title,
  });

  final String status;
  final String title;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('custom_games')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? const [];
        final Map<String, int> counts = <String, int>{};

        for (final doc in docs) {
          final data = doc.data();
          final String gameType = (data['gameType'] as String?)?.trim() ?? 'unknown';
          counts[gameType] = (counts[gameType] ?? 0) + 1;
        }

        if (counts.isEmpty) {
          return Center(
            child: Text(
              'No $status DIY submissions.',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          );
        }

        final entries = counts.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return _GameTypeReviewCard(
              gameType: entry.key,
              count: entry.value,
              title: title,
            );
          },
        );
      },
    );
  }
}

class _GameTypeReviewCard extends StatelessWidget {
  const _GameTypeReviewCard({
    required this.gameType,
    required this.count,
    required this.title,
  });

  final String gameType;
  final int count;
  final String title;

  String get _label {
    switch (gameType) {
      case 'memory':
        return 'Memory Match';
      case 'sort_puzzle':
        return 'Sort Puzzle';
      default:
        return gameType.replaceAll('_', ' ');
    }
  }

  IconData get _icon {
    switch (gameType) {
      case 'memory':
        return Icons.grid_view_rounded;
      case 'sort_puzzle':
        return Icons.local_drink_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  Color get _accent {
    switch (gameType) {
      case 'memory':
        return const Color(0xFF5B67F1);
      case 'sort_puzzle':
        return const Color(0xFF17A8FF);
      default:
        return const Color(0xFF6B7280);
    }
  }

  void _openReviewScreen(BuildContext context) {
    switch (gameType) {
      case 'memory':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const MemoryDiyReviewScreen(),
          ),
        );
        return;
      case 'sort_puzzle':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SortPuzzleReviewScreen(),
          ),
        );
        return;
      default:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('No review screen is wired yet for "$gameType".'),
            ),
          );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openReviewScreen(context),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
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
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    _icon,
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
                        _label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count item(s) in $title',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _accent,
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
          ),
        ),
      ),
    );
  }
}