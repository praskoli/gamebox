import 'dart:math' as math;
import 'package:flutter/material.dart';

class BlockPlaceEffect extends StatefulWidget {
  final List<Offset> cellPositions;
  final double cellSize;
  final bool emphasizeClear;

  const BlockPlaceEffect({
    super.key,
    required this.cellPositions,
    required this.cellSize,
    this.emphasizeClear = false,
  });

  @override
  State<BlockPlaceEffect> createState() => _BlockPlaceEffectState();
}

class _BlockPlaceEffectState extends State<BlockPlaceEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.emphasizeClear ? 520 : 320,
      ),
    )..forward();

    _fade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _scale = Tween<double>(
      begin: 0.55,
      end: widget.emphasizeClear ? 1.45 : 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _sparkDots(Offset cellTopLeft) {
    final size = widget.cellSize;
    final color = widget.emphasizeClear
        ? const Color(0xFFFFF1A6)
        : const Color(0xFFFFD260);

    const angles = <double>[
      0,
      45,
      90,
      135,
      180,
      225,
      270,
      315,
    ];

    return angles.map((angle) {
      final rad = angle * (math.pi / 180);
      final distance = widget.emphasizeClear ? size * 0.30 : size * 0.22;
      final dx = math.cos(rad) * distance * _scale.value;
      final dy = math.sin(rad) * distance * _scale.value;

      return Positioned(
        left: cellTopLeft.dx + (size / 2) + dx - 2,
        top: cellTopLeft.dy + (size / 2) + dy - 2,
        child: Opacity(
          opacity: _fade.value,
          child: Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.55),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.emphasizeClear
        ? const Color(0xFFFFE98A)
        : const Color(0xFFFFC24C);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              for (final cellTopLeft in widget.cellPositions) ...[
                Positioned(
                  left: cellTopLeft.dx,
                  top: cellTopLeft.dy,
                  child: Opacity(
                    opacity: _fade.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Transform.rotate(
                        angle: widget.emphasizeClear
                            ? _controller.value * 0.14
                            : 0,
                        child: Container(
                          width: widget.cellSize,
                          height: widget.cellSize,
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(widget.cellSize * 0.22),
                            color: glowColor.withOpacity(
                              widget.emphasizeClear ? 0.22 : 0.18,
                            ),
                            border: Border.all(
                              color: glowColor.withOpacity(0.8),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withOpacity(0.35),
                                blurRadius:
                                widget.emphasizeClear ? 24 : 14,
                                spreadRadius:
                                widget.emphasizeClear ? 3 : 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ..._sparkDots(cellTopLeft),
              ],
            ],
          );
        },
      ),
    );
  }
}