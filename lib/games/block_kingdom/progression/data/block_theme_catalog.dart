import 'package:flutter/material.dart';

import '../domain/block_theme_config.dart';

class BlockThemeCatalog {
  const BlockThemeCatalog._();

  static const BlockThemeConfig forest = BlockThemeConfig(
    id: 'forest',
    name: 'Forest',
    screenGradient: [
      Color(0xFF0B1F16),
      Color(0xFF153526),
      Color(0xFF1E4D32),
    ],
    boardGradient: [
      Color(0xFF10271D),
      Color(0xFF173324),
    ],
    trayGradient: [
      Color(0xFF1D3B2B),
      Color(0xFF2A5B40),
    ],
    accent: Color(0xFF6EE7A2),
    filledColors: [
      Color(0xFFB8F28A),
      Color(0xFF71D16D),
      Color(0xFF33A852),
    ],
    emptyColors: [
      Color(0xFF42584C),
      Color(0xFF32453A),
    ],
  );

  static const BlockThemeConfig desert = BlockThemeConfig(
    id: 'desert',
    name: 'Desert',
    screenGradient: [
      Color(0xFF2A1B0E),
      Color(0xFF593617),
      Color(0xFF7A4A1F),
    ],
    boardGradient: [
      Color(0xFF342113),
      Color(0xFF4C2F18),
    ],
    trayGradient: [
      Color(0xFF6C431F),
      Color(0xFF9A5E2C),
    ],
    accent: Color(0xFFFFD36B),
    filledColors: [
      Color(0xFFFFE08A),
      Color(0xFFFFB74D),
      Color(0xFFFF8A00),
    ],
    emptyColors: [
      Color(0xFF5E4A3A),
      Color(0xFF4D3B2D),
    ],
  );

  static const BlockThemeConfig neon = BlockThemeConfig(
    id: 'neon',
    name: 'Neon',
    screenGradient: [
      Color(0xFF0A1020),
      Color(0xFF131A35),
      Color(0xFF1B2350),
    ],
    boardGradient: [
      Color(0xFF101735),
      Color(0xFF0D1430),
    ],
    trayGradient: [
      Color(0xFF312A74),
      Color(0xFF5A3FC0),
    ],
    accent: Color(0xFF7CF3FF),
    filledColors: [
      Color(0xFF8AF7FF),
      Color(0xFF56D9FF),
      Color(0xFF8B5CF6),
    ],
    emptyColors: [
      Color(0xFF46507A),
      Color(0xFF363F67),
    ],
  );

  static BlockThemeConfig forLevel(int level) {
    if (level <= 10) return forest;
    if (level <= 20) return desert;
    return neon;
  }
}