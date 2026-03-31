import 'package:flutter/material.dart';

class LineClearSweepEffect extends StatefulWidget {
  final Rect boardRect;
  final double cellSize;
  final List<int> rows;
  final List<int> cols;

  const LineClearSweepEffect({
    super.key,
    required this.boardRect,
    required this.cellSize,
    required this.rows,
    required this.cols,
  });

  @override
  State<LineClearSweepEffect> createState() =>
      _LineClearSweepEffectState();
}

class _LineClearSweepEffectState extends State<LineClearSweepEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> progress;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..forward();

    progress = Tween(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return Stack(
            children: [
              for (final r in widget.rows)
                Positioned(
                  left: widget.boardRect.left,
                  top: widget.boardRect.top + r * widget.cellSize,
                  child: Container(
                    width: widget.boardRect.width,
                    height: widget.cellSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.9),
                          Colors.transparent,
                        ],
                        stops: [
                          (progress.value - 0.2).clamp(0.0, 1.0),
                          progress.value.clamp(0.0, 1.0),
                          (progress.value + 0.2).clamp(0.0, 1.0),
                        ],
                      ),
                    ),
                  ),
                ),
              for (final c in widget.cols)
                Positioned(
                  left: widget.boardRect.left + c * widget.cellSize,
                  top: widget.boardRect.top,
                  child: Container(
                    width: widget.cellSize,
                    height: widget.boardRect.height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.9),
                          Colors.transparent,
                        ],
                        stops: [
                          (progress.value - 0.2).clamp(0.0, 1.0),
                          progress.value.clamp(0.0, 1.0),
                          (progress.value + 0.2).clamp(0.0, 1.0),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}