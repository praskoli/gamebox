import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../games/memory_match/domain/memory_diy_game_config.dart';
import '../data/memory_diy_repository.dart';
import 'memory_diy_builder_screen.dart';
import '../../../games/memory_match/presentation/memory_game_screen.dart';

class MemoryDiyReviewScreen extends StatefulWidget {
  const MemoryDiyReviewScreen({super.key});

  @override
  State<MemoryDiyReviewScreen> createState() => _MemoryDiyReviewScreenState();
}

class _MemoryDiyReviewScreenState extends State<MemoryDiyReviewScreen>
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
    debugPrint('DIY REVIEW ADMIN CHECK -> uid: ${user?.uid}, email: ${user?.email}');
    _tabController = TabController(length: _statuses.length, vsync: this);
    _isAdminFuture = MemoryDiyRepository.instance.isCurrentUserAdminReviewer();
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

  Color _colorForStatus(String status) {
    switch (status) {
      case 'pending_review':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF5B67F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final bool isAdmin = snapshot.data ?? false;

        if (!isAdmin) {
          return const _AdminAccessDeniedScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FC),
          appBar: AppBar(
            title: const Text('DIY Review Studio'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Rejected'),
              ],
            ),
          ),
          body: Column(
            children: [
              const _ReviewHeroBanner(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _statuses.map((status) {
                    return _ProjectStatusTab(
                      status: status,
                      title: _titleForStatus(status),
                      accentColor: _colorForStatus(status),
                    );
                  }).toList(growable: false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminAccessDeniedScreen extends StatelessWidget {
  const _AdminAccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('DIY Review Studio'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
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
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 44,
                color: Color(0xFFEF4444),
              ),
              SizedBox(height: 12),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This review studio is visible only to emails configured as DIY reviewers in Firestore.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewHeroBanner extends StatelessWidget {
  const _ReviewHeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B67F1), Color(0xFF8B5CF6)],
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
                Icons.shield_rounded,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Project Review Control Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Review submitted DIY projects, play them, and approve or reject them without needing a new app release.',
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

class _ProjectStatusTab extends StatelessWidget {
  const _ProjectStatusTab({
    required this.status,
    required this.title,
    required this.accentColor,
  });

  final String status;
  final String title;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MemoryDiyGameConfig>>(
      stream: MemoryDiyRepository.instance.watchProjectsByStatus(status),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _ReviewErrorState(
            title: title,
            errorText: snapshot.error.toString(),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final List<MemoryDiyGameConfig> projects = snapshot.data ?? const [];

        if (projects.isEmpty) {
          return _EmptyReviewState(
            title: title,
            accentColor: accentColor,
            status: status,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: projects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final config = projects[index];
            return _ReviewProjectCard(
              config: config,
              status: status,
              accentColor: accentColor,
            );
          },
        );
      },
    );
  }
}

class _EmptyReviewState extends StatelessWidget {
  const _EmptyReviewState({
    required this.title,
    required this.accentColor,
    required this.status,
  });

  final String title;
  final Color accentColor;
  final String status;

  String get _message {
    switch (status) {
      case 'pending_review':
        return 'No projects are waiting for approval right now.';
      case 'approved':
        return 'No approved projects yet.';
      case 'rejected':
        return 'No rejected projects yet.';
      default:
        return 'No projects found.';
    }
  }

  IconData get _icon {
    switch (status) {
      case 'pending_review':
        return Icons.hourglass_top_rounded;
      case 'approved':
        return Icons.verified_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.inbox_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 44, color: accentColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ReviewErrorState extends StatelessWidget {
  const _ReviewErrorState({
    required this.title,
    required this.errorText,
  });

  final String title;
  final String errorText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 12),
            Text(
              '$title Error',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ReviewProjectCard extends StatefulWidget {
  const _ReviewProjectCard({
    required this.config,
    required this.status,
    required this.accentColor,
  });

  final MemoryDiyGameConfig config;
  final String status;
  final Color accentColor;

  @override
  State<_ReviewProjectCard> createState() => _ReviewProjectCardState();
}

class _ReviewProjectCardState extends State<_ReviewProjectCard> {
  bool _busy = false;

  Future<void> _playProject() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryGameScreen(
          diyConfig: widget.config,
        ),
      ),
    );
  }

  Future<void> _openProject() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryDiyBuilderScreen(
          initialConfig: widget.config,
        ),
      ),
    );
  }

  Future<void> _approveProject() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await MemoryDiyRepository.instance.approveProject(widget.config);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Approved "${widget.config.title}".'),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not approve project: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _rejectProject() async {
    if (_busy) return;

    final TextEditingController reasonController = TextEditingController();

    final String? reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add a reason so you can remember why this project was rejected.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Example: Card count too low or theme not suitable',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(reasonController.text.trim());
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null) return;

    setState(() => _busy = true);
    try {
      await MemoryDiyRepository.instance.rejectProject(
        widget.config,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Rejected "${widget.config.title}".'),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not reject project: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case 'pending_review':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Project';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> previewItems =
    widget.config.items.take(8).toList(growable: false);

    return Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: widget.accentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.config.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(label: widget.config.categoryId),
                _InfoPill(
                  label:
                  '${widget.config.gridColumns} x ${widget.config.gridRows}',
                ),
                _InfoPill(
                  label:
                  '${(widget.config.gridColumns * widget.config.gridRows) ~/ 2} pairs',
                ),
                _InfoPill(label: '${widget.config.previewDurationMs}ms preview'),
                _InfoPill(label: '${widget.config.flipBackDelayMs}ms flip'),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Card Set Preview',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: previewItems.map((item) {
                return Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 28),
                  ),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _playProject,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openProject,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open'),
                  ),
                ),
              ],
            ),
            if (widget.status == 'pending_review') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _rejectProject,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _busy ? null : _approveProject,
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
  });

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