import 'package:flutter/material.dart';

class ProgressPathPainter extends CustomPainter {
  const ProgressPathPainter({
    required this.points,
  });

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final shadowPaint = Paint()
      ..color = const Color(0x14000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final basePaint = Paint()
      ..color = const Color(0xFFFFE5B7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerStripePaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midY = (previous.dy + current.dy) / 2;

      path.cubicTo(
        previous.dx,
        midY,
        current.dx,
        midY,
        current.dx,
        current.dy,
      );
    }

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, basePaint);
    canvas.drawPath(path, centerStripePaint);
  }

  @override
  bool shouldRepaint(covariant ProgressPathPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}