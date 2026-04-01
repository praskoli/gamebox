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
          scale: scorePulse ? 1.07 : 1,
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1A2542),
                  Color(0xFF0F1630),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6EE7FF).withOpacity(0.08),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD36B).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD36B),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Score: $score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                if (scoreGain > 0) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF84FFD2).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF84FFD2).withOpacity(0.18),
                      ),
                    ),
                    child: Text(
                      '+$scoreGain',
                      style: const TextStyle(
                        color: Color(0xFF84FFD2),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          child: primaryText.isEmpty
              ? const SizedBox(
            key: ValueKey('empty-banner'),
            height: 58,
          )
              : Container(
            key: ValueKey(primaryText + secondaryText),
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.16),
                  color.withOpacity(0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.34),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.14),
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
                      color: Colors.white.withOpacity(0.86),
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
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