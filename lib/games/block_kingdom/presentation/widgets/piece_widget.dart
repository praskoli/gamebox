import 'package:flutter/material.dart';
import '../../domain/block_piece.dart';

class PieceWidget extends StatelessWidget {
  final BlockPiece piece;
  final double cellSize;
  final bool active;
  final double opacity;

  const PieceWidget({
    super.key,
    required this.piece,
    this.cellSize = 24,
    this.active = false,
    this.opacity = 1,
  });

  IconData _pickMotif(Color baseColor) {
    final hue = baseColor.red + baseColor.green + baseColor.blue;

    if (hue > 600) return Icons.workspace_premium_rounded; // crown
    if (baseColor.blue > baseColor.red && baseColor.blue > baseColor.green) {
      return Icons.diamond_rounded;
    }
    if (baseColor.green > baseColor.red) return Icons.eco_rounded;
    if (baseColor.red > 200) return Icons.local_fire_department_rounded;

    return Icons.auto_awesome_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final palettes = <List<Color>>[
      [Color(0xFFFFE17D), Color(0xFFFFC140), Color(0xFFFFA400)],
      [Color(0xFF8EDCFF), Color(0xFF4CB5F5), Color(0xFF2196F3)],
      [Color(0xFF9EFFB3), Color(0xFF4CAF50), Color(0xFF2E7D32)],
      [Color(0xFFFF9EFF), Color(0xFFE040FB), Color(0xFF9C27B0)],
      [Color(0xFFFFB1A1), Color(0xFFFF7043), Color(0xFFE64A19)],
      [Color(0xFFB39DFF), Color(0xFF7E57C2), Color(0xFF5E35B1)],
    ];

    final colors = palettes[piece.hashCode.abs() % palettes.length];
    final shadowColor = colors[1];
    final motif = _pickMotif(colors[1]);

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: piece.shape.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((cell) {
              if (cell == 0) {
                return SizedBox(width: cellSize, height: cellSize);
              }

              final radius = cellSize * 0.22;

              return Container(
                width: cellSize,
                height: cellSize,
                margin: EdgeInsets.all(cellSize * 0.05),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: Colors.white.withOpacity(active ? 0.6 : 0.28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(active ? 0.4 : 0.18),
                      blurRadius: active ? 20 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    /// 🔥 Shine animation
                    _Shimmer(cellSize: cellSize),

                    /// 🔥 Top gloss
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: cellSize * 0.66,
                        height: cellSize * 0.18,
                        margin: EdgeInsets.only(top: cellSize * 0.08),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),

                    /// 🔥 CENTER MOTIF
                    Center(
                      child: Icon(
                        motif,
                        size: cellSize * 0.38,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),

                    /// 🔥 Bottom shadow
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: cellSize * 0.74,
                        height: cellSize * 0.12,
                        margin: EdgeInsets.only(bottom: cellSize * 0.07),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double cellSize;

  const _Shimmer({
    required this.cellSize,
    Key? key,
  }) : super(key: key);

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ VERY IMPORTANT (fixes your crash)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (widget.cellSize * 2) * _controller.value,
            0,
          ),
          child: child,
        );
      },
      child: Container(
        width: widget.cellSize * 2,
        height: widget.cellSize * 2,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.0),
              Colors.white.withOpacity(0.25),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}