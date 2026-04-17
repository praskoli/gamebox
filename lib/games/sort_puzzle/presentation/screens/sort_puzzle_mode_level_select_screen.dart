import 'dart:math' as math;
import '../../../../features/memory_match/data/memory_diy_repository.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/asset_sort_puzzle_repository.dart';
import '../../data/sort_puzzle_progress_service.dart';
import '../../domain/sort_level.dart';
import '../../domain/sort_puzzle_variant.dart';
import '../screens/sort_puzzle_game_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SortPuzzleModeLevelSelectScreen extends StatefulWidget {
  const SortPuzzleModeLevelSelectScreen({
    super.key,
    required this.variant,
    required this.modeKey,
    required this.modeTitle,
    required this.description,
  });
    final SortPuzzleVariant variant;
  final String modeKey;
  final String modeTitle;
  final String description;

  @override
  State<SortPuzzleModeLevelSelectScreen> createState() =>
      _SortPuzzleModeLevelSelectScreenState();
}

class _SortPuzzleModeLevelSelectScreenState
    extends State<SortPuzzleModeLevelSelectScreen> {
  static const int _levelsPerPage = 25;
  static const String _adminConfigCollection = 'app_config';
  static const String _adminConfigDocId = 'diy_review_admins';
  static const String _fallbackAdminEmail = 'koli.prasanth.rao@gmail.com';
  final PageController _pageController = PageController();

  late Future<List<SortLevel>> _future;
  int _unlockedStep = 1;
  int _currentPage = 0;
  final Map<int, int> _starsByLevel = <int, int>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _isCurrentUserAdminReviewer() async {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    final String currentEmail =
        FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase() ?? '';

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection(_adminConfigCollection)
          .doc(_adminConfigDocId)
          .get();

      final Map<String, dynamic>? data = doc.data();
      final dynamic rawAllowedEmails = data?['allowedEmails'];
      final dynamic rawAllowedUids = data?['allowedUids'];

      final List<String> allowedEmails;
      if (rawAllowedEmails is List) {
        allowedEmails = rawAllowedEmails
            .map((dynamic e) => e.toString().trim().toLowerCase())
            .where((String e) => e.isNotEmpty)
            .toList(growable: false);
      } else if (rawAllowedEmails is String &&
          rawAllowedEmails.trim().isNotEmpty) {
        allowedEmails = <String>[rawAllowedEmails.trim().toLowerCase()];
      } else {
        allowedEmails = <String>[_fallbackAdminEmail];
      }

      final List<String> allowedUids;
      if (rawAllowedUids is List) {
        allowedUids = rawAllowedUids
            .map((dynamic e) => e.toString().trim())
            .where((String e) => e.isNotEmpty)
            .toList(growable: false);
      } else if (rawAllowedUids is String &&
          rawAllowedUids.trim().isNotEmpty) {
        allowedUids = <String>[rawAllowedUids.trim()];
      } else {
        allowedUids = const <String>[];
      }

      return allowedUids.contains(currentUid) ||
          allowedEmails.contains(currentEmail);
    } catch (_) {
      return currentEmail == _fallbackAdminEmail;
    }
  }

  Future<List<SortLevel>> _load() async {
    final List<SortLevel> filtered = await AssetSortPuzzleRepository.instance
        .loadLevelsForMode(widget.variant, widget.modeKey);

    final bool isAdmin =
    await MemoryDiyRepository.instance.isCurrentUserAdminReviewer();

    _unlockedStep = isAdmin
        ? filtered.length
        : await SortPuzzleProgressService.instance.getUnlockedStep(
      widget.variant,
      widget.modeKey,
    );

    _starsByLevel.clear();
    for (final SortLevel level in filtered) {
      _starsByLevel[level.levelNumber] =
      await SortPuzzleProgressService.instance.getStars(
        widget.variant,
        widget.modeKey,
        level.levelNumber,
      );

    }

    if (filtered.isNotEmpty) {
      final int safeStep = _unlockedStep.clamp(1, filtered.length);
      _currentPage = (safeStep - 1) ~/ _levelsPerPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_currentPage);
      });
    } else {
      _currentPage = 0;
    }

    return filtered;
  }

  Future<void> _openLevel(List<SortLevel> levels, int index) async {
    final SortLevel level = levels[index];

    final int? stars = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => SortPuzzleGameScreen(level: level),
      ),
    );

    if (stars != null && stars > 0) {
      final int completedStep = index + 1;
      final int nextStep = completedStep + 1;

      await SortPuzzleProgressService.instance.unlockStepIfHigher(
        widget.variant,
        widget.modeKey,
        nextStep,
      );

      await SortPuzzleProgressService.instance.saveStars(
        widget.variant,
        widget.modeKey,
        level.levelNumber,
        stars,
      );

      if (!mounted) return;

      final List<SortLevel> refreshed = await _load();
      if (!mounted) return;

      setState(() {
        _future = Future<List<SortLevel>>.value(refreshed);
      });

      if (nextStep <= refreshed.length) {
        final bool? goNext = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => _NextLevelSheet(
            nextLevel: refreshed[nextStep - 1].levelNumber,
            accent: _themeFor(widget.variant, widget.modeKey).titleFill,
          ),
        );

        if (goNext == true && mounted) {
          await _openLevel(refreshed, nextStep - 1);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _SelectorTheme theme = _themeFor(widget.variant, widget.modeKey);

    return Scaffold(
      backgroundColor: theme.skyTop,
      body: Stack(
        children: <Widget>[
          _GameSelectorBackground(theme: theme),
          SafeArea(
            child: FutureBuilder<List<SortLevel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to load levels: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final List<SortLevel> levels =
                    snapshot.data ?? const <SortLevel>[];
                if (levels.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _emptyMessage(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                }

                final int totalPages =
                math.max(1, (levels.length / _levelsPerPage).ceil());
                final int completedCount = levels
                    .where((e) => (_starsByLevel[e.levelNumber] ?? 0) > 0)
                    .length;
                final int totalStars = levels.fold<int>(
                  0,
                      (sum, level) => sum + (_starsByLevel[level.levelNumber] ?? 0),
                );

                final int safeStep = _unlockedStep.clamp(1, levels.length);
                final int currentLevelNumber = levels[safeStep - 1].levelNumber;

                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                      child: Row(
                        children: <Widget>[
                          _BackButtonBubble(theme: theme),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                _SelectLevelTitle(theme: theme),
                                const SizedBox(height: 2),
                                Text(
                                  _prettyModeTitle(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    fontStyle: FontStyle.italic,
                                    color: theme.subtitleColor,
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: Colors.white.withOpacity(0.85),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 52),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                      child: _TopStatsRow(
                        completedCount: completedCount,
                        totalLevels: levels.length,
                        totalStars: totalStars,
                        currentLevelNumber: currentLevelNumber,
                        theme: theme,
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: totalPages,
                        onPageChanged: (value) {
                          setState(() {
                            _currentPage = value;
                          });
                        },
                        itemBuilder: (context, pageIndex) {
                          final int start = pageIndex * _levelsPerPage;
                          final int end =
                          math.min(start + _levelsPerPage, levels.length);
                          final List<SortLevel> visible =
                          levels.sublist(start, end);

                          return Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                            child: _LevelGridPage(
                              theme: theme,
                              visibleLevels: visible,
                              startIndex: start,
                              unlockedStep: _unlockedStep,
                              starsByLevel: _starsByLevel,
                              onTap: (globalIndex) =>
                                  _openLevel(levels, globalIndex),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List<Widget>.generate(
                          totalPages,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 22 : 9,
                            height: 9,
                            decoration: BoxDecoration(
                              gradient: _currentPage == index
                                  ? LinearGradient(
                                colors: <Color>[
                                  theme.titleFill,
                                  theme.titleAccent,
                                ],
                              )
                                  : null,
                              color: _currentPage == index
                                  ? null
                                  : theme.pageDotInactive,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _prettyModeTitle() {
    switch (widget.modeKey) {
      case 'classic_journey':
        return 'Classic Journey';
      case 'move_challenge':
        return 'Move Challenge';
      case 'time_challenge':
        return 'Time Challenge';
      case 'theme_worlds':
        return 'Theme Worlds';
      default:
        return widget.modeTitle;
    }
  }

  String _emptyMessage() {
    switch (widget.modeKey) {
      case 'classic_journey':
        return 'No Classic Journey levels are available yet.\n\nClassic Journey expects official levels without move limits, time limits, or theme world keys.';
      case 'move_challenge':
        return 'No Move Challenge levels are available yet.\n\nMove Challenge expects official levels with a moveLimit.';
      case 'time_challenge':
        return 'No Time Challenge levels are available yet.\n\nTime Challenge expects official levels with a timeLimitSeconds value.';
      case 'theme_worlds':
        return 'No Theme Worlds levels are available yet.\n\nTheme Worlds expects official levels with a worldKey.';
      default:
        return 'No official levels available yet.';
    }
  }

  _SelectorTheme _themeFor(SortPuzzleVariant variant, String modeKey) {
    switch (variant) {
      case SortPuzzleVariant.color:
        switch (modeKey) {
          case 'move_challenge':
            return const _SelectorTheme(
              skyTop: Color(0xFFFFF0E7),
              skyBottom: Color(0xFFFFFAF3),
              cloudColor: Color(0xFFFFFFFF),
              hillFront: Color(0xFFFFB84C),
              hillMid: Color(0xFFFFD174),
              hillBack: Color(0xFFFFE8AA),
              titleFill: Color(0xFFFF7A1C),
              titleAccent: Color(0xFFFFC84F),
              titleStroke: Color(0xFFFFFFFF),
              subtitleColor: Color(0xFFB55A13),
              statBg: Color(0xFFFFFBF5),
              statBorder: Color(0xFFFFE0BD),
              statIconBg: Color(0xFFFFEDD8),
              tileTop: Color(0xFFFFB53B),
              tileBottom: Color(0xFFFF8E16),
              tileBorder: Color(0xFFFFD369),
              tileInnerGlow: Color(0xFFFFE089),
              tileShadow: Color(0x33D47500),
              lockedTop: Color(0xFFCBB9A7),
              lockedBottom: Color(0xFFB39E8C),
              lockedBorder: Color(0xFFEADCCF),
              currentRing: Color(0xFFFFFFFF),
              currentGlow: Color(0x55FF9C2D),
              textPrimary: Color(0xFF6B3608),
              textOnTile: Color(0xFFFFFFFF),
              textSecondary: Color(0xFF9F6230),
              starColor: Color(0xFFFFD246),
              starEmpty: Color(0xFFD8C3A6),
              pageDotInactive: Color(0x55DDA56E),
              backButtonBg: Color(0xFFFFFFFF),
              backButtonIcon: Color(0xFF9B501B),
            );
          case 'time_challenge':
            return const _SelectorTheme(
              skyTop: Color(0xFFE8F8FF),
              skyBottom: Color(0xFFF7FDFF),
              cloudColor: Color(0xFFFFFFFF),
              hillFront: Color(0xFF57C3FF),
              hillMid: Color(0xFF9DE0FF),
              hillBack: Color(0xFFCFEFFF),
              titleFill: Color(0xFF1FB9FF),
              titleAccent: Color(0xFF79A3FF),
              titleStroke: Color(0xFFFFFFFF),
              subtitleColor: Color(0xFF2D7498),
              statBg: Color(0xFFF8FDFF),
              statBorder: Color(0xFFD6F0FF),
              statIconBg: Color(0xFFE7F8FF),
              tileTop: Color(0xFF33C8FF),
              tileBottom: Color(0xFF169AE6),
              tileBorder: Color(0xFF93E8FF),
              tileInnerGlow: Color(0xFFA4F0FF),
              tileShadow: Color(0x33238CC9),
              lockedTop: Color(0xFFAEBECA),
              lockedBottom: Color(0xFF94A7B7),
              lockedBorder: Color(0xFFDCE6ED),
              currentRing: Color(0xFFFFFFFF),
              currentGlow: Color(0x5530BFFF),
              textPrimary: Color(0xFF1B4E67),
              textOnTile: Color(0xFFFFFFFF),
              textSecondary: Color(0xFF5B87A0),
              starColor: Color(0xFFFFD456),
              starEmpty: Color(0xFFBDCCD8),
              pageDotInactive: Color(0x555C9FC7),
              backButtonBg: Color(0xFFFFFFFF),
              backButtonIcon: Color(0xFF2D6D8D),
            );
          case 'theme_worlds':
            return const _SelectorTheme(
              skyTop: Color(0xFFF2EEFF),
              skyBottom: Color(0xFFFBF9FF),
              cloudColor: Color(0xFFFFFFFF),
              hillFront: Color(0xFFAE8CFF),
              hillMid: Color(0xFFD1C1FF),
              hillBack: Color(0xFFE8E0FF),
              titleFill: Color(0xFF865DFF),
              titleAccent: Color(0xFFFF8FD7),
              titleStroke: Color(0xFFFFFFFF),
              subtitleColor: Color(0xFF6A4FC4),
              statBg: Color(0xFFF9F6FF),
              statBorder: Color(0xFFE0D8FF),
              statIconBg: Color(0xFFF0EAFF),
              tileTop: Color(0xFFA678FF),
              tileBottom: Color(0xFF784AF9),
              tileBorder: Color(0xFFDABFFF),
              tileInnerGlow: Color(0xFFE1CDFF),
              tileShadow: Color(0x334D29BE),
              lockedTop: Color(0xFFBDB2CB),
              lockedBottom: Color(0xFFA89CB7),
              lockedBorder: Color(0xFFE8E0F0),
              currentRing: Color(0xFFFFFFFF),
              currentGlow: Color(0x558C6AFF),
              textPrimary: Color(0xFF4C2D9A),
              textOnTile: Color(0xFFFFFFFF),
              textSecondary: Color(0xFF7A66B0),
              starColor: Color(0xFFFFD456),
              starEmpty: Color(0xFFC8BFDA),
              pageDotInactive: Color(0x557D66C0),
              backButtonBg: Color(0xFFFFFFFF),
              backButtonIcon: Color(0xFF6D4FC6),
            );
          case 'classic_journey':
          default:
            return const _SelectorTheme(
              skyTop: Color(0xFFE7F8FF),
              skyBottom: Color(0xFFF7FDFF),
              cloudColor: Color(0xFFFFFFFF),
              hillFront: Color(0xFF89DD52),
              hillMid: Color(0xFFB5EE82),
              hillBack: Color(0xFFD8F8AF),
              titleFill: Color(0xFFF54AA4),
              titleAccent: Color(0xFFFF9E4B),
              titleStroke: Color(0xFFFFFFFF),
              subtitleColor: Color(0xFF58799A),
              statBg: Color(0xFFFFFEFF),
              statBorder: Color(0xFFDCEBF5),
              statIconBg: Color(0xFFF2F7FF),
              tileTop: Color(0xFFFFB130),
              tileBottom: Color(0xFFFF8716),
              tileBorder: Color(0xFFFFD76A),
              tileInnerGlow: Color(0xFFFFE18A),
              tileShadow: Color(0x33D46A00),
              lockedTop: Color(0xFFB9C3CF),
              lockedBottom: Color(0xFF97A6B8),
              lockedBorder: Color(0xFFDDE5EC),
              currentRing: Color(0xFFFFFFFF),
              currentGlow: Color(0x55FF9E30),
              textPrimary: Color(0xFF30566D),
              textOnTile: Color(0xFF5E2400),
              textSecondary: Color(0xFF6F8EAC),
              starColor: Color(0xFFFFC93C),
              starEmpty: Color(0xFFC4D0DB),
              pageDotInactive: Color(0x555F8BB4),
              backButtonBg: Color(0xFFFFFFFF),
              backButtonIcon: Color(0xFF3A6A84),
            );
        }
      case SortPuzzleVariant.ball:
        return const _SelectorTheme(
          skyTop: Color(0xFF09143C),
          skyBottom: Color(0xFF18265F),
          cloudColor: Color(0x16FFFFFF),
          hillFront: Color(0xFF2341A4),
          hillMid: Color(0xFF2B57C5),
          hillBack: Color(0xFF18307D),
          titleFill: Color(0xFF59D4FF),
          titleAccent: Color(0xFFAD78FF),
          titleStroke: Color(0xFFF0FFFF),
          subtitleColor: Color(0xFFD1E0FF),
          statBg: Color(0x22173572),
          statBorder: Color(0x334D77FF),
          statIconBg: Color(0x2A5DA3FF),
          tileTop: Color(0xFF57D4FF),
          tileBottom: Color(0xFF2C8EFF),
          tileBorder: Color(0xFFBDEBFF),
          tileInnerGlow: Color(0xFFA9EEFF),
          tileShadow: Color(0x33219FFF),
          lockedTop: Color(0xFF7788A7),
          lockedBottom: Color(0xFF5F6F8E),
          lockedBorder: Color(0xFF9AAACC),
          currentRing: Color(0xFFFFFFFF),
          currentGlow: Color(0x5546D0FF),
          textPrimary: Color(0xFFFFFFFF),
          textOnTile: Color(0xFFFFFFFF),
          textSecondary: Color(0xCCFFFFFF),
          starColor: Color(0xFFFFD456),
          starEmpty: Color(0x668EA6CF),
          pageDotInactive: Color(0x555B79C2),
          backButtonBg: Color(0x2219367A),
          backButtonIcon: Color(0xFFFFFFFF),
        );
      case SortPuzzleVariant.water:
        return const _SelectorTheme(
          skyTop: Color(0xFF081C54),
          skyBottom: Color(0xFF14377C),
          cloudColor: Color(0x16FFFFFF),
          hillFront: Color(0xFF0D68B6),
          hillMid: Color(0xFF1592D1),
          hillBack: Color(0xFF0E4A90),
          titleFill: Color(0xFF31D4FF),
          titleAccent: Color(0xFF7EB9FF),
          titleStroke: Color(0xFFE9FFFF),
          subtitleColor: Color(0xFFC3EAFF),
          statBg: Color(0x2215407A),
          statBorder: Color(0x334BB0FF),
          statIconBg: Color(0x263AA8FF),
          tileTop: Color(0xFF2BCAFF),
          tileBottom: Color(0xFF1587E6),
          tileBorder: Color(0xFF9CE7FF),
          tileInnerGlow: Color(0xFF99F0FF),
          tileShadow: Color(0x33278DD8),
          lockedTop: Color(0xFF7087A6),
          lockedBottom: Color(0xFF5A7191),
          lockedBorder: Color(0xFF93ABCA),
          currentRing: Color(0xFFFFFFFF),
          currentGlow: Color(0x5533C5FF),
          textPrimary: Color(0xFFFFFFFF),
          textOnTile: Color(0xFFFFFFFF),
          textSecondary: Color(0xCCFFFFFF),
          starColor: Color(0xFFFFD456),
          starEmpty: Color(0x668EA6CF),
          pageDotInactive: Color(0x555B79C2),
          backButtonBg: Color(0x22153D74),
          backButtonIcon: Color(0xFFFFFFFF),
        );
      case SortPuzzleVariant.sand:
        return const _SelectorTheme(
          skyTop: Color(0xFFFFF3DB),
          skyBottom: Color(0xFFFFFBF0),
          cloudColor: Color(0xFFFFFFFF),
          hillFront: Color(0xFFEFB85D),
          hillMid: Color(0xFFF6D985),
          hillBack: Color(0xFFFBE9B5),
          titleFill: Color(0xFFE78B24),
          titleAccent: Color(0xFFFFC34A),
          titleStroke: Color(0xFFFFFFFF),
          subtitleColor: Color(0xFF986024),
          statBg: Color(0xFFFFF9ED),
          statBorder: Color(0xFFF0D6A4),
          statIconBg: Color(0xFFFFEECC),
          tileTop: Color(0xFFF2A43A),
          tileBottom: Color(0xFFD9861A),
          tileBorder: Color(0xFFFFD76E),
          tileInnerGlow: Color(0xFFFFDE7B),
          tileShadow: Color(0x33D78B21),
          lockedTop: Color(0xFFCAB699),
          lockedBottom: Color(0xFFB19B7D),
          lockedBorder: Color(0xFFEADCC7),
          currentRing: Color(0xFFFFFFFF),
          currentGlow: Color(0x55F39B29),
          textPrimary: Color(0xFF704213),
          textOnTile: Color(0xFFFFFFFF),
          textSecondary: Color(0xFF9C6E35),
          starColor: Color(0xFFFFD456),
          starEmpty: Color(0xFFD5BF95),
          pageDotInactive: Color(0x55D1AA63),
          backButtonBg: Color(0xFFFFFFFF),
          backButtonIcon: Color(0xFF8A551B),
        );
      case SortPuzzleVariant.bird:
        return const _SelectorTheme(
          skyTop: Color(0xFFE7FAFF),
          skyBottom: Color(0xFFF8FEFF),
          cloudColor: Color(0xFFFFFFFF),
          hillFront: Color(0xFF8ADF8B),
          hillMid: Color(0xFFB6F0A0),
          hillBack: Color(0xFFD6F9BF),
          titleFill: Color(0xFF15A9FF),
          titleAccent: Color(0xFF4FD26B),
          titleStroke: Color(0xFFFFFFFF),
          subtitleColor: Color(0xFF437A6C),
          statBg: Color(0xFFF5FFFB),
          statBorder: Color(0xFFD8F0E3),
          statIconBg: Color(0xFFE7FFF0),
          tileTop: Color(0xFF26B8FF),
          tileBottom: Color(0xFF158EE0),
          tileBorder: Color(0xFFA6EAFF),
          tileInnerGlow: Color(0xFFA5F1FF),
          tileShadow: Color(0x33239FE1),
          lockedTop: Color(0xFFA1B8B3),
          lockedBottom: Color(0xFF89A09C),
          lockedBorder: Color(0xFFD5E7E2),
          currentRing: Color(0xFFFFFFFF),
          currentGlow: Color(0x5528C4FF),
          textPrimary: Color(0xFF27655A),
          textOnTile: Color(0xFFFFFFFF),
          textSecondary: Color(0xFF5F9588),
          starColor: Color(0xFFFFD456),
          starEmpty: Color(0xFFC3D9D3),
          pageDotInactive: Color(0x5574B9A9),
          backButtonBg: Color(0xFFFFFFFF),
          backButtonIcon: Color(0xFF3A7C71),
        );
    }
  }
}

class _BackButtonBubble extends StatelessWidget {
  const _BackButtonBubble({
    required this.theme,
  });

  final _SelectorTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: theme.backButtonBg,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.tileShadow.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Icon(
          Icons.arrow_back_rounded,
          color: theme.backButtonIcon,
        ),
      ),
    );
  }
}

class _SelectLevelTitle extends StatelessWidget {
  const _SelectLevelTitle({
    required this.theme,
  });

  final _SelectorTheme theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Transform.translate(
          offset: const Offset(0, 4),
          child: Text(
            'SELECT LEVEL',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: theme.titleAccent.withOpacity(0.40),
            ),
          ),
        ),
        Text(
          'SELECT LEVEL',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = theme.titleStroke,
          ),
        ),
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: <Color>[theme.titleFill, theme.titleAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds);
          },
          child: const Text(
            'SELECT LEVEL',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopStatsRow extends StatelessWidget {
  const _TopStatsRow({
    required this.completedCount,
    required this.totalLevels,
    required this.totalStars,
    required this.currentLevelNumber,
    required this.theme,
  });

  final int completedCount;
  final int totalLevels;
  final int totalStars;
  final int currentLevelNumber;
  final _SelectorTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatBubble(
            icon: Icons.check_circle_rounded,
            text: '$completedCount/$totalLevels',
            iconColor: theme.titleFill,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBubble(
            icon: Icons.star_rounded,
            text: '$totalStars',
            iconColor: theme.starColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatBubble(
            icon: Icons.play_arrow_rounded,
            text: 'Lv $currentLevelNumber',
            iconColor: theme.titleAccent,
            theme: theme,
          ),
        ),
      ],
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.theme,
  });

  final IconData icon;
  final String text;
  final Color iconColor;
  final _SelectorTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: theme.statBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.statBorder),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.tileShadow.withOpacity(0.14),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.statIconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelGridPage extends StatelessWidget {
  const _LevelGridPage({
    required this.theme,
    required this.visibleLevels,
    required this.startIndex,
    required this.unlockedStep,
    required this.starsByLevel,
    required this.onTap,
  });

  final _SelectorTheme theme;
  final List<SortLevel> visibleLevels;
  final int startIndex;
  final int unlockedStep;
  final Map<int, int> starsByLevel;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleLevels.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, localIndex) {
        final SortLevel level = visibleLevels[localIndex];
        final int globalIndex = startIndex + localIndex;
        final int step = globalIndex + 1;
        final bool locked = step > unlockedStep;
        final bool current = step == unlockedStep && !locked;
        final int stars = starsByLevel[level.levelNumber] ?? 0;

        return _GlossyLevelTile(
          theme: theme,
          levelNumber: level.levelNumber,
          stars: stars,
          locked: locked,
          current: current,
          onTap: locked ? null : () => onTap(globalIndex),
        );
      },
    );
  }
}

class _GlossyLevelTile extends StatelessWidget {
  const _GlossyLevelTile({
    required this.theme,
    required this.levelNumber,
    required this.stars,
    required this.locked,
    required this.current,
    required this.onTap,
  });

  final _SelectorTheme theme;
  final int levelNumber;
  final int stars;
  final bool locked;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final List<Color> fillColors = locked
        ? <Color>[theme.lockedTop, theme.lockedBottom]
        : <Color>[theme.tileTop, theme.tileBottom];

    final Color borderColor = locked ? theme.lockedBorder : theme.tileBorder;

    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                3,
                    (int index) => Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 1),
                  child: Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 12,
                    color: index < stars ? theme.starColor : theme.starEmpty,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: fillColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: current ? theme.currentRing : borderColor,
                  width: current ? 3 : 2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: theme.tileShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                  if (current)
                    BoxShadow(
                      color: theme.currentGlow,
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 7,
                    right: 7,
                    top: 6,
                    child: Container(
                      height: 11,
                      decoration: BoxDecoration(
                        color: locked
                            ? Colors.white.withOpacity(0.18)
                            : theme.tileInnerGlow.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Center(
                    child: locked
                        ? const Icon(
                      Icons.lock_rounded,
                      color: Colors.white,
                      size: 24,
                    )
                        : Text(
                      '$levelNumber',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.textOnTile,
                        shadows: const <Shadow>[
                          Shadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (current)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: theme.currentGlow,
                              blurRadius: 7,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
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

class _NextLevelSheet extends StatelessWidget {
  const _NextLevelSheet({
    required this.nextLevel,
    required this.accent,
  });

  final int nextLevel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.emoji_events_rounded,
                color: accent,
                size: 34,
              ),
              const SizedBox(height: 10),
              const Text(
                'Level Complete',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Go to Level $nextLevel?',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                      ),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameSelectorBackground extends StatelessWidget {
  const _GameSelectorBackground({
    required this.theme,
  });

  final _SelectorTheme theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[theme.skyTop, theme.skyBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 92,
          left: 12,
          child: _cloud(110, 42, 0.88),
        ),
        Positioned(
          top: 148,
          right: 8,
          child: _cloud(132, 46, 0.82),
        ),
        Positioned(
          top: 210,
          left: 70,
          child: _cloud(92, 34, 0.76),
        ),
        Positioned(
          top: 254,
          right: 56,
          child: _cloud(84, 30, 0.70),
        ),
        Positioned(
          bottom: 90,
          left: -24,
          right: -24,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: theme.hillBack,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(180),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 54,
          left: -18,
          right: -18,
          child: Container(
            height: 132,
            decoration: BoxDecoration(
              color: theme.hillMid,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(200),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 18,
          left: -6,
          right: -6,
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: theme.hillFront,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(160),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cloud(double width, double height, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.cloudColor,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.white.withOpacity(0.26),
              blurRadius: 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectorTheme {
  const _SelectorTheme({
    required this.skyTop,
    required this.skyBottom,
    required this.cloudColor,
    required this.hillFront,
    required this.hillMid,
    required this.hillBack,
    required this.titleFill,
    required this.titleAccent,
    required this.titleStroke,
    required this.subtitleColor,
    required this.statBg,
    required this.statBorder,
    required this.statIconBg,
    required this.tileTop,
    required this.tileBottom,
    required this.tileBorder,
    required this.tileInnerGlow,
    required this.tileShadow,
    required this.lockedTop,
    required this.lockedBottom,
    required this.lockedBorder,
    required this.currentRing,
    required this.currentGlow,
    required this.textPrimary,
    required this.textOnTile,
    required this.textSecondary,
    required this.starColor,
    required this.starEmpty,
    required this.pageDotInactive,
    required this.backButtonBg,
    required this.backButtonIcon,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color cloudColor;

  final Color hillFront;
  final Color hillMid;
  final Color hillBack;

  final Color titleFill;
  final Color titleAccent;
  final Color titleStroke;
  final Color subtitleColor;

  final Color statBg;
  final Color statBorder;
  final Color statIconBg;

  final Color tileTop;
  final Color tileBottom;
  final Color tileBorder;
  final Color tileInnerGlow;
  final Color tileShadow;

  final Color lockedTop;
  final Color lockedBottom;
  final Color lockedBorder;

  final Color currentRing;
  final Color currentGlow;

  final Color textPrimary;
  final Color textOnTile;
  final Color textSecondary;

  final Color starColor;
  final Color starEmpty;
  final Color pageDotInactive;

  final Color backButtonBg;
  final Color backButtonIcon;
}