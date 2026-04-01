import 'package:flutter/material.dart';

class BlockThemeConfig {
  const BlockThemeConfig({
    required this.id,
    required this.name,
    required this.screenGradient,
    required this.boardGradient,
    required this.trayGradient,
    required this.accent,
    required this.filledColors,
    required this.emptyColors,
  });

  final String id;
  final String name;
  final List<Color> screenGradient;
  final List<Color> boardGradient;
  final List<Color> trayGradient;
  final Color accent;
  final List<Color> filledColors;
  final List<Color> emptyColors;
}