import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'routing/route_names.dart';

class GameBoxApp extends StatelessWidget {
  const GameBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5B67F1),
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      ),
      initialRoute: RouteNames.authGate,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}