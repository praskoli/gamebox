import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/memory_card_model.dart';
import '../../domain/memory_theme_pack.dart';

class MemoryTile extends StatelessWidget {
  const MemoryTile({
    super.key,
    required this.card,
    required this.themePack,
    required this.onTap,
    this.isWrong = false,
    this.isJustMatched = false,
  });

  final MemoryCardModel card;
  final MemoryThemePack themePack;
  final VoidCallback onTap;
  final bool isWrong;
  final bool isJustMatched;

  @override
  Widget build(BuildContext context) {
    final showFront = card.isFaceUp || card.isMatched;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: showFront ? 1 : 0),
      duration: const Duration(milliseconds: 250),
      builder: (context, value, child) {
        final angle = value * math.pi;
        final isFrontVisible = value >= 0.5;

        return _ShakeWrapper(
          active: isWrong,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              scale: isJustMatched || card.isMatched ? 1.08 : 1,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: isFrontVisible
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _FrontFace(
                    symbol: card.value,
                    themePack: themePack,
                    matched: card.isMatched || isJustMatched,
                    wrong: isWrong,
                  ),
                )
                    : _BackFace(themePack: themePack),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShakeWrapper extends StatelessWidget {
  const _ShakeWrapper({
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: active ? 1 : 0),
      duration: const Duration(milliseconds: 360),
      builder: (context, value, _) {
        final dx = active ? math.sin(value * math.pi * 6) * 8 : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: child,
        );
      },
    );
  }
}

class _FrontFace extends StatelessWidget {
  const _FrontFace({
    required this.symbol,
    required this.themePack,
    required this.matched,
    required this.wrong,
  });

  final String symbol;
  final MemoryThemePack themePack;
  final bool matched;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final gradientColors = wrong
        ? const [Color(0xFFFCA5A5), Color(0xFFEF4444)]
        : matched
        ? const [Color(0xFFBBF7D0), Color(0xFF86EFAC)]
        : [themePack.tileGradientStart, themePack.tileGradientEnd];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (matched)
            const BoxShadow(
              color: Color(0x3322C55E),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          if (wrong)
            const BoxShadow(
              color: Color(0x33EF4444),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          const BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          style: const TextStyle(fontSize: 34),
        ),
      ),
    );
  }
}

class _BackFace extends StatelessWidget {
  const _BackFace({
    required this.themePack,
  });

  final MemoryThemePack themePack;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: themePack.nodeColor.withOpacity(0.22),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.question_mark_rounded,
          color: themePack.nodeColor,
          size: 32,
        ),
      ),
    );
  }
}