import 'package:flutter/material.dart';

import 'memory_world_config.dart';

@immutable
class MemoryThemePack {
  const MemoryThemePack({
    required this.id,
    required this.title,
    required this.worldTitle,
    required this.emoji,
    required this.worldGradient,
    required this.tileGradient,
    required this.tileAccent,
    required this.glowColor,
    required this.itemPool,
  });

  final String id;
  final String title;
  final String worldTitle;
  final String emoji;
  final List<Color> worldGradient;
  final List<Color> tileGradient;
  final Color tileAccent;
  final Color glowColor;
  final List<String> itemPool;

  Color get primaryColor => worldGradient.first;
  Color get secondaryColor => worldGradient.last;

  Color get backgroundStartColor => worldGradient.first;
  Color get backgroundMiddleColor =>
      worldGradient.length > 2 ? worldGradient[1] : worldGradient.first;
  Color get backgroundEndColor => worldGradient.last;

  Color get backgroundTop => backgroundStartColor;
  Color get backgroundBottom => backgroundEndColor;
  String get worldEmoji => emoji;

  Color get tilePrimary => tileGradient.first;
  Color get tileSecondary => tileGradient.last;

  Color get tileGradientStart => tileGradient.first;
  Color get tileGradientEnd => tileGradient.last;

  Color get nodeColor => tileAccent;
  Color get badgeColor => tileAccent;

  factory MemoryThemePack.fromConfig(
      MemoryWorldConfig config, {
        required List<String> resolvedItemPool,
      }) {
    final List<Color> safeWorldGradient = config.worldGradientHex.isEmpty
        ? const <Color>[
      Color(0xFFE3F2FD),
      Color(0xFF90CAF9),
      Color(0xFF42A5F5),
    ]
        : config.worldGradientHex.map(_colorFromHex).toList(growable: false);

    final List<Color> safeTileGradient = config.tileGradientHex.isEmpty
        ? const <Color>[
      Color(0xFFFFFFFF),
      Color(0xFFE3F2FD),
    ]
        : config.tileGradientHex.map(_colorFromHex).toList(growable: false);

    final List<String> safePool = resolvedItemPool.isEmpty
        ? const <String>['🍎', '🍌', '🍇', '🍊', '🍓', '🥭', '🍍', '🍉']
        : resolvedItemPool;

    return MemoryThemePack(
      id: config.id,
      title: config.title,
      worldTitle: config.worldTitle,
      emoji: config.emoji,
      worldGradient: safeWorldGradient,
      tileGradient: safeTileGradient,
      tileAccent: _colorFromHex(config.tileAccentHex),
      glowColor: _colorFromHex(config.glowColorHex),
      itemPool: safePool,
    );
  }

  static Color _colorFromHex(String rawHex) {
    String hex = rawHex.trim().toUpperCase().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) {
      hex = 'FF1976D2';
    }
    return Color(int.parse(hex, radix: 16));
  }
}