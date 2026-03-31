import 'package:flutter/material.dart';

class WorldMapPainter extends CustomPainter {
  WorldMapPainter({
    required this.pathColor,
  });

  final Color pathColor;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = pathColor.withOpacity(0.20)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final paint = Paint()
      ..color = pathColor
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.35, 80)
      ..cubicTo(size.width * 0.08, 180, size.width * 0.82, 250, size.width * 0.60, 360)
      ..cubicTo(size.width * 0.30, 470, size.width * 0.10, 560, size.width * 0.45, 680)
      ..cubicTo(size.width * 0.78, 790, size.width * 0.78, 900, size.width * 0.36, 1020)
      ..cubicTo(size.width * 0.12, 1110, size.width * 0.52, 1220, size.width * 0.64, 1340)
      ..cubicTo(size.width * 0.72, 1440, size.width * 0.28, 1520, size.width * 0.38, 1640);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);

    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      for (double distance = 0; distance < metric.length; distance += 28) {
        final extract = metric.extractPath(distance, distance + 10);
        canvas.drawPath(extract, dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.pathColor != pathColor;
  }
}