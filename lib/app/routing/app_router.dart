import 'package:flutter/material.dart';
import '../../game_engine/community/my_projects_screen.dart';
import '../../game_engine/community/community_creations_screen.dart';
import '../../platform/profile/settings_screen.dart';
import '../../platform/auth/auth_gate.dart';
import '../../platform/auth/login_screen.dart';
import '../../game_engine/catalog/game_routes.dart';
import '../../games/memory_match/presentation/memory_game_screen.dart';
import '../../games/memory_match/presentation/memory_world_map_screen.dart';
import '../navigation/main_bottom_nav_screen.dart';
import 'route_names.dart';
import '../../game_engine/community/community_leaderboard_screen.dart';
class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get routes {
    return {
      RouteNames.authGate: (_) => const AuthGate(),
      RouteNames.login: (_) => const LoginScreen(),
      RouteNames.home: (_) => const MainBottomNavScreen(),

      // ✅ NEW
      RouteNames.myProjects: (_) => const MyProjectsScreen(),
      RouteNames.community: (_) => const CommunityCreationsScreen(),
      RouteNames.settings: (_) => const SettingsScreen(),
      RouteNames.leaderboard: (_) => const CommunityLeaderboardScreen(),
      GameRoutes.memoryWorldMap: (_) => const MemoryWorldMapScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == GameRoutes.memoryGame) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      return MaterialPageRoute(
        builder: (_) => MemoryGameScreen(
          worldId: (args['worldId'] ?? '').toString(),
          levelNumber: (args['levelNumber'] as num?)?.toInt() ?? 1,
        ),
      );
    }
    return null;
  }
}