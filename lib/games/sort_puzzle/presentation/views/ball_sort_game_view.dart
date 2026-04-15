import 'package:flutter/material.dart';

import '../../domain/sort_level.dart';
import '../controller/sort_puzzle_controller.dart';
import '../widgets/sort_container_widget.dart';
import '../widgets/sort_puzzle_hud.dart';

class BallSortGameView extends StatelessWidget {
  const BallSortGameView({
    super.key,
    required this.level,
    required this.controller,
  });

  final SortLevel level;
  final SortPuzzleController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1437),
      body: Stack(
        children: [
          const _NeonBg(),
          SafeArea(
            child: Column(
              children: [
                const _Header(title: 'Ball Sort'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: SortPuzzleHud(
                    levelTitle: level.title,
                    subtitle: 'Group matching balls into tubes',
                    moves: controller.session.moveCount,
                    elapsedText: _fmt(controller.session.elapsed),
                    onUndo: controller.undo,
                    onHint: controller.applyHint,
                    onRestart: controller.restart,
                    canUndo: level.allowUndo,
                    canHint: level.allowHints,
                    accentColor: const Color(0xFF6C63FF),
                    dark: true,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.session.containers.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.60,
                      ),
                      itemBuilder: (context, index) {
                        return SortContainerWidget(
                          container: controller.session.containers[index],
                          variant: level.variant,
                          isSelected: controller.session.selectedContainerIndex == index,
                          onTap: () => controller.selectContainer(index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: const [
                Text(
                  'Ball Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Level 1',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _NeonBg extends StatelessWidget {
  const _NeonBg();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF091234),
                Color(0xFF11245C),
                Color(0xFF091234),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -60,
          left: -40,
          child: _glow(const Color(0xFF3B82F6), 180),
        ),
        Positioned(
          top: 160,
          right: -30,
          child: _glow(const Color(0xFFEC4899), 180),
        ),
        Positioned(
          bottom: -40,
          left: 40,
          child: _glow(const Color(0xFF22C55E), 200),
        ),
      ],
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.14),
      ),
    );
  }
}