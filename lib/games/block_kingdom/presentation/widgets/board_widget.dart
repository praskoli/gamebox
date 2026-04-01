import 'package:flutter/material.dart';

import '../../domain/block_cell_type.dart';
import '../controller/block_controller.dart';

class BoardWidget extends StatelessWidget {
  final BlockController controller;

  const BoardWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final board = controller.engine.board;
    final ghostSet = controller.previewCells
        .map((e) => '${e.row}_${e.col}')
        .toSet();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF121826),
            Color(0xFF0C1220),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boardSize = constraints.maxWidth;
          final cellSize = boardSize / board.size;
          final tileGap = cellSize * 0.10;
          final tileSize = cellSize - tileGap * 2;

          return Stack(
            children: [
              for (int r = 0; r < board.size; r++)
                for (int c = 0; c < board.size; c++)
                  Positioned(
                    left: c * cellSize + tileGap,
                    top: r * cellSize + tileGap,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutBack,
                      scale: _tileScale(
                        key: '${r}_$c',
                        ghostSet: ghostSet,
                        controller: controller,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: tileSize,
                        height: tileSize,
                        decoration: BoxDecoration(
                          gradient: _tileGradient(
                            cellType: board.grid[r][c],
                            isGhost: ghostSet.contains('${r}_$c'),
                            ghostValid: controller.isValidPlacement,
                            isPlaced: controller.recentPlacedCellKeys
                                .contains('${r}_$c'),
                            isCleared: controller.recentClearedCellKeys
                                .contains('${r}_$c'),
                          ),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(
                            color: _cellBorder(
                              cellType: board.grid[r][c],
                              isGhost: ghostSet.contains('${r}_$c'),
                              ghostValid: controller.isValidPlacement,
                              isPlaced: controller.recentPlacedCellKeys
                                  .contains('${r}_$c'),
                              isCleared: controller.recentClearedCellKeys
                                  .contains('${r}_$c'),
                            ),
                            width: 1,
                          ),
                          boxShadow: _cellShadow(
                            cellType: board.grid[r][c],
                            isGhost: ghostSet.contains('${r}_$c'),
                            ghostValid: controller.isValidPlacement,
                            isPlaced: controller.recentPlacedCellKeys
                                .contains('${r}_$c'),
                            isCleared: controller.recentClearedCellKeys
                                .contains('${r}_$c'),
                          ),
                        ),
                        child: Stack(
                          children: [
                            _cellGloss(
                              cellType: board.grid[r][c],
                              isGhost: ghostSet.contains('${r}_$c'),
                              isPlaced: controller.recentPlacedCellKeys
                                  .contains('${r}_$c'),
                              isCleared: controller.recentClearedCellKeys
                                  .contains('${r}_$c'),
                            ),
                            if (_shouldShowFilledMotif(
                              cellType: board.grid[r][c],
                              isPlaced: controller.recentPlacedCellKeys
                                  .contains('${r}_$c'),
                              isCleared: controller.recentClearedCellKeys
                                  .contains('${r}_$c'),
                            ))
                              Center(
                                child: Icon(
                                  _pickMotif(r, c),
                                  size: tileSize * 0.34,
                                  color: Colors.white.withOpacity(
                                    controller.recentClearedCellKeys
                                        .contains('${r}_$c')
                                        ? 0.95
                                        : 0.82,
                                  ),
                                ),
                              ),
                            if (board.grid[r][c] == BlockCellType.deadZone)
                              Center(
                                child: Icon(
                                  Icons.block_rounded,
                                  size: tileSize * 0.34,
                                  color: const Color(0xFFFF8A80).withOpacity(0.9),
                                ),
                              ),
                            if (board.grid[r][c] == BlockCellType.blocked)
                              Center(
                                child: Icon(
                                  Icons.shield_rounded,
                                  size: tileSize * 0.34,
                                  color: const Color(0xFFB0BEC5).withOpacity(0.9),
                                ),
                              ),
                            if (ghostSet.contains('${r}_$c'))
                              Center(
                                child: Icon(
                                  _pickMotif(r, c),
                                  size: tileSize * 0.28,
                                  color: Colors.white.withOpacity(
                                    controller.isValidPlacement ? 0.45 : 0.30,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              for (int i = 1; i < board.size; i++)
                Positioned(
                  left: i * cellSize,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              for (int i = 1; i < board.size; i++)
                Positioned(
                  top: i * cellSize,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowFilledMotif({
    required BlockCellType cellType,
    required bool isPlaced,
    required bool isCleared,
  }) {
    return cellType == BlockCellType.filled || isPlaced || isCleared;
  }

  IconData _pickMotif(int row, int col) {
    final index = (row + col) % 5;
    switch (index) {
      case 0:
        return Icons.workspace_premium_rounded;
      case 1:
        return Icons.diamond_rounded;
      case 2:
        return Icons.eco_rounded;
      case 3:
        return Icons.auto_awesome_rounded;
      default:
        return Icons.local_fire_department_rounded;
    }
  }

  double _tileScale({
    required String key,
    required Set<String> ghostSet,
    required BlockController controller,
  }) {
    if (controller.recentClearedCellKeys.contains(key)) return 1.10;
    if (controller.recentPlacedCellKeys.contains(key)) return 1.05;

    if (ghostSet.contains(key) && controller.isValidPlacement) {
      final time = DateTime.now().millisecondsSinceEpoch % 600;
      final pulse = time / 600;
      return 1.02 + (pulse * 0.04);
    }

    return 1;
  }

  Gradient _tileGradient({
    required BlockCellType cellType,
    required bool isGhost,
    required bool ghostValid,
    required bool isPlaced,
    required bool isCleared,
  }) {
    if (isCleared) {
      return const LinearGradient(
        colors: [
          Color(0xFFFFF1A6),
          Color(0xFFFFD86A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (isPlaced) {
      return const LinearGradient(
        colors: [
          Color(0xFFFFE17D),
          Color(0xFFFFC140),
          Color(0xFFFFA400),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (cellType == BlockCellType.filled) {
      return const LinearGradient(
        colors: [
          Color(0xFFFFD665),
          Color(0xFFFFB739),
          Color(0xFFFF9B00),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (cellType == BlockCellType.deadZone) {
      return const LinearGradient(
        colors: [
          Color(0xFF4A1115),
          Color(0xFF2C0B0E),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (cellType == BlockCellType.blocked) {
      return const LinearGradient(
        colors: [
          Color(0xFF465A64),
          Color(0xFF263238),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (isGhost) {
      return ghostValid
          ? LinearGradient(
        colors: [
          const Color(0xFF58F3A0).withOpacity(0.72),
          const Color(0xFF35D97E).withOpacity(0.62),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )
          : LinearGradient(
        colors: [
          const Color(0xFFFF7C8B).withOpacity(0.72),
          const Color(0xFFFF5A6E).withOpacity(0.62),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    return const LinearGradient(
      colors: [
        Color(0xFF505050),
        Color(0xFF404040),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Color _cellBorder({
    required BlockCellType cellType,
    required bool isGhost,
    required bool ghostValid,
    required bool isPlaced,
    required bool isCleared,
  }) {
    if (isCleared) return const Color(0xFFFFF2AE).withOpacity(0.95);
    if (isPlaced) return const Color(0xFFFFE39A).withOpacity(0.85);
    if (cellType == BlockCellType.filled) {
      return const Color(0xFFFFFFFF).withOpacity(0.16);
    }
    if (cellType == BlockCellType.deadZone) {
      return const Color(0xFFFF8A80).withOpacity(0.65);
    }
    if (cellType == BlockCellType.blocked) {
      return const Color(0xFFCFD8DC).withOpacity(0.65);
    }

    if (isGhost) {
      return ghostValid
          ? const Color(0xFFB6FFD2).withOpacity(0.90)
          : const Color(0xFFFFBAC3).withOpacity(0.90);
    }

    return Colors.black.withOpacity(0.20);
  }

  List<BoxShadow> _cellShadow({
    required BlockCellType cellType,
    required bool isGhost,
    required bool ghostValid,
    required bool isPlaced,
    required bool isCleared,
  }) {
    if (isCleared) {
      return [
        BoxShadow(
          color: const Color(0xFFFFE16B).withOpacity(0.38),
          blurRadius: 16,
          spreadRadius: 1.2,
        ),
      ];
    }

    if (isPlaced) {
      return [
        BoxShadow(
          color: const Color(0xFFFFB000).withOpacity(0.26),
          blurRadius: 12,
          spreadRadius: 0.9,
        ),
      ];
    }

    if (isGhost) {
      return [
        BoxShadow(
          color: ghostValid
              ? const Color(0xFF44E98A).withOpacity(0.26)
              : const Color(0xFFFF6577).withOpacity(0.26),
          blurRadius: 10,
          spreadRadius: 0.8,
        ),
      ];
    }

    if (cellType == BlockCellType.deadZone) {
      return [
        BoxShadow(
          color: const Color(0xFFFF5252).withOpacity(0.14),
          blurRadius: 8,
          spreadRadius: 0.6,
        ),
      ];
    }

    if (cellType == BlockCellType.blocked) {
      return [
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          blurRadius: 8,
          spreadRadius: 0.4,
        ),
      ];
    }

    if (cellType == BlockCellType.filled) {
      return [
        BoxShadow(
          color: Colors.white.withOpacity(0.06),
          blurRadius: 8,
          spreadRadius: 0.4,
        ),
      ];
    }

    return const [];
  }

  Widget _cellGloss({
    required BlockCellType cellType,
    required bool isGhost,
    required bool isPlaced,
    required bool isCleared,
  }) {
    if (cellType == BlockCellType.empty &&
        !isGhost &&
        !isPlaced &&
        !isCleared) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        height: 10,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(
            isCleared
                ? 0.30
                : isPlaced
                ? 0.26
                : isGhost
                ? 0.12
                : cellType == BlockCellType.deadZone
                ? 0.08
                : cellType == BlockCellType.blocked
                ? 0.10
                : 0.16,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}