// lib/features/memory_match/presentation/widgets/memory_tile.dart
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
    final bool showFront = card.isFaceUp || card.isMatched;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: showFront ? 1 : 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOutBack,
      builder: (BuildContext context, double value, Widget? child) {
        final double angle = value * math.pi;
        final bool isFrontVisible = value >= 0.5;

        return _ShakeWrapper(
          active: isWrong,
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: isJustMatched || card.isMatched ? 1.08 : 1,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
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
      builder: (BuildContext context, double value, Widget? _) {
        final double dx = active ? math.sin(value * math.pi * 6) * 8 : 0.0;
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
    final List<Color> gradientColors = wrong
        ? const <Color>[Color(0xFFFCA5A5), Color(0xFFEF4444)]
        : matched
        ? const <Color>[Color(0xFFBBF7D0), Color(0xFF86EFAC)]
        : <Color>[themePack.tileGradientStart, themePack.tileGradientEnd];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: matched
              ? const Color(0xFF16A34A).withOpacity(0.50)
              : themePack.nodeColor.withOpacity(0.18),
          width: matched ? 2 : 1.2,
        ),
        boxShadow: <BoxShadow>[
          if (matched)
            const BoxShadow(
              color: Color(0x3322C55E),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          if (wrong)
            const BoxShadow(
              color: Color(0x33EF4444),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          BoxShadow(
            color: themePack.glowColor.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          symbol,
          style: const TextStyle(
            fontSize: 34,
            height: 1,
          ),
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
        gradient: LinearGradient(
          colors: <Color>[
            Colors.white.withOpacity(0.96),
            Colors.white.withOpacity(0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themePack.nodeColor.withOpacity(0.24),
          width: 1.4,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: themePack.glowColor.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: <Color>[
                    themePack.tileGradientStart.withOpacity(0.16),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.question_mark_rounded,
              color: themePack.nodeColor,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}