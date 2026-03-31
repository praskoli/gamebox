import 'package:flutter/material.dart';

import '../../../../platform/play_access/data/play_pause_message_library.dart';
import '../../domain/play_pause_message.dart';
import '../../../../platform/play_access/presentation/widgets/animated_play_pause_message_card.dart';

class GameBreakOverlay extends StatelessWidget {
  const GameBreakOverlay({
    super.key,
    required this.seed,
    required this.isBreakRequired,
    required this.onPrimaryAction,
    this.onSecondaryAction,
  });

  final int seed;
  final bool isBreakRequired;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final PlayPauseMessage message = isBreakRequired
        ? PlayPauseMessageLibrary.pickBreakMessage(seed)
        : PlayPauseMessageLibrary.pickBonusMessage(seed);

    return AnimatedPlayPauseMessageCard(
      message: message,
      isBlocking: true,
      primaryActionLabel: isBreakRequired ? 'Take a Break' : 'Ask Parent',
      secondaryActionLabel: isBreakRequired ? 'Bonus Time' : 'Not Now',
      onPrimaryAction: onPrimaryAction,
      onSecondaryAction: onSecondaryAction,
    );
  }
}