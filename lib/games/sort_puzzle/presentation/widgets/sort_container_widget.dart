import 'package:flutter/material.dart';

import '../../domain/sort_container.dart';
import '../../domain/sort_piece.dart';
import '../../domain/sort_puzzle_variant.dart';

class SortContainerWidget extends StatelessWidget {
  const SortContainerWidget({
    super.key,
    required this.container,
    required this.variant,
    required this.isSelected,
    required this.onTap,
  });

  final SortContainer container;
  final SortPuzzleVariant variant;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SortPuzzleVariant.ball:
        return _TubeContainer(
          container: container,
          isSelected: isSelected,
          onTap: onTap,
          style: _TubeStyle.ball,
        );
      case SortPuzzleVariant.color:
        return _TubeContainer(
          container: container,
          isSelected: isSelected,
          onTap: onTap,
          style: _TubeStyle.color,
        );
      case SortPuzzleVariant.water:
        return _TubeContainer(
          container: container,
          isSelected: isSelected,
          onTap: onTap,
          style: _TubeStyle.water,
        );
      case SortPuzzleVariant.sand:
        return _TubeContainer(
          container: container,
          isSelected: isSelected,
          onTap: onTap,
          style: _TubeStyle.sand,
        );
      case SortPuzzleVariant.bird:
        return _BirdPerchContainer(
          container: container,
          isSelected: isSelected,
          onTap: onTap,
        );
    }
  }
}

enum _TubeStyle { ball, color, water, sand }

class _TubeContainer extends StatelessWidget {
  const _TubeContainer({
    required this.container,
    required this.isSelected,
    required this.onTap,
    required this.style,
  });

  final SortContainer container;
  final bool isSelected;
  final VoidCallback onTap;
  final _TubeStyle style;

  @override
  Widget build(BuildContext context) {
    final List<SortPiece?> slots = _slotsFromBottom(container);
    final bool dark = style == _TubeStyle.ball || style == _TubeStyle.water;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: _accent().withOpacity(0.24),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? _accent() : _border(dark),
                  width: 2,
                ),
                color: dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.50),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isSelected ? _accent() : _border(dark),
                    width: isSelected ? 2.6 : 2.0,
                  ),
                  color: dark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.56),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: List.generate(
                      container.capacity,
                          (index) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: index == container.capacity - 1 ? 0 : 5,
                          ),
                          child: _TubeSlot(
                            piece: slots[index],
                            style: style,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accent() {
    switch (style) {
      case _TubeStyle.ball:
        return const Color(0xFF6C63FF);
      case _TubeStyle.color:
        return const Color(0xFF5A80F4);
      case _TubeStyle.water:
        return const Color(0xFF1CB6FF);
      case _TubeStyle.sand:
        return const Color(0xFFE39B2E);
    }
  }

  Color _border(bool dark) {
    return dark ? Colors.white.withOpacity(0.62) : const Color(0xFFC8CFDB);
  }
}

class _TubeSlot extends StatelessWidget {
  const _TubeSlot({
    required this.piece,
    required this.style,
  });

  final SortPiece? piece;
  final _TubeStyle style;

  @override
  Widget build(BuildContext context) {
    if (piece == null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: style == _TubeStyle.ball || style == _TubeStyle.water
                ? Colors.white.withOpacity(0.18)
                : const Color(0xFFD8DDE6),
          ),
        ),
      );
    }

    final Color c = _resolveColor(piece!.groupKey);

    switch (style) {
      case _TubeStyle.ball:
        return Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.82),
                    c,
                    c.withOpacity(0.94),
                  ],
                  stops: const [0.0, 0.24, 1.0],
                  center: const Alignment(-0.35, -0.35),
                ),
              ),
            ),
          ),
        );
      case _TubeStyle.color:
        return Container(
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(14),
          ),
        );
      case _TubeStyle.water:
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _brighten(c, 0.18),
                  c,
                  _darken(c, 0.12),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      case _TubeStyle.sand:
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: c),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SandTexturePainter(
                    color: Colors.white.withOpacity(0.10),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _BirdPerchContainer extends StatelessWidget {
  const _BirdPerchContainer({
    required this.container,
    required this.isSelected,
    required this.onTap,
  });

  final SortContainer container;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<SortPiece?> slots = _slotsFromBottom(container);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? const Color(0x2214A7FF) : Colors.transparent,
        ),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(
                  container.capacity,
                      (index) => Expanded(
                    child: Center(
                      child: slots[index] == null
                          ? const SizedBox.shrink()
                          : _BetterBirdToken(
                        color: _resolveColor(slots[index]!.groupKey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF7A4A2C),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x442C170A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BetterBirdToken extends StatelessWidget {
  const _BetterBirdToken({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              width: 34,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 25,
            top: 6,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 16,
                height: 9,
                decoration: BoxDecoration(
                  color: _darken(color, 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            left: 38,
            top: 8,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF7EA),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 3,
                  height: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF111827),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 54,
            top: 12,
            child: CustomPaint(
              size: const Size(10, 8),
              painter: _TrianglePainter(color: const Color(0xFFFFB74D)),
            ),
          ),
          Positioned(
            left: 24,
            bottom: 2,
            child: Row(
              children: const [
                _BirdLeg(),
                SizedBox(width: 5),
                _BirdLeg(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirdLeg extends StatelessWidget {
  const _BirdLeg();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 10,
      color: const Color(0xFF8B5E3C),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SandTexturePainter extends CustomPainter {
  const _SandTexturePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (double y = 4; y < size.height; y += 7) {
      for (double x = 4; x < size.width; x += 10) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SandTexturePainter oldDelegate) =>
      oldDelegate.color != color;
}

List<SortPiece?> _slotsFromBottom(SortContainer container) {
  final slots = List<SortPiece?>.filled(container.capacity, null);
  int cursor = 0;
  for (final piece in container.pieces) {
    for (int i = 0; i < piece.amount && cursor < container.capacity; i++) {
      slots[cursor] = piece;
      cursor++;
    }
  }
  return slots.reversed.toList();
}

Color _resolveColor(String? groupKey) {
  switch (groupKey) {
    case 'red':
      return const Color(0xFFFF5A5F);
    case 'blue':
      return const Color(0xFF4C8DFF);
    case 'green':
      return const Color(0xFF3CCB7F);
    case 'yellow':
      return const Color(0xFFFFC94A);
    case 'purple':
      return const Color(0xFFA86BFF);
    case 'orange':
      return const Color(0xFFFF914D);
    case 'pink':
      return const Color(0xFFFF71B8);
    case 'teal':
      return const Color(0xFF35C7C2);
    case 'brown':
      return const Color(0xFFA66A3F);
    case 'cyan':
      return const Color(0xFF21C7E8);
    case 'lime':
      return const Color(0xFF9AD93A);
    case 'navy':
      return const Color(0xFF2F4B8F);
    case 'gold':
      return const Color(0xFFE3B341);
    case 'silver':
      return const Color(0xFFB8C2CC);
    case 'maroon':
      return const Color(0xFF7A2E52);
    case 'indigo':
      return const Color(0xFF5B5BD6);
    case 'crimson':
      return const Color(0xFFD63A4A);
    default:
      return const Color(0xFF9AA4B2);
  }
}

Color _brighten(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
      .toColor();
}