import 'package:flutter/material.dart';

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
                            filled: board.grid[r][c] == 1,
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
                              filled: board.grid[r][c] == 1,
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
                            filled: board.grid[r][c] == 1,
                            isGhost: ghostSet.contains('${r}_$c'),
                            ghostValid: controller.isValidPlacement,
                            isPlaced: controller.recentPlacedCellKeys
                                .contains('${r}_$c'),
                            isCleared: controller.recentClearedCellKeys
                                .contains('${r}_$c'),
                          ),
                        ),
                        child: _cellGloss(
                          filled: board.grid[r][c] == 1,
                          isGhost: ghostSet.contains('${r}_$c'),
                          isPlaced: controller.recentPlacedCellKeys
                              .contains('${r}_$c'),
                          isCleared: controller.recentClearedCellKeys
                              .contains('${r}_$c'),
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
    required bool filled,
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
          Color(0xFFFFD665),
          Color(0xFFFFB739),
          Color(0xFFFF9B00),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    if (filled) {
      return const LinearGradient(
        colors: [
          Color(0xFF59B5FF),
          Color(0xFF319AF2),
          Color(0xFF2485D9),
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
    required bool filled,
    required bool isGhost,
    required bool ghostValid,
    required bool isPlaced,
    required bool isCleared,
  }) {
    if (isCleared) return const Color(0xFFFFF2AE).withOpacity(0.95);
    if (isPlaced) return const Color(0xFFFFE39A).withOpacity(0.85);
    if (filled) return const Color(0xFFA7DAFF).withOpacity(0.28);

    if (isGhost) {
      return ghostValid
          ? const Color(0xFFB6FFD2).withOpacity(0.90)
          : const Color(0xFFFFBAC3).withOpacity(0.90);
    }

    return Colors.black.withOpacity(0.20);
  }

  List<BoxShadow> _cellShadow({
    required bool filled,
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

    if (filled) {
      return [
        BoxShadow(
          color: const Color(0xFF349AF0).withOpacity(0.15),
          blurRadius: 8,
          spreadRadius: 0.4,
        ),
      ];
    }

    return const [];
  }

  Widget _cellGloss({
    required bool filled,
    required bool isGhost,
    required bool isPlaced,
    required bool isCleared,
  }) {
    if (!filled && !isGhost && !isPlaced && !isCleared) {
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
                : 0.16,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}