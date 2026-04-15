import 'package:flutter/material.dart';

class SortPuzzleHud extends StatelessWidget {
  const SortPuzzleHud({
    super.key,
    required this.levelTitle,
    required this.subtitle,
    required this.moves,
    required this.elapsedText,
    required this.onUndo,
    required this.onHint,
    required this.onRestart,
    required this.canUndo,
    required this.canHint,
    required this.accentColor,
    required this.dark,
  });

  final String levelTitle;
  final String subtitle;
  final int moves;
  final String elapsedText;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onRestart;
  final bool canUndo;
  final bool canHint;
  final Color accentColor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color text = dark ? Colors.white : const Color(0xFF0F172A);
    final Color sub = dark
        ? Colors.white.withOpacity(0.74)
        : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                levelTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  color: text,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            _MiniStatPill(
              label: 'Moves',
              value: '$moves',
              dark: dark,
            ),
            const SizedBox(width: 8),
            _MiniStatPill(
              label: 'Time',
              value: elapsedText,
              dark: dark,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: sub,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(
              icon: Icons.undo_rounded,
              label: 'Undo',
              enabled: canUndo,
              onTap: onUndo,
              filled: false,
              accentColor: accentColor,
              dark: dark,
            ),
            _ActionChip(
              icon: Icons.lightbulb_rounded,
              label: 'Hint',
              enabled: canHint,
              onTap: onHint,
              filled: false,
              accentColor: accentColor,
              dark: dark,
            ),
            _ActionChip(
              icon: Icons.replay_rounded,
              label: 'Restart',
              enabled: true,
              onTap: onRestart,
              filled: true,
              accentColor: accentColor,
              dark: dark,
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({
    required this.label,
    required this.value,
    required this.dark,
  });

  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? Colors.white.withOpacity(0.12) : const Color(0xFFDDE3F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white.withOpacity(0.72) : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: dark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.filled,
    required this.accentColor,
    required this.dark,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool filled;
  final Color accentColor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final Color fg = filled
        ? Colors.white
        : (dark ? Colors.white : accentColor);

    final Color bg = filled
        ? accentColor
        : (dark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.74));

    return Opacity(
      opacity: enabled ? 1 : 0.35,
      child: IgnorePointer(
        ignoring: !enabled,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: filled
                  ? null
                  : Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.14)
                    : accentColor.withOpacity(0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: fg, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}