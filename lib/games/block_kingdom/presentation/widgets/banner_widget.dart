import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  final String primaryText;
  final String secondaryText;
  final Color color;
  final int score;
  final bool scorePulse;
  final int scoreGain;

  const BannerWidget({
    super.key,
    required this.primaryText,
    required this.secondaryText,
    required this.color,
    required this.score,
    required this.scorePulse,
    required this.scoreGain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedScale(
          scale: scorePulse ? 1.06 : 1,
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF172033),
                  Color(0xFF0E1320),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.07),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD36B),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                if (scoreGain > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    '+$scoreGain',
                    style: const TextStyle(
                      color: Color(0xFF84FFD2),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          child: primaryText.isEmpty
              ? const SizedBox(
            key: ValueKey('empty-banner'),
            height: 52,
          )
              : Container(
            key: ValueKey(primaryText + secondaryText),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withOpacity(0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  primaryText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                if (secondaryText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondaryText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color.withOpacity(0.9),
                      fontSize: 12.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}