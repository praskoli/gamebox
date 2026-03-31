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

  @override
  Widget build(BuildContext context) {
    final palettes = <List<Color>>[
      const [
        Color(0xFFFFE17D),
        Color(0xFFFFC140),
        Color(0xFFFFA400),
      ],
      const [
        Color(0xFF8EDCFF),
        Color(0xFF4CB5F5),
        Color(0xFF2196F3),
      ],
      const [
        Color(0xFF9EFFB3),
        Color(0xFF4CAF50),
        Color(0xFF2E7D32),
      ],
      const [
        Color(0xFFFF9EFF),
        Color(0xFFE040FB),
        Color(0xFF9C27B0),
      ],
      const [
        Color(0xFFFFB1A1),
        Color(0xFFFF7043),
        Color(0xFFE64A19),
      ],
      const [
        Color(0xFFB39DFF),
        Color(0xFF7E57C2),
        Color(0xFF5E35B1),
      ],
    ];

    final colors = palettes[piece.hashCode.abs() % palettes.length];
    final shadowColor = colors[1];

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: piece.shape.map((row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((cell) {
              if (cell == 0) {
                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                );
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
                    color: Colors.white.withOpacity(active ? 0.52 : 0.28),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor.withOpacity(active ? 0.36 : 0.16),
                      blurRadius: active ? 18 : 9,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: cellSize * 0.66,
                        height: cellSize * 0.18,
                        margin: EdgeInsets.only(top: cellSize * 0.08),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: cellSize * 0.58,
                        height: cellSize * 0.42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(radius * 0.7),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: cellSize * 0.74,
                        height: cellSize * 0.12,
                        margin: EdgeInsets.only(bottom: cellSize * 0.07),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.10),
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