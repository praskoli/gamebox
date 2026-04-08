import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreatorProfileScreen extends StatelessWidget {
  const CreatorProfileScreen({
    super.key,
    required this.creatorUid,
    required this.fallbackName,
  });

  final String creatorUid;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final userDoc =
    FirebaseFirestore.instance.collection('users').doc(creatorUid);
    final gamesQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(creatorUid)
        .collection('custom_games')
        .where('gameType', isEqualTo: 'memory')
        .where('status', isEqualTo: 'approved');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creator Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: userDoc.get(),
        builder: (context, userSnapshot) {
          final userData = userSnapshot.data?.data() ?? <String, dynamic>{};
          final displayName =
          (userData['displayName'] ?? '').toString().trim().isNotEmpty
              ? (userData['displayName'] ?? '').toString().trim()
              : fallbackName;
          final photoUrl = (userData['photoUrl'] ?? '').toString().trim();

          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: gamesQuery.get(),
            builder: (context, gamesSnapshot) {
              if (gamesSnapshot.connectionState == ConnectionState.waiting ||
                  userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (gamesSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load creator profile:\n${gamesSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final docs = gamesSnapshot.data?.docs ?? [];
              int totalPlays = 0;
              int totalLikes = 0;

              for (final doc in docs) {
                final data = doc.data();
                totalPlays += (data['playCount'] as num?)?.toInt() ?? 0;
                totalLikes += (data['likesCount'] as num?)?.toInt() ?? 0;
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _CreatorHeaderCard(
                    displayName: displayName,
                    photoUrl: photoUrl,
                    totalGames: docs.length,
                    totalPlays: totalPlays,
                    totalLikes: totalLikes,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Published Games',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty)
                    const _EmptyCreatorGamesCard()
                  else
                    ...docs.map((doc) {
                      final data = doc.data();
                      final title =
                      (data['title'] ?? 'Untitled Quest').toString();
                      final playCount = (data['playCount'] as num?)?.toInt() ?? 0;
                      final likesCount =
                          (data['likesCount'] as num?)?.toInt() ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CreatorGameCard(
                          title: title,
                          playCount: playCount,
                          likesCount: likesCount,
                        ),
                      );
                    }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CreatorHeaderCard extends StatelessWidget {
  const _CreatorHeaderCard({
    required this.displayName,
    required this.photoUrl,
    required this.totalGames,
    required this.totalPlays,
    required this.totalLikes,
  });

  final String displayName;
  final String photoUrl;
  final int totalGames;
  final int totalPlays;
  final int totalLikes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6D1CD8),
            Color(0xFF2C0D73),
            Color(0xFF081D63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332E1065),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _CreatorProfileAvatar(
            displayName: displayName,
            photoUrl: photoUrl,
            size: 88,
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CreatorStat(
                  label: 'Games',
                  value: '$totalGames',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CreatorStat(
                  label: 'Battles',
                  value: '$totalPlays',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CreatorStat(
                  label: 'Likes',
                  value: '$totalLikes',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreatorStat extends StatelessWidget {
  const _CreatorStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE9D5FF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorProfileAvatar extends StatelessWidget {
  const _CreatorProfileAvatar({
    required this.displayName,
    required this.photoUrl,
    this.size = 48,
  });

  final String displayName;
  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(
            name: displayName,
            size: size,
          ),
        ),
      );
    }

    return _FallbackAvatar(
      name: displayName,
      size: size,
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.name,
    required this.size,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }

  String _buildInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'AR';
    if (parts.length == 1) {
      final word = parts.first;
      return word.length >= 2
          ? word.substring(0, math.min(2, word.length)).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _CreatorGameCard extends StatelessWidget {
  const _CreatorGameCard({
    required this.title,
    required this.playCount,
    required this.likesCount,
  });

  final String title;
  final int playCount;
  final int likesCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101425),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2A3160)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '🎮 $playCount',
            style: const TextStyle(
              color: Color(0xFFCCD3FF),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '❤️ $likesCount',
            style: const TextStyle(
              color: Color(0xFFFFB4C8),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCreatorGamesCard extends StatelessWidget {
  const _EmptyCreatorGamesCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Text(
        'No approved games published yet.',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}