import 'dart:math' as math;
import '../../games/sort_puzzle/creator/models/sort_puzzle_creator_draft.dart';
import '../../games/sort_puzzle/presentation/screens/sort_puzzle_game_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/routing/route_names.dart';
import '../../games/memory_match/domain/memory_diy_game_config.dart';
import '../../games/memory_match/presentation/memory_game_screen.dart';
import '../../story_creator/data/story_repository.dart';
import '../../story_creator/presentation/story_player_screen.dart';
import 'creator_profile_screen.dart';

enum CommunitySortMode {
  latest,
  mostPlayed,
  mostLiked,
}

enum CreatorFeedContentType {
  game,
  story,
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
  final StoryRepository _storyRepository = StoryRepository();

  final List<_CreatorFeedItem> _items = <_CreatorFeedItem>[];

  CommunitySortMode _sortMode = CommunitySortMode.latest;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;

  DocumentSnapshot<Map<String, dynamic>>? _lastGameDoc;
  DocumentSnapshot<Map<String, dynamic>>? _lastStoryDoc;
  bool _hasMoreGames = true;
  bool _hasMoreStories = true;

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
      subtitle:
      'Sign in to like games and stories, support builders, and save your activity.',
    ),
    _GuestPromptCopy(
      title: 'Join the DIY creator arena',
      subtitle:
      'Create your identity, cheer the content you love, and keep your progress.',
    ),
    _GuestPromptCopy(
      title: 'Your likes deserve to count',
      subtitle: 'Sign in so your support is saved and tied to your profile.',
    ),
    _GuestPromptCopy(
      title: 'Support this creator properly',
      subtitle:
      'Log in to like content, follow your favorites, and stay part of the action.',
    ),
    _GuestPromptCopy(
      title: 'Ready to back this creator?',
      subtitle:
      'Sign in to unlock likes and become part of the DIY creator community.',
    ),
  ];

  User? get _currentUser => FirebaseAuth.instance.currentUser;
  String get _currentUserId => _currentUser?.uid ?? '';
  bool get _canLikeContent =>
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

  Query<Map<String, dynamic>> _gamesBaseQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collectionGroup('custom_games')
        .where('status', isEqualTo: 'approved')
        .where('communityVisible', isEqualTo: true);

    switch (_sortMode) {
      case CommunitySortMode.latest:
        return query.orderBy('approvedAt', descending: true);
      case CommunitySortMode.mostPlayed:
        return query.orderBy('playCount', descending: true);
      case CommunitySortMode.mostLiked:
        return query.orderBy('likesCount', descending: true);
    }
  }

  Query<Map<String, dynamic>> _storiesBaseQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('stories')
        .where('status', isEqualTo: 'published')
        .where('communityVisible', isEqualTo: true);

    switch (_sortMode) {
      case CommunitySortMode.latest:
        return query.orderBy('reviewedAt', descending: true);
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
      _items.clear();
      _lastGameDoc = null;
      _lastStoryDoc = null;
      _hasMoreGames = true;
      _hasMoreStories = true;
    });

    try {
      final QuerySnapshot<Map<String, dynamic>> gamesSnapshot =
      await _gamesBaseQuery().limit(_pageSize).get();

      final QuerySnapshot<Map<String, dynamic>> storiesSnapshot =
      await _storiesBaseQuery().limit(_pageSize).get();

      if (!mounted) return;

      final List<_CreatorFeedItem> merged = <_CreatorFeedItem>[
        ...gamesSnapshot.docs.map(_mapGameDocToFeedItem),
        ...storiesSnapshot.docs.map(_mapStoryDocToFeedItem),
      ];

      _sortMergedItems(merged);

      setState(() {
        _items.addAll(merged);
        _lastGameDoc =
        gamesSnapshot.docs.isNotEmpty ? gamesSnapshot.docs.last : null;
        _lastStoryDoc =
        storiesSnapshot.docs.isNotEmpty ? storiesSnapshot.docs.last : null;
        _hasMoreGames = gamesSnapshot.docs.length == _pageSize;
        _hasMoreStories = storiesSnapshot.docs.length == _pageSize;
        _hasMore = _hasMoreGames || _hasMoreStories;
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
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      QuerySnapshot<Map<String, dynamic>>? gamesSnapshot;
      QuerySnapshot<Map<String, dynamic>>? storiesSnapshot;

      if (_hasMoreGames) {
        Query<Map<String, dynamic>> gameQuery =
        _gamesBaseQuery().limit(_pageSize);
        if (_lastGameDoc != null) {
          gameQuery = gameQuery.startAfterDocument(_lastGameDoc!);
        }
        gamesSnapshot = await gameQuery.get();
      }

      if (_hasMoreStories) {
        Query<Map<String, dynamic>> storyQuery =
        _storiesBaseQuery().limit(_pageSize);
        if (_lastStoryDoc != null) {
          storyQuery = storyQuery.startAfterDocument(_lastStoryDoc!);
        }
        storiesSnapshot = await storyQuery.get();
      }

      if (!mounted) return;

      final List<_CreatorFeedItem> merged = <_CreatorFeedItem>[
        if (gamesSnapshot != null)
          ...gamesSnapshot.docs.map(_mapGameDocToFeedItem),
        if (storiesSnapshot != null)
          ...storiesSnapshot.docs.map(_mapStoryDocToFeedItem),
      ];

      _sortMergedItems(merged);

      setState(() {
        _items.addAll(merged);

        if (gamesSnapshot != null) {
          if (gamesSnapshot.docs.isNotEmpty) {
            _lastGameDoc = gamesSnapshot.docs.last;
          }
          _hasMoreGames = gamesSnapshot.docs.length == _pageSize;
        }

        if (storiesSnapshot != null) {
          if (storiesSnapshot.docs.isNotEmpty) {
            _lastStoryDoc = storiesSnapshot.docs.last;
          }
          _hasMoreStories = storiesSnapshot.docs.length == _pageSize;
        }

        _hasMore = _hasMoreGames || _hasMoreStories;
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

  void _sortMergedItems(List<_CreatorFeedItem> items) {
    switch (_sortMode) {
      case CommunitySortMode.latest:
        items.sort((a, b) {
          final DateTime aTime =
              a.visibleAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final DateTime bTime =
              b.visibleAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        break;
      case CommunitySortMode.mostPlayed:
        items.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case CommunitySortMode.mostLiked:
        items.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
    }
  }

  _CreatorFeedItem _mapGameDocToFeedItem(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final Map<String, dynamic> data = doc.data();

    return _CreatorFeedItem(
      id: doc.id,
      contentType: CreatorFeedContentType.game,
      gameType: (data['gameType'] ?? '').toString(),
      ownerUid: (data['ownerUid'] ?? '').toString(),
      title: (data['title'] ?? 'Untitled Game').toString(),
      creatorName: _readCreatorName(data),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      playCount: (data['playCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] is List)
          ? (data['likedBy'] as List<dynamic>)
          .map((dynamic e) => e.toString())
          .toList(growable: false)
          : const <String>[],
      visibleAt: _readDate(data['approvedAt']) ?? _readDate(data['updatedAt']),
      coverImageUrl: '',
      rawData: data,
    );
  }

  _CreatorFeedItem _mapStoryDocToFeedItem(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final Map<String, dynamic> data = doc.data();

    return _CreatorFeedItem(
      id: doc.id,
      contentType: CreatorFeedContentType.story,
      gameType: null,
      ownerUid: (data['ownerUid'] ?? '').toString(),
      title: (data['title'] ?? 'Untitled Story').toString(),
      creatorName: _readCreatorName(data),
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      playCount: (data['playCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] is List)
          ? (data['likedBy'] as List<dynamic>)
          .map((dynamic e) => e.toString())
          .toList(growable: false)
          : const <String>[],
      visibleAt: _readDate(data['reviewedAt']) ?? _readDate(data['updatedAt']),
      coverImageUrl: (data['coverImageUrl'] ?? '').toString(),
      rawData: data,
    );
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<bool> _openLoginFlow() async {
    if (widget.onLoginTap != null) {
      return await widget.onLoginTap!(context);
    }

    try {
      final dynamic result =
      await Navigator.of(context).pushNamed(RouteNames.login);
      return result == true || _canLikeContent;
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
    final int index =
        DateTime.now().millisecondsSinceEpoch % _guestPromptCopies.length;
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
                colors: <Color>[
                  Color(0xFF31C7A5),
                  Color(0xFF44D1B4),
                  Color(0xFF63E0C3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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

  Future<void> _toggleLike(_CreatorFeedItem item) async {
    if (!_canLikeContent) {
      final bool loggedIn = await _showGuestLikePopup();
      if (!loggedIn || !_canLikeContent) {
        return;
      }
    }

    final bool isLiked = item.likedBy.contains(_currentUserId);

    final DocumentReference<Map<String, dynamic>> docRef =
    item.contentType == CreatorFeedContentType.game
        ? FirebaseFirestore.instance
        .collection('users')
        .doc(item.ownerUid)
        .collection('custom_games')
        .doc(item.id)
        : FirebaseFirestore.instance.collection('stories').doc(item.id);

    try {
      if (isLiked) {
        await docRef.update(<String, Object>{
          'likedBy': FieldValue.arrayRemove(<String>[_currentUserId]),
          'likesCount': FieldValue.increment(-1),
        });
      } else {
        await docRef.update(<String, Object>{
          'likedBy': FieldValue.arrayUnion(<String>[_currentUserId]),
          'likesCount': FieldValue.increment(1),
        });
      }

      final int index = _items.indexWhere(
            (_CreatorFeedItem e) =>
        e.id == item.id && e.contentType == item.contentType,
      );

      if (index >= 0 && mounted) {
        final List<String> updatedLikedBy =
        List<String>.from(_items[index].likedBy);
        final int updatedLikesCount = _items[index].likesCount;

        if (isLiked) {
          updatedLikedBy.remove(_currentUserId);
          _items[index] = _items[index].copyWith(
            likedBy: updatedLikedBy,
            likesCount: updatedLikesCount > 0 ? updatedLikesCount - 1 : 0,
          );
        } else {
          updatedLikedBy.add(_currentUserId);
          _items[index] = _items[index].copyWith(
            likedBy: updatedLikedBy,
            likesCount: updatedLikesCount + 1,
          );
        }

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

  Future<void> _openItem(_CreatorFeedItem item) async {
    if (item.contentType == CreatorFeedContentType.story) {
      try {
        await FirebaseFirestore.instance
            .collection('stories')
            .doc(item.id)
            .update(<String, Object>{
          'playCount': FieldValue.increment(1),
        });
      } catch (_) {}

      final StoryBundle? bundle = await _storyRepository.getStoryBundle(item.id);
      if (!mounted || bundle == null) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoryPlayerScreen(
            story: bundle.story,
            scenes: bundle.scenes,
          ),
        ),
      );

      final int index = _items.indexWhere(
            (_CreatorFeedItem e) =>
        e.id == item.id && e.contentType == item.contentType,
      );
      if (index >= 0 && mounted) {
        _items[index] = _items[index].copyWith(
          playCount: _items[index].playCount + 1,
        );
        setState(() {});
      }
      return;
    }

    if (item.gameType == 'memory') {
      final String ownerUid = item.ownerUid;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('custom_games')
            .doc(item.id)
            .update(<String, Object>{
          'playCount': FieldValue.increment(1),
        });
      } catch (_) {}

      final MemoryDiyGameConfig diyConfig = MemoryDiyGameConfig.fromMap(
        <String, dynamic>{
          ...item.rawData,
          'id': item.id,
        },
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MemoryGameScreen(
            diyConfig: diyConfig,
          ),
        ),
      );

      final int index = _items.indexWhere(
            (_CreatorFeedItem e) =>
        e.id == item.id && e.contentType == item.contentType,
      );
      if (index >= 0 && mounted) {
        _items[index] = _items[index].copyWith(
          playCount: _items[index].playCount + 1,
        );
        setState(() {});
      }
      return;
    }

    if (item.gameType == 'sort_puzzle') {
      final String ownerUid = item.ownerUid;

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(ownerUid)
            .collection('custom_games')
            .doc(item.id)
            .update(<String, Object>{
          'playCount': FieldValue.increment(1),
        });
      } catch (_) {}

      final SortPuzzleCreatorDraft draft = SortPuzzleCreatorDraft.fromFirestore(
        <String, dynamic>{
          ...item.rawData,
        },
        item.id,
      );

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SortPuzzleGameScreen(
            level: draft.toLevel(levelNumber: draft.levelNumber),
          ),
        ),
      );

      final int index = _items.indexWhere(
            (_CreatorFeedItem e) =>
        e.id == item.id && e.contentType == item.contentType,
      );
      if (index >= 0 && mounted) {
        _items[index] = _items[index].copyWith(
          playCount: _items[index].playCount + 1,
        );
        setState(() {});
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Game type "${item.gameType ?? 'unknown'}" is not playable yet in community feed.',
          ),
        ),
      );
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

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No creator content yet.\nPublish a game or story and be the first legend.',
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
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (BuildContext context, int i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final _CreatorFeedItem item = _items[i];
          final bool isLiked =
              _currentUserId.isNotEmpty && item.likedBy.contains(_currentUserId);
          final List<Color> gradient =
          _tileGradients[i % _tileGradients.length];

          return _NeonCreatorContentTile(
            ownerUid: item.ownerUid,
            title: item.title,
            creatorName: item.creatorName,
            likesCount: item.likesCount,
            playCount: item.playCount,
            isLiked: isLiked,
            gradientColors: gradient,
            contentType: item.contentType,
            gameType: item.gameType,
            coverImageUrl: item.coverImageUrl,
            onProfileTap: () => _openCreatorProfile(
              ownerUid: item.ownerUid,
              creatorName: item.creatorName,
            ),
            onLike: () => _toggleLike(item),
            onShare: () {
              final String deepLink =
              item.contentType == CreatorFeedContentType.story
                  ? 'gamebox://story/${item.id}'
                  : 'gamebox://play/${item.id}';
              final String contentLabel =
              item.contentType == CreatorFeedContentType.story
                  ? 'story'
                  : 'game';
              Share.share('Jump into this GameBox $contentLabel!\n$deepLink');
            },
            onOpen: () => _openItem(item),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShowHeading =
        !widget.showScaffold || widget.showInlineHeader;

    final Widget body = SafeArea(
      child: Column(
        children: <Widget>[
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
                children: <Widget>[
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

class _CreatorFeedItem {
  const _CreatorFeedItem({
    required this.id,
    required this.contentType,
    required this.ownerUid,
    required this.title,
    required this.creatorName,
    required this.likesCount,
    required this.playCount,
    required this.likedBy,
    required this.visibleAt,
    required this.rawData,
    this.gameType,
    this.coverImageUrl = '',
  });

  final String id;
  final CreatorFeedContentType contentType;
  final String ownerUid;
  final String title;
  final String creatorName;
  final int likesCount;
  final int playCount;
  final List<String> likedBy;
  final DateTime? visibleAt;
  final Map<String, dynamic> rawData;
  final String? gameType;
  final String coverImageUrl;

  _CreatorFeedItem copyWith({
    int? likesCount,
    int? playCount,
    List<String>? likedBy,
  }) {
    return _CreatorFeedItem(
      id: id,
      contentType: contentType,
      ownerUid: ownerUid,
      title: title,
      creatorName: creatorName,
      likesCount: likesCount ?? this.likesCount,
      playCount: playCount ?? this.playCount,
      likedBy: likedBy ?? this.likedBy,
      visibleAt: visibleAt,
      rawData: rawData,
      gameType: gameType,
      coverImageUrl: coverImageUrl,
    );
  }
}

class _NeonCreatorContentTile extends StatelessWidget {
  const _NeonCreatorContentTile({
    required this.ownerUid,
    required this.title,
    required this.creatorName,
    required this.likesCount,
    required this.playCount,
    required this.isLiked,
    required this.gradientColors,
    required this.contentType,
    required this.gameType,
    required this.coverImageUrl,
    required this.onProfileTap,
    required this.onLike,
    required this.onShare,
    required this.onOpen,
  });

  final String ownerUid;
  final String title;
  final String creatorName;
  final int likesCount;
  final int playCount;
  final bool isLiked;
  final List<Color> gradientColors;
  final CreatorFeedContentType contentType;
  final String? gameType;
  final String coverImageUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onOpen;

  bool get _isStory => contentType == CreatorFeedContentType.story;

  String get _typeLabel {
    if (_isStory) return 'Story';
    switch (gameType) {
      case 'memory':
        return 'Memory Game';
      case 'sort_puzzle':
        return 'Sort Puzzle';
      case 'block':
        return 'Block Game';
      default:
        if ((gameType ?? '').trim().isEmpty) return 'Game';
        return _capitalize(gameType!.replaceAll('_', ' '));
    }
  }

  IconData get _typeIcon {
    if (_isStory) return Icons.auto_stories_rounded;
    switch (gameType) {
      case 'memory':
        return Icons.grid_view_rounded;
      case 'block':
        return Icons.view_module_rounded;
      default:
        return Icons.sports_esports_rounded;
    }
  }

  String get _playLabel => _isStory ? '$playCount reads' : '$playCount plays';

  @override
  Widget build(BuildContext context) {
    final String displayName = creatorName;
    final String photoUrl = '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 360;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x332E1065),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 10,
                spacing: 10,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: compact
                          ? constraints.maxWidth
                          : constraints.maxWidth - 110,
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: <Widget>[
                        _TypeChip(
                          icon: _typeIcon,
                          label: _typeLabel,
                        ),
                      ],
                    ),
                  ),
                  Container(
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
                      children: <Widget>[
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
                ],
              ),
              const SizedBox(height: 12),
              compact
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: onProfileTap,
                    child: _CreatorCoverAvatar(
                      displayName: displayName,
                      photoUrl: photoUrl,
                      coverImageUrl: coverImageUrl,
                      isStory: _isStory,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CreatorTextBlock(
                    title: title,
                    displayName: displayName,
                    playLabel: _playLabel,
                    isStory: _isStory,
                    onOpen: onOpen,
                    onProfileTap: onProfileTap,
                    neonTextStyle: _neonTextStyle,
                  ),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: onProfileTap,
                    child: _CreatorCoverAvatar(
                      displayName: displayName,
                      photoUrl: photoUrl,
                      coverImageUrl: coverImageUrl,
                      isStory: _isStory,
                      size: 64,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _CreatorTextBlock(
                      title: title,
                      displayName: displayName,
                      playLabel: _playLabel,
                      isStory: _isStory,
                      onOpen: onOpen,
                      onProfileTap: onProfileTap,
                      neonTextStyle: _neonTextStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: <Widget>[
                  _NeonIconButton(
                    icon: isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    onTap: onLike,
                    size: 44,
                    iconSize: 24,
                  ),
                  _NeonIconButton(
                    icon: Icons.north_east_rounded,
                    onTap: onShare,
                    size: 44,
                    iconSize: 24,
                  ),
                  _NeonIconButton(
                    icon: _isStory
                        ? Icons.auto_stories_rounded
                        : Icons.play_arrow_rounded,
                    onTap: onOpen,
                    size: 44,
                    iconSize: 28,
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
      shadows: <Shadow>[
        Shadow(color: glowColor, blurRadius: 10),
        Shadow(color: glowColor.withOpacity(0.9), blurRadius: 18),
      ],
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value.substring(0, 1).toUpperCase() + value.substring(1);
  }
}

class _CreatorTextBlock extends StatelessWidget {
  const _CreatorTextBlock({
    required this.title,
    required this.displayName,
    required this.playLabel,
    required this.isStory,
    required this.onOpen,
    required this.onProfileTap,
    required this.neonTextStyle,
  });

  final String title;
  final String displayName;
  final String playLabel;
  final bool isStory;
  final VoidCallback onOpen;
  final VoidCallback onProfileTap;
  final TextStyle Function({
  double fontSize,
  Color glowColor,
  }) neonTextStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: onOpen,
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: neonTextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onProfileTap,
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: neonTextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Icon(
              isStory
                  ? Icons.menu_book_rounded
                  : Icons.sports_esports_rounded,
              color: const Color(0xFF9CC1FF),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                playLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: neonTextStyle(
                  fontSize: 18,
                  glowColor: const Color(0xFFFF6BF5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CreatorCoverAvatar extends StatelessWidget {
  const _CreatorCoverAvatar({
    required this.displayName,
    required this.photoUrl,
    required this.coverImageUrl,
    required this.isStory,
    this.size = 48,
  });

  final String displayName;
  final String photoUrl;
  final String coverImageUrl;
  final bool isStory;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isStory && coverImageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          coverImageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _FallbackAvatar(
            name: displayName,
            size: size,
            isStory: true,
          ),
        ),
      );
    }

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
            isStory: isStory,
          ),
        ),
      );
    }

    return _FallbackAvatar(
      name: displayName,
      size: size,
      isStory: isStory,
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({
    required this.name,
    required this.size,
    required this.isStory,
  });

  final String name;
  final double size;
  final bool isStory;

  @override
  Widget build(BuildContext context) {
    final String initials = _buildInitials(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: isStory ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isStory ? BorderRadius.circular(18) : null,
        gradient: LinearGradient(
          colors: isStory
              ? const <Color>[Color(0xFFEC4899), Color(0xFF8B5CF6)]
              : const <Color>[Color(0xFF4F46E5), Color(0xFF9333EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: isStory
            ? const Icon(
          Icons.auto_stories_rounded,
          color: Colors.white,
          size: 28,
        )
            : Text(
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
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String e) => e.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'AR';
    if (parts.length == 1) {
      final String word = parts.first;
      return word.length >= 2
          ? word.substring(0, math.min(2, word.length)).toUpperCase()
          : word.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
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
          shadows: const <Shadow>[
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
        shadows: <Shadow>[
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

class _GuestPromptCopy {
  const _GuestPromptCopy({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}