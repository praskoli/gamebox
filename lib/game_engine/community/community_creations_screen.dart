import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/routing/route_names.dart';
import '../../games/memory_match/domain/memory_diy_game_config.dart';
import '../../games/memory_match/presentation/memory_game_screen.dart';
import 'creator_profile_screen.dart';

enum CommunitySortMode {
  latest,
  mostPlayed,
  mostLiked,
}

class CommunityCreationsScreen extends StatefulWidget {
  const CommunityCreationsScreen({
    super.key,
    this.showScaffold = false,
    this.showInlineHeader = true,
    this.onLoginTap,
  });

  final bool showScaffold;
  final bool showInlineHeader;
  final Future<bool> Function(BuildContext context)? onLoginTap;

  @override
  CommunityCreationsScreenState createState() =>
      CommunityCreationsScreenState();
}

class CommunityCreationsScreenState extends State<CommunityCreationsScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _docs =
  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  CommunitySortMode _sortMode = CommunitySortMode.latest;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  static const List<List<Color>> _tileGradients = <List<Color>>[
    <Color>[
      Color(0xFF7C1DFF),
      Color(0xFF3B0F8A),
      Color(0xFF0B237A),
    ],
    <Color>[
      Color(0xFFFF3CAC),
      Color(0xFF784BA0),
      Color(0xFF2B2E8A),
    ],
    <Color>[
      Color(0xFF00C6FF),
      Color(0xFF6A11CB),
      Color(0xFF1F1C7A),
    ],
    <Color>[
      Color(0xFF8E2DE2),
      Color(0xFF4A00E0),
      Color(0xFF0F2A88),
    ],
    <Color>[
      Color(0xFFFF512F),
      Color(0xFF7B1FA2),
      Color(0xFF1A237E),
    ],
  ];

  static const List<_GuestPromptCopy> _guestPromptCopies = <_GuestPromptCopy>[
    _GuestPromptCopy(
      title: 'Cheer your favorite creators',
      subtitle: 'Sign in to like games, support builders, and save your activity.',
    ),
    _GuestPromptCopy(
      title: 'Join the DIY creator arena',
      subtitle: 'Create your identity, cheer the games you love, and keep your progress.',
    ),
    _GuestPromptCopy(
      title: 'Your likes deserve to count',
      subtitle: 'Sign in so your support is saved and tied to your profile.',
    ),
    _GuestPromptCopy(
      title: 'Support this creator properly',
      subtitle: 'Log in to like games, follow your favorites, and stay part of the action.',
    ),
    _GuestPromptCopy(
      title: 'Ready to back this game?',
      subtitle: 'Sign in to unlock likes and become part of the DIY creator community.',
    ),
  ];

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String get _currentUserId => _currentUser?.uid ?? '';
  bool get _canLikeGames =>
      _currentUser != null && !(_currentUser?.isAnonymous ?? false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> refreshCreatorFeed() => _loadInitialPage();

  Query<Map<String, dynamic>> _baseQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collectionGroup('custom_games')
        .where('gameType', isEqualTo: 'memory')
        .where('status', isEqualTo: 'approved');

    switch (_sortMode) {
      case CommunitySortMode.latest:
        return query.orderBy('approvedAt', descending: true);
      case CommunitySortMode.mostPlayed:
        return query.orderBy('playCount', descending: true);
      case CommunitySortMode.mostLiked:
        return query.orderBy('likesCount', descending: true);
    }
  }

  Future<void> _loadInitialPage() async {
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _error = null;
      _lastDoc = null;
      _docs.clear();
    });

    try {
      final snapshot = await _baseQuery().limit(_pageSize).get();

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
      final snapshot = await _baseQuery()
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();

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
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<bool> _openLoginFlow() async {
    if (widget.onLoginTap != null) {
      return await widget.onLoginTap!(context);
    }

    try {
      final result = await Navigator.of(context).pushNamed(RouteNames.login);
      return result == true || _canLikeGames;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Connect your login screen to the Creator popup.'),
          ),
        );
      return false;
    }
  }

  Future<bool> _showGuestLikePopup() async {
    final int index = DateTime.now().millisecondsSinceEpoch %
        _guestPromptCopies.length;
    final _GuestPromptCopy copy = _guestPromptCopies[index];

    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF31C7A5),
                  Color(0xFF44D1B4),
                  Color(0xFF63E0C3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.24),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  copy.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  copy.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF3FFFB),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF18A985),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    child: const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.82),
                      ),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    child: const Text('Not Now'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'By signing in, you agree to the Terms & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      return _openLoginFlow();
    }

    return false;
  }

  Future<void> _toggleLike({
    required String ownerUid,
    required String gameId,
    required bool isLiked,
  }) async {
    if (!_canLikeGames) {
      final bool loggedIn = await _showGuestLikePopup();
      if (!loggedIn || !_canLikeGames) {
        return;
      }
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('custom_games')
        .doc(gameId);

    try {
      if (isLiked) {
        await docRef.update({
          'likedBy': FieldValue.arrayRemove(<String>[_currentUserId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        await docRef.update({
          'likedBy': FieldValue.arrayUnion(<String>[_currentUserId]),
          'likesCount': FieldValue.increment(1),
        });
      }

      final int index = _docs.indexWhere((doc) => doc.id == gameId);
      if (index >= 0 && mounted) {
        final current = Map<String, dynamic>.from(_docs[index].data());
        final List<String> currentLikedBy =
        List<String>.from(current['likedBy'] ?? const <String>[]);
        final int currentLikesCount =
            (current['likesCount'] as num?)?.toInt() ?? 0;

        if (isLiked) {
          currentLikedBy.remove(_currentUserId);
          current['likesCount'] =
          currentLikesCount > 0 ? currentLikesCount - 1 : 0;
        } else {
          currentLikedBy.add(_currentUserId);
          current['likesCount'] = currentLikesCount + 1;
        }

        current['likedBy'] = currentLikedBy;

        _docs[index] = _MutableMapDocumentSnapshot(
          id: _docs[index].id,
          data: current,
        );

        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not update cheer: $e'),
          ),
        );
    }
  }

  Future<void> _playGame({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) async {
    final data = doc.data();
    final ownerUid = (data['ownerUid'] ?? '').toString();

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerUid)
          .collection('custom_games')
          .doc(doc.id)
          .update({
        'playCount': FieldValue.increment(1),
      });
    } catch (_) {}

    final diyConfig = MemoryDiyGameConfig.fromMap({
      ...data,
      'id': doc.id,
    });

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryGameScreen(
          diyConfig: diyConfig,
        ),
      ),
    );

    final int index = _docs.indexWhere((e) => e.id == doc.id);
    if (index >= 0 && mounted) {
      final current = Map<String, dynamic>.from(_docs[index].data());
      final int currentPlayCount = (current['playCount'] as num?)?.toInt() ?? 0;
      current['playCount'] = currentPlayCount + 1;

      _docs[index] = _MutableMapDocumentSnapshot(
        id: _docs[index].id,
        data: current,
      );

      setState(() {});
    }
  }

  void _openCreatorProfile({
    required String ownerUid,
    required String creatorName,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatorProfileScreen(
          creatorUid: ownerUid,
          fallbackName: creatorName,
        ),
      ),
    );
  }

  String _readCreatorName(Map<String, dynamic> data) {
    final String creatorName = (data['creatorName'] ?? '').toString().trim();
    if (creatorName.isNotEmpty) return creatorName;

    final String ownerUid = (data['ownerUid'] ?? '').toString().trim();
    if (ownerUid.isEmpty) return 'Arena Builder';
    if (ownerUid.length <= 8) return ownerUid;
    return 'Builder ${ownerUid.substring(0, 6)}';
  }

  String _sortLabel(CommunitySortMode mode) {
    switch (mode) {
      case CommunitySortMode.latest:
        return 'New Drops';
      case CommunitySortMode.mostPlayed:
        return 'Trending';
      case CommunitySortMode.mostLiked:
        return 'Fan Favorites';
    }
  }

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Creator feed failed:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.4),
          ),
        ),
      );
    }

    if (_docs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No games yet.\nCreate one and be the first legend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitialPage,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: _docs.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          if (i >= _docs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final doc = _docs[i];
          final data = doc.data();

          final ownerUid = (data['ownerUid'] ?? '').toString();
          final likedByRaw = data['likedBy'];
          final likedBy = likedByRaw is List
              ? likedByRaw.map((e) => e.toString()).toList()
              : <String>[];

          final bool isLiked =
              _currentUserId.isNotEmpty && likedBy.contains(_currentUserId);

          final String title = (data['title'] ?? 'Untitled Quest').toString();
          final String creatorName = _readCreatorName(data);
          final int likesCount = (data['likesCount'] as num?)?.toInt() ?? 0;
          final int playCount = (data['playCount'] as num?)?.toInt() ?? 0;
          final List<Color> gradient = _tileGradients[i % _tileGradients.length];

          return _NeonCreatorGameTile(
            ownerUid: ownerUid,
            title: title,
            creatorName: creatorName,
            likesCount: likesCount,
            playCount: playCount,
            isLiked: isLiked,
            gradientColors: gradient,
            onProfileTap: () => _openCreatorProfile(
              ownerUid: ownerUid,
              creatorName: creatorName,
            ),
            onLike: () => _toggleLike(
              ownerUid: ownerUid,
              gameId: doc.id,
              isLiked: isLiked,
            ),
            onShare: () {
              final link = 'gamebox://play/${doc.id}';
              Share.share('Jump into this GameBox arena!\n$link');
            },
            onPlay: () => _playGame(doc: doc),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShowHeading =
        !widget.showScaffold || widget.showInlineHeader;

    final body = SafeArea(
      child: Column(
        children: [
          if (shouldShowHeading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _NeonSectionHeading(text: 'DIY Creators'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SortChip(
                    label: _sortLabel(CommunitySortMode.latest),
                    selected: _sortMode == CommunitySortMode.latest,
                    onTap: () {
                      if (_sortMode == CommunitySortMode.latest) return;
                      setState(() => _sortMode = CommunitySortMode.latest);
                      _loadInitialPage();
                    },
                  ),
                  _SortChip(
                    label: _sortLabel(CommunitySortMode.mostPlayed),
                    selected: _sortMode == CommunitySortMode.mostPlayed,
                    onTap: () {
                      if (_sortMode == CommunitySortMode.mostPlayed) return;
                      setState(() => _sortMode = CommunitySortMode.mostPlayed);
                      _loadInitialPage();
                    },
                  ),
                  _SortChip(
                    label: _sortLabel(CommunitySortMode.mostLiked),
                    selected: _sortMode == CommunitySortMode.mostLiked,
                    onTap: () {
                      if (_sortMode == CommunitySortMode.mostLiked) return;
                      setState(() => _sortMode = CommunitySortMode.mostLiked);
                      _loadInitialPage();
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('DIY Creators'),
      ),
      body: body,
    );
  }
}

class _NeonCreatorGameTile extends StatelessWidget {
  const _NeonCreatorGameTile({
    required this.ownerUid,
    required this.title,
    required this.creatorName,
    required this.likesCount,
    required this.playCount,
    required this.isLiked,
    required this.gradientColors,
    required this.onProfileTap,
    required this.onLike,
    required this.onShare,
    required this.onPlay,
  });

  final String ownerUid;
  final String title;
  final String creatorName;
  final int likesCount;
  final int playCount;
  final bool isLiked;
  final List<Color> gradientColors;
  final VoidCallback onProfileTap;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final userDoc =
    FirebaseFirestore.instance.collection('users').doc(ownerUid);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
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
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: userDoc.get(),
        builder: (context, snapshot) {
          final userData = snapshot.data?.data() ?? <String, dynamic>{};
          final displayName =
          (userData['displayName'] ?? '').toString().trim().isNotEmpty
              ? (userData['displayName'] ?? '').toString().trim()
              : creatorName;
          final photoUrl = (userData['photoUrl'] ?? '').toString().trim();

          return Stack(
            children: [
              Positioned(
                top: -2,
                right: 0,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFF5F84),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$likesCount',
                        style: _neonTextStyle(
                          fontSize: 20,
                          glowColor: const Color(0xFFFF6BF5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: _CreatorProfileAvatar(
                      displayName: displayName,
                      photoUrl: photoUrl,
                      size: 64,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 64),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: onProfileTap,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _neonTextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: onProfileTap,
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _neonTextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.sports_esports_rounded,
                                color: Color(0xFF9CC1FF),
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$playCount battles',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _neonTextStyle(
                                    fontSize: 18,
                                    glowColor: const Color(0xFFFF6BF5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _NeonIconButton(
                                icon: isLiked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onTap: onLike,
                                size: 44,
                                iconSize: 24,
                              ),
                              const SizedBox(width: 16),
                              _NeonIconButton(
                                icon: Icons.north_east_rounded,
                                onTap: onShare,
                                size: 44,
                                iconSize: 24,
                              ),
                              const SizedBox(width: 16),
                              _NeonIconButton(
                                icon: Icons.play_arrow_rounded,
                                onTap: onPlay,
                                size: 44,
                                iconSize: 28,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  TextStyle _neonTextStyle({
    double fontSize = 24,
    Color glowColor = const Color(0xFFFF86FF),
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      height: 0.96,
      letterSpacing: 0.4,
      shadows: [
        Shadow(color: glowColor, blurRadius: 10),
        Shadow(color: glowColor.withOpacity(0.9), blurRadius: 18),
      ],
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

class _NeonIconButton extends StatelessWidget {
  const _NeonIconButton({
    required this.icon,
    required this.onTap,
    this.size = 52,
    this.iconSize = 30,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Color(0xFFFF86FF),
              blurRadius: 12,
            ),
            Shadow(
              color: Color(0xFFFF86FF),
              blurRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE8E3FF),
      backgroundColor: Colors.white,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF5B67F1) : const Color(0xFF374151),
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected
            ? const Color(0xFFB9B5FF)
            : const Color(0xFFD1D5DB),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      avatar: selected
          ? const Icon(
        Icons.check_rounded,
        size: 18,
        color: Color(0xFF5B67F1),
      )
          : null,
    );
  }
}

class _NeonSectionHeading extends StatelessWidget {
  const _NeonSectionHeading({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.4,
        shadows: [
          Shadow(
            color: Color(0xFFFF86FF),
            blurRadius: 10,
          ),
          Shadow(
            color: Color(0xFFFF86FF),
            blurRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _MutableMapDocumentSnapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _MutableMapDocumentSnapshot({
    required this.id,
    required Map<String, dynamic> data,
  }) : _data = data;

  @override
  final String id;

  final Map<String, dynamic> _data;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  bool get exists => true;

  @override
  int get hashCode => Object.hash(id, _data);

  @override
  bool operator ==(Object other) {
    return other is _MutableMapDocumentSnapshot && other.id == id;
  }

  @override
  dynamic get(Object field) => _data[field];
}

class _GuestPromptCopy {
  const _GuestPromptCopy({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}