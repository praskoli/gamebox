import 'package:flutter/material.dart';

import '../../game_engine/community/community_creations_screen.dart';
import '../../game_engine/community/community_leaderboard_screen.dart';
import '../../game_engine/community/my_projects_screen.dart';
import '../../game_engine/catalog/game_routes.dart';
import '../../games/memory_match/presentation/memory_game_screen.dart';
import '../../games/memory_match/presentation/memory_world_map_screen.dart';
import '../../platform/auth/auth_gate.dart';
import '../../platform/auth/login_screen.dart';
import '../../platform/profile/settings_screen.dart';
import '../../story_creator/domain/scene_model.dart';
import '../../story_creator/domain/story_model.dart';
import '../../story_creator/presentation/story_player_screen.dart';
import '../../story_creator/presentation/story_review_screen.dart';
import '../navigation/main_bottom_nav_screen.dart';
import 'route_names.dart';

class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get routes {
    return {
      RouteNames.authGate: (_) => const AuthGate(),
      RouteNames.login: (_) => const LoginScreen(),
      RouteNames.home: (_) => const MainBottomNavScreen(),

      RouteNames.myProjects: (_) => const MyProjectsScreen(),
      RouteNames.community: (_) => const CommunityCreationsScreen(),
      RouteNames.leaderboard: (_) => const CommunityLeaderboardScreen(),
      RouteNames.settings: (_) => const SettingsScreen(),

      RouteNames.storyReview: (_) => const StoryReviewScreen(),

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

    if (settings.name == RouteNames.storyPlayer) {
      final args = settings.arguments as Map<String, dynamic>? ?? {};

      final StoryModel? story = args['story'] as StoryModel?;
      final List<SceneModel>? scenes = args['scenes'] as List<SceneModel>?;

      if (story == null || scenes == null) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Story Error')),
            body: const Center(
              child: Text('Story data missing for StoryPlayerScreen'),
            ),
          ),
        );
      }

      return MaterialPageRoute(
        builder: (_) => StoryPlayerScreen(
          story: story,
          scenes: scenes,
        ),
      );
    }

    return null;
  }
}
