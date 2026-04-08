import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../platform/profile/settings_screen.dart';
import '../../game_engine/catalog/diy_game_studio_entry_screen.dart';
import '../../game_engine/catalog/featured_games_screen.dart';
import '../home/home_tab_screen.dart';
import '../home/home_view_model.dart';
import '../../platform/profile/player_profile_tab_screen.dart';
import '../../game_engine/community/community_creations_screen.dart';

class MainBottomNavScreen extends StatefulWidget {
  const MainBottomNavScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainBottomNavScreen> createState() => _MainBottomNavScreenState();
}

class _MainBottomNavScreenState extends State<MainBottomNavScreen> {
  late int _currentIndex;
  late final PageController _pageController;

  final GlobalKey<CommunityCreationsScreenState> _creatorTabKey =
  GlobalKey<CommunityCreationsScreenState>();

  static const List<String> _titles = <String>[
    'Home',
    'Play',
    'DIY Game Studio',
    '',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  PreferredSizeWidget? _buildAppBar(HomeViewModel vm) {
    if (_currentIndex == 2) {
      return null;
    }

    return AppBar(
      title: _currentIndex == 3
          ? null
          : _BoldAppBarTitle(_titles[_currentIndex]),
      actions: [
        if (_currentIndex != 4 && _currentIndex != 3)
          IconButton(
            onPressed: vm.refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        if (_currentIndex == 3)
          IconButton(
            onPressed: () {
              _creatorTabKey.currentState?.refreshCreatorFeed();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        if (_currentIndex == 4)
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<HomeViewModel>.value(
                    value: vm,
                    child: const SettingsScreen(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          ),
      ],
    );
  }

  void _goToPage(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel()..initialize(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: _buildAppBar(vm),

            // ✅ FULL SWIPE ENABLED
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                const HomeTabScreen(),
                const FeaturedGamesScreen(),
                const DiyGameStudioEntryScreen(),
                CommunityCreationsScreen(
                  key: _creatorTabKey,
                  showScaffold: false,
                  showInlineHeader: false,
                ),
                const PlayerProfileTabScreen(),
              ],
            ),

            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _goToPage,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_esports_rounded),
                  selectedIcon: Icon(Icons.sports_esports_rounded),
                  label: 'Play',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_rounded),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: 'DIY',
                ),
                NavigationDestination(
                  icon: Icon(Icons.public_rounded),
                  selectedIcon: Icon(Icons.public_rounded),
                  label: 'Creator',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BoldAppBarTitle extends StatelessWidget {
  const _BoldAppBarTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Color(0xFF111827), // dark text
        shadows: [
          Shadow(
            color: Color(0xFF9D4DFF), // neon purple glow
            blurRadius: 6,
          ),
          Shadow(
            color: Color(0xFFEC4899), // neon pink glow
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}