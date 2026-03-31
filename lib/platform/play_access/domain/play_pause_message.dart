import 'package:flutter/material.dart';

enum PlayPauseMessageVariant {
  warning,
  breakRequired,
  bonusRequest,
  familyGuidance,
}

enum PlayPauseAnimationStyle {
  recharge,
  familyUnlock,
  confidencePause,
  familyTeam,
}

class PlayPauseMessage {
  const PlayPauseMessage({
    required this.title,
    required this.message,
    required this.variant,
    required this.animationStyle,
    required this.icon,
    required this.gradientColors,
  });

  final String title;
  final String message;
  final PlayPauseMessageVariant variant;
  final PlayPauseAnimationStyle animationStyle;
  final IconData icon;
  final List<Color> gradientColors;
}