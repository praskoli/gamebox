import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:gamebox/games/sort_puzzle/data/sort_puzzle_repository.dart';
import '../models/sort_puzzle_creator_draft.dart';
import 'sort_puzzle_creator_screen.dart';
import '../../presentation/screens/sort_puzzle_game_screen.dart';
import '../../domain/sort_puzzle_variant.dart';

class SortPuzzleReviewScreen extends StatefulWidget {
  const SortPuzzleReviewScreen({super.key});

  @override
  State<SortPuzzleReviewScreen> createState() => _SortPuzzleReviewScreenState();
}

class _SortPuzzleReviewScreenState extends State<SortPuzzleReviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final Future<bool> _isAdminFuture;

  static const List<String> _statuses = <String>[
    'pending_review',
    'approved',
    'rejected',
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    debugPrint(
      'SORT DIY REVIEW ADMIN CHECK -> uid: ${user?.uid}, email: ${user?.email}',
    );
    _tabController = TabController(length: _statuses.length, vsync: this);
    _isAdminFuture = SortPuzzleRepository.instance.isCurrentUserAdminReviewer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bool isAdmin = snapshot.data ?? false;
        if (!isAdmin) {
          return const Scaffold(
            body: Center(
              child: Text('Admin access required for Sort Puzzle review.'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF18122B),
            foregroundColor: Colors.white,
            title: const Text('Sort Puzzle Review Studio'),
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
                .map((status) => _ProjectStatusTab(status: status))
                .toList(growable: false),
          ),
        );
      },
    );
  }
}

class _ProjectStatusTab extends StatelessWidget {
  const _ProjectStatusTab({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SortPuzzleCreatorDraft>>(
      stream: SortPuzzleRepository.instance.watchProjectsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<SortPuzzleCreatorDraft> projects =
            snapshot.data ?? const <SortPuzzleCreatorDraft>[];

        if (projects.isEmpty) {
          return Center(child: Text('No $status sort projects.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _ReviewProjectCard(
              config: projects[index],
              status: status,
            );
          },
        );
      },
    );
  }
}

class _ReviewProjectCard extends StatefulWidget {
  const _ReviewProjectCard({
    required this.config,
    required this.status,
  });

  final SortPuzzleCreatorDraft config;
  final String status;

  @override
  State<_ReviewProjectCard> createState() => _ReviewProjectCardState();
}

class _ReviewProjectCardState extends State<_ReviewProjectCard> {
  bool _busy = false;

  Future<void> _playProject() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SortPuzzleGameScreen(
          level: widget.config.toLevel(levelNumber: widget.config.levelNumber),
        ),
      ),
    );
  }

  Future<void> _inspectProject() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SortPuzzleCreatorScreen(
          variant: widget.config.variant,
          initialDraft: widget.config,
          isReviewMode: true,
        ),
      ),
    );
  }

  Future<void> _approve() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await SortPuzzleRepository.instance.approveProject(widget.config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved "${widget.config.title}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not approve project: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject() async {
    if (_busy) return;

    final TextEditingController reasonController = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Project'),
        content: TextField(
          controller: reasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add rejection reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(reasonController.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    reasonController.dispose();
    if (reason == null) return;

    setState(() => _busy = true);
    try {
      await SortPuzzleRepository.instance.rejectProject(
        widget.config,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected "${widget.config.title}".')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not reject project: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String _variantLabel(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return 'Bird Sort';
      case SortPuzzleVariant.ball:
        return 'Ball Sort';
      case SortPuzzleVariant.color:
        return 'Color Sort';
      case SortPuzzleVariant.water:
        return 'Water Sort';
      case SortPuzzleVariant.sand:
        return 'Sand Sort';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.config.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'By ${widget.config.creatorName}',
            style: const TextStyle(
              color: Color(0xFF5B67F1),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: _variantLabel(widget.config.variant)),
              _InfoPill(label: '${widget.config.containers.length} containers'),
              _InfoPill(label: 'Capacity ${widget.config.capacity}'),
              _InfoPill(label: widget.config.status),
            ],
          ),
          if (widget.config.rejectionReason.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Reason: ${widget.config.rejectionReason}',
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _inspectProject,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Inspect'),
              ),
              ElevatedButton.icon(
                onPressed: _playProject,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
              if (widget.status == 'pending_review')
                FilledButton.icon(
                  onPressed: _busy ? null : _approve,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Approve'),
                ),
              if (widget.status == 'pending_review')
                OutlinedButton.icon(
                  onPressed: _busy ? null : _reject,
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Reject'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}