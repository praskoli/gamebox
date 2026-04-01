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
  late final AnimationController controller;
  late final Animation<double> progress;
  late final Animation<double> fade;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();

    progress = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    fade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.45, 1, curve: Curves.easeOut),
      ),
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
                _buildRowSweep(r),
              for (final c in widget.cols)
                _buildColSweep(c),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRowSweep(int row) {
    final width = widget.boardRect.width;
    final bandWidth = widget.cellSize * 1.8;
    final left =
        widget.boardRect.left + ((width + bandWidth) * progress.value) - bandWidth;

    return Positioned(
      left: left,
      top: widget.boardRect.top + row * widget.cellSize,
      child: Opacity(
        opacity: fade.value,
        child: Container(
          width: bandWidth,
          height: widget.cellSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.92),
                const Color(0xFFFFE37A).withOpacity(0.95),
                Colors.white.withOpacity(0.92),
                Colors.transparent,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(widget.cellSize * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFE37A).withOpacity(0.40),
                blurRadius: 16,
                spreadRadius: 1.5,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColSweep(int col) {
    final height = widget.boardRect.height;
    final bandHeight = widget.cellSize * 1.8;
    final top =
        widget.boardRect.top + ((height + bandHeight) * progress.value) - bandHeight;

    return Positioned(
      left: widget.boardRect.left + col * widget.cellSize,
      top: top,
      child: Opacity(
        opacity: fade.value,
        child: Container(
          width: widget.cellSize,
          height: bandHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.92),
                const Color(0xFFFFE37A).withOpacity(0.95),
                Colors.white.withOpacity(0.92),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(widget.cellSize * 0.28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFE37A).withOpacity(0.40),
                blurRadius: 16,
                spreadRadius: 1.5,
              ),
            ],
          ),
        ),
      ),
    );
  }
}