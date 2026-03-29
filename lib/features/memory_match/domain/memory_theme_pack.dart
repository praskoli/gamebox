import 'package:flutter/material.dart';

class MemoryThemePack {
  const MemoryThemePack({
    required this.id,
    required this.title,
    required this.worldTitle,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.pathColor,
    required this.nodeColor,
    required this.tileGradientStart,
    required this.tileGradientEnd,
    required this.items,
    required this.worldEmoji,
  });

  final String id;
  final String title;
  final String worldTitle;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color pathColor;
  final Color nodeColor;
  final Color tileGradientStart;
  final Color tileGradientEnd;
  final List<String> items;
  final String worldEmoji;
}