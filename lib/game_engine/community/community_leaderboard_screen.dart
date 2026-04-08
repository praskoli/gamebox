import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommunityLeaderboardScreen extends StatelessWidget {
  const CommunityLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: const [
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _LeaderboardHero(),
            ),
            SizedBox(height: 12),
            TabBar(
              tabs: [
                Tab(text: 'Top Games'),
                Tab(text: 'Top Builders'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _TopGamesTab(),
                  _TopCreatorsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardHero extends StatelessWidget {
  const _LeaderboardHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3158FF), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x443158FF),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '🏆 Hall of Legends\nOnly the strongest builds shine here.',
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

class _TopGamesTab extends StatefulWidget {
  const _TopGamesTab();

  @override
  State<_TopGamesTab> createState() => _TopGamesTabState();
}

class _TopGamesTabState extends State<_TopGamesTab> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs =
  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collectionGroup('custom_games')
        .where('status', isEqualTo: 'approved')
        .orderBy('playCount', descending: true);
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _error = null;
      _lastDoc = null;
      _docs.clear();
    });

    try {
      final snapshot = await _query().limit(_pageSize).get();

      if (!mounted) return;

      setState(() {
        _docs.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot =
      await _query().startAfterDocument(_lastDoc!).limit(_pageSize).get();

      if (!mounted) return;

      setState(() {
        _docs.addAll(snapshot.docs);
        if (snapshot.docs.isNotEmpty) {
          _lastDoc = snapshot.docs.last;
        }
        _hasMore = snapshot.docs.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  String _readCreatorName(Map<String, dynamic> data) {
    final String creatorName = (data['creatorName'] ?? '').toString().trim();
    if (creatorName.isNotEmpty) return creatorName;

    final String ownerUid = (data['ownerUid'] ?? '').toString().trim();
    if (ownerUid.isEmpty) return 'Arena Builder';
    if (ownerUid.length <= 8) return ownerUid;
    return 'Builder ${ownerUid.substring(0, 6)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Hall load failed:\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_docs.isEmpty) {
      return const Center(
        child: Text('No legends ranked yet'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: _docs.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _docs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final data = _docs[i].data();
          final int rank = i + 1;
          final String title = (data['title'] ?? 'Untitled Quest').toString();
          final String creatorName = _readCreatorName(data);
          final int playCount = (data['playCount'] as num?)?.toInt() ?? 0;
          final int likesCount = (data['likesCount'] as num?)?.toInt() ?? 0;

          if (rank <= 3) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TopThreeGameCard(
                rank: rank,
                title: title,
                creatorName: creatorName,
                playCount: playCount,
                likesCount: likesCount,
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161A2D),
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
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF232A56),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Color(0xFFCCD3FF),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                'By $creatorName • $likesCount cheers',
                style: const TextStyle(
                  color: Color(0xFFB9C0FF),
                  fontWeight: FontWeight.w700,
                ),
              ),
              trailing: Text(
                '$playCount battles',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF7DA2FF),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopCreatorsTab extends StatelessWidget {
  const _TopCreatorsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collectionGroup('custom_games')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Builder board failed:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text('No builders yet'));
        }

        final Map<String, _CreatorStats> creatorMap = <String, _CreatorStats>{};

        for (final doc in docs) {
          final data = doc.data();
          final String ownerUid = (data['ownerUid'] ?? 'unknown').toString();
          final String creatorName = _readCreatorName(data, ownerUid);
          final int plays = (data['playCount'] as num?)?.toInt() ?? 0;

          final existing = creatorMap[ownerUid];
          if (existing == null) {
            creatorMap[ownerUid] = _CreatorStats(
              ownerUid: ownerUid,
              creatorName: creatorName,
              totalPlays: plays,
              totalPublished: 1,
            );
          } else {
            creatorMap[ownerUid] = existing.copyWith(
              totalPlays: existing.totalPlays + plays,
              totalPublished: existing.totalPublished + 1,
              creatorName: existing.creatorName.isNotEmpty
                  ? existing.creatorName
                  : creatorName,
            );
          }
        }

        final sorted = creatorMap.values.toList()
          ..sort((a, b) => b.totalPlays.compareTo(a.totalPlays));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: sorted.length,
          itemBuilder: (_, i) {
            final entry = sorted[i];
            final rank = i + 1;

            if (rank <= 3) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TopThreeCreatorCard(
                  rank: rank,
                  creatorName: entry.creatorName,
                  totalPlays: entry.totalPlays,
                  totalPublished: entry.totalPublished,
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161A2D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A3160)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF232A56),
                  child: Text(
                    _creatorInitials(entry.creatorName),
                    style: const TextStyle(
                      color: Color(0xFFCCD3FF),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                title: Text(
                  entry.creatorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  '${entry.totalPublished} games built',
                  style: const TextStyle(
                    color: Color(0xFFB9C0FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Text(
                  '${entry.totalPlays} battles',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF7DA2FF),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _readCreatorName(Map<String, dynamic> data, String ownerUid) {
    final String creatorName = (data['creatorName'] ?? '').toString().trim();
    if (creatorName.isNotEmpty) return creatorName;
    if (ownerUid.length <= 8) return ownerUid;
    return 'Builder ${ownerUid.substring(0, 6)}';
  }

  String _creatorInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'AR';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _TopThreeGameCard extends StatelessWidget {
  const _TopThreeGameCard({
    required this.rank,
    required this.title,
    required this.creatorName,
    required this.playCount,
    required this.likesCount,
  });

  final int rank;
  final String title;
  final String creatorName;
  final int playCount;
  final int likesCount;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (rank) {
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFF94A3B8),
      _ => const Color(0xFFB45309),
    };

    final IconData icon = switch (rank) {
      1 => Icons.workspace_premium_rounded,
      2 => Icons.emoji_events_rounded,
      _ => Icons.military_tech_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.22),
            const Color(0xFF161A2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withOpacity(0.15),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$rank • $title',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By $creatorName',
                  style: const TextStyle(
                    color: Color(0xFFE4E7FF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.sports_martial_arts_rounded,
                      label: '$playCount battles',
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.bolt_rounded,
                      label: '$likesCount cheers',
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopThreeCreatorCard extends StatelessWidget {
  const _TopThreeCreatorCard({
    required this.rank,
    required this.creatorName,
    required this.totalPlays,
    required this.totalPublished,
  });

  final int rank;
  final String creatorName;
  final int totalPlays;
  final int totalPublished;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (rank) {
      1 => const Color(0xFFF59E0B),
      2 => const Color(0xFF94A3B8),
      _ => const Color(0xFFB45309),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.22),
            const Color(0xFF161A2D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withOpacity(0.15),
            child: Text(
              _creatorInitials(creatorName),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$rank • $creatorName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.sports_martial_arts_rounded,
                      label: '$totalPlays battles',
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.auto_awesome_rounded,
                      label: '$totalPublished builds',
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _creatorInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'AR';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, 2).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CreatorStats {
  const _CreatorStats({
    required this.ownerUid,
    required this.creatorName,
    required this.totalPlays,
    required this.totalPublished,
  });

  final String ownerUid;
  final String creatorName;
  final int totalPlays;
  final int totalPublished;

  _CreatorStats copyWith({
    String? ownerUid,
    String? creatorName,
    int? totalPlays,
    int? totalPublished,
  }) {
    return _CreatorStats(
      ownerUid: ownerUid ?? this.ownerUid,
      creatorName: creatorName ?? this.creatorName,
      totalPlays: totalPlays ?? this.totalPlays,
      totalPublished: totalPublished ?? this.totalPublished,
    );
  }
}