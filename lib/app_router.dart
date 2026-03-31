import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_screen.dart';
import 'features/games/game_routes.dart';
import 'features/memory_match/presentation/memory_game_screen.dart';
import 'features/memory_match/presentation/memory_world_map_screen.dart';
import 'features/navigation/main_bottom_nav_screen.dart';
import 'route_names.dart';

class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get routes {
    return {
      RouteNames.authGate: (_) => const AuthGate(),
      RouteNames.login: (_) => const LoginScreen(),
      RouteNames.home: (_) => const MainBottomNavScreen(),
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