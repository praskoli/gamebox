import 'dart:math' as math;
import 'package:flutter/material.dart';

class FloatingFruitWidget extends StatefulWidget {
  const FloatingFruitWidget({
    super.key,
    required this.emoji,
    required this.baseOffset,
    this.size = 28,
    this.amplitude = 12,
    this.duration = const Duration(seconds: 4),
    this.rotate = true,
    this.opacity = 0.95,
  });

  final String emoji;
  final Offset baseOffset;
  final double size;
  final double amplitude;
  final Duration duration;
  final bool rotate;
  final double opacity;

  @override
  State<FloatingFruitWidget> createState() => _FloatingFruitWidgetState();
}

class _FloatingFruitWidgetState extends State<FloatingFruitWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final double _phase;

  @override
  void initState() {
    super.initState();
    _phase = (widget.baseOffset.dx + widget.baseOffset.dy) / 57.0;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final verticalDrift =
            math.sin((t * math.pi * 2) + _phase) * widget.amplitude;
        final horizontalDrift =
            math.cos((t * math.pi) + _phase) * (widget.amplitude * 0.18);
        final rotation =
        widget.rotate ? math.sin((t * math.pi * 2) + _phase) * 0.06 : 0.0;
        final scale = 0.96 + (math.sin((t * math.pi * 2) + _phase) * 0.03);

        return Positioned(
          left: widget.baseOffset.dx + horizontalDrift,
          top: widget.baseOffset.dy + verticalDrift,
          child: Opacity(
            opacity: widget.opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: Text(
                  widget.emoji,
                  style: TextStyle(fontSize: widget.size),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}