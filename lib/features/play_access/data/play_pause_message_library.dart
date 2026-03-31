import 'package:flutter/material.dart';

import '../domain/play_pause_message.dart';

class PlayPauseMessageLibrary {
  const PlayPauseMessageLibrary._();

  static const List<PlayPauseMessage> breakReminders = [
    PlayPauseMessage(
      title: 'Great job!',
      message: 'Let’s pause for a quick recharge.',
      variant: PlayPauseMessageVariant.warning,
      animationStyle: PlayPauseAnimationStyle.recharge,
      icon: Icons.spa_rounded,
      gradientColors: [Color(0xFF14B8A6), Color(0xFF5EEAD4)],
    ),
    PlayPauseMessage(
      title: 'Break time!',
      message: 'You’ve played 5 levels — time to stretch and relax.',
      variant: PlayPauseMessageVariant.breakRequired,
      animationStyle: PlayPauseAnimationStyle.recharge,
      icon: Icons.self_improvement_rounded,
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF93C5FD)],
    ),
    PlayPauseMessage(
      title: 'Amazing progress!',
      message: 'A short break keeps you sharp.',
      variant: PlayPauseMessageVariant.warning,
      animationStyle: PlayPauseAnimationStyle.confidencePause,
      icon: Icons.auto_awesome_rounded,
      gradientColors: [Color(0xFFF59E0B), Color(0xFFFDE68A)],
    ),
    PlayPauseMessage(
      title: 'Eye rest time',
      message: 'Your eyes deserve a rest — let’s take one now.',
      variant: PlayPauseMessageVariant.breakRequired,
      animationStyle: PlayPauseAnimationStyle.recharge,
      icon: Icons.visibility_rounded,
      gradientColors: [Color(0xFF6366F1), Color(0xFFA5B4FC)],
    ),
    PlayPauseMessage(
      title: 'Healthy pause',
      message: 'Balance is power — let’s rest and come back stronger.',
      variant: PlayPauseMessageVariant.familyGuidance,
      animationStyle: PlayPauseAnimationStyle.familyTeam,
      icon: Icons.favorite_rounded,
      gradientColors: [Color(0xFFEC4899), Color(0xFFF9A8D4)],
    ),
  ];

  static const List<PlayPauseMessage> bonusRequests = [
    PlayPauseMessage(
      title: 'Want extra play?',
      message: 'Ask your parent for bonus time.',
      variant: PlayPauseMessageVariant.bonusRequest,
      animationStyle: PlayPauseAnimationStyle.familyUnlock,
      icon: Icons.lock_open_rounded,
      gradientColors: [Color(0xFF5B67F1), Color(0xFF8B5CF6)],
    ),
    PlayPauseMessage(
      title: 'Today’s limit reached',
      message: 'Request more with parent approval.',
      variant: PlayPauseMessageVariant.bonusRequest,
      animationStyle: PlayPauseAnimationStyle.familyUnlock,
      icon: Icons.family_restroom_rounded,
      gradientColors: [Color(0xFFF97316), Color(0xFFFDBA74)],
    ),
    PlayPauseMessage(
      title: 'Bonus time awaits',
      message: 'Extra fun is a family choice — request it now.',
      variant: PlayPauseMessageVariant.familyGuidance,
      animationStyle: PlayPauseAnimationStyle.familyTeam,
      icon: Icons.card_giftcard_rounded,
      gradientColors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
    ),
    PlayPauseMessage(
      title: 'Nothing is lost',
      message: 'Your progress is safe — parents can unlock more play.',
      variant: PlayPauseMessageVariant.familyGuidance,
      animationStyle: PlayPauseAnimationStyle.confidencePause,
      icon: Icons.shield_rounded,
      gradientColors: [Color(0xFF06B6D4), Color(0xFF67E8F9)],
    ),
  ];

  static PlayPauseMessage pickBreakMessage(int seed) {
    return breakReminders[seed % breakReminders.length];
  }

  static PlayPauseMessage pickBonusMessage(int seed) {
    return bonusRequests[seed % bonusRequests.length];
  }
}