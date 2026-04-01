import 'package:flutter/material.dart';

import '../controller/block_controller.dart';
import 'piece_widget.dart';

class TrayWidget extends StatelessWidget {
  final BlockController controller;

  const TrayWidget({
    super.key,
    required this.controller,
  });

  static const List<List<Color>> _trayThemes = [
    [Color(0xFF1A2A6C), Color(0xFFB21F1F)],
    [Color(0xFF0F2027), Color(0xFF2C5364)],
    [Color(0xFF42275A), Color(0xFF734B6D)],
    [Color(0xFF134E5E), Color(0xFF71B280)],
    [Color(0xFF355C7D), Color(0xFF6C5B7B)],
    [Color(0xFF16222A), Color(0xFF3A6073)],
  ];

  @override
  Widget build(BuildContext context) {
    final tray = controller.engine.tray;
    final theme =
    _trayThemes[(controller.engine.session.score ~/ 25) % _trayThemes.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.view_in_ar_rounded,
                color: Color(0xFFFFD36B),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Your pieces',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.94),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(tray.length, (index) {
              final piece = tray[index];
              final isDraggingThis = controller.draggingIndex == index;

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (details) {
                  controller.startDrag(index, details.globalPosition);
                },
                onPanUpdate: (details) {
                  controller.updateDrag(details.globalPosition);
                },
                onPanEnd: (_) {
                  controller.endDrag();
                },
                onPanCancel: () {
                  controller.endDrag();
                },
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(
                    '${controller.engine.session.score}_${piece.hashCode}_$index',
                  ),
                  tween: Tween<double>(begin: 0.18, end: 0),
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  builder: (context, spawnOffset, child) {
                    return Transform.translate(
                      offset: Offset(0, spawnOffset * 24),
                      child: Opacity(
                        opacity: 1 - (spawnOffset * 0.85),
                        child: child,
                      ),
                    );
                  },
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: isDraggingThis ? 0.10 : 1,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      scale: isDraggingThis ? 0.90 : 1,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        offset: isDraggingThis
                            ? const Offset(0, 0.08)
                            : const Offset(0, 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          constraints: const BoxConstraints(
                            minWidth: 100,
                            minHeight: 90,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.015),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(
                                isDraggingThis ? 0.02 : 0.06,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isDraggingThis ? 0.12 : 0.22,
                                ),
                                blurRadius: isDraggingThis ? 8 : 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            scale: isDraggingThis ? 0.95 : 1,
                            child: PieceWidget(
                              piece: piece,
                              cellSize: 30,
                              active: false,
                              opacity: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}