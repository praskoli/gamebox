import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routing/route_names.dart';
import '../../platform/auth/google_sign_in_service.dart';
import '../../game_engine/catalog/diy_games_screen.dart';
import '../../game_engine/catalog/featured_games_screen.dart';
import '../home/home_tab_screen.dart';
import '../home/home_view_model.dart';
import '../../platform/profile/player_profile_tab_screen.dart';
import '../../platform/player/presentation/player_stats_screen.dart';

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

  static const List<String> _titles = <String>[
    'Home',
    'Featured Games',
    'DIY',
    'Player Stats',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
  }

  Future<void> _logout(BuildContext context) async {
    await GoogleSignInService.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteNames.login,
          (route) => false,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel()..initialize(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_titles[_currentIndex]),
              actions: [
                if (_currentIndex != 4)
                  IconButton(
                    onPressed: vm.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                  ),
                if (_currentIndex == 4)
                  IconButton(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Logout',
                  ),
              ],
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: const [
                HomeTabScreen(),
                FeaturedGamesScreen(),
                DiyGamesScreen(),
                PlayerStatsScreen(),
                PlayerProfileTabScreen(),
              ],
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.sports_esports_rounded),
                  selectedIcon: Icon(Icons.sports_esports_rounded),
                  label: 'Featured',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_awesome_rounded),
                  selectedIcon: Icon(Icons.auto_awesome_rounded),
                  label: 'DIY',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_rounded),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Stats',
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