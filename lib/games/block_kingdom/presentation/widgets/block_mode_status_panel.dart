import 'package:flutter/material.dart';

import '../../domain/block_mode.dart';

class BlockModeStatusPanel extends StatelessWidget {
  const BlockModeStatusPanel({
    super.key,
    required this.mode,
    required this.levelLabel,
    required this.objectiveTitle,
    required this.progressText,
    required this.primaryProgress,
    required this.secondaryProgress,
    required this.timerLabel,
    required this.showTimer,
    required this.rewardLabel,
  });

  final BlockMode mode;
  final String levelLabel;
  final String objectiveTitle;
  final String progressText;
  final double primaryProgress;
  final double secondaryProgress;
  final String timerLabel;
  final bool showTimer;
  final String rewardLabel;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForMode(mode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF151F37),
            Color(0xFF0E172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _ModeBadge(mode: mode, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  levelLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (showTimer)
                _TimerChip(
                  label: timerLabel,
                  accent: accent,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.flag_rounded,
                  label: 'Objective',
                  value: objectiveTitle,
                  accent: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Reward',
                  value: rewardLabel,
                  accent: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              progressText,
              style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: primaryProgress.clamp(0.0, 1.0),
              minHeight: 11,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (secondaryProgress > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: secondaryProgress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _accentForMode(BlockMode mode) {
    switch (mode) {
      case BlockMode.kingdom:
        return const Color(0xFFF59E0B);
      case BlockMode.endless:
        return const Color(0xFF14B8A6);
      case BlockMode.timeTrial:
        return const Color(0xFF8B5CF6);
    }
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({
    required this.mode,
    required this.accent,
  });

  final BlockMode mode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mode) {
      BlockMode.kingdom => Icons.emoji_events_rounded,
      BlockMode.endless => Icons.all_inclusive_rounded,
      BlockMode.timeTrial => Icons.timer_rounded,
    };

    final label = switch (mode) {
      BlockMode.kingdom => 'Kingdom',
      BlockMode.endless => 'Endless',
      BlockMode.timeTrial => 'Time Trial',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withOpacity(0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withOpacity(0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, color: accent, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.64),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}