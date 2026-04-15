import 'package:flutter/material.dart';

import '../../domain/sort_level.dart';
import '../controller/sort_puzzle_controller.dart';
import '../widgets/sort_container_widget.dart';
import '../widgets/sort_puzzle_hud.dart';

class SandSortGameView extends StatelessWidget {
  const SandSortGameView({
    super.key,
    required this.level,
    required this.controller,
  });

  final SortLevel level;
  final SortPuzzleController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9EEDB),
      body: Stack(
        children: [
          const _SandBg(),
          SafeArea(
            child: Column(
              children: [
                const _Header(title: 'Sand Sort'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: SortPuzzleHud(
                    levelTitle: level.title,
                    subtitle: 'Separate colored sand layers',
                    moves: controller.session.moveCount,
                    elapsedText: _fmt(controller.session.elapsed),
                    onUndo: controller.undo,
                    onHint: controller.applyHint,
                    onRestart: controller.restart,
                    canUndo: level.allowUndo,
                    canHint: level.allowHints,
                    accentColor: const Color(0xFFE39B2E),
                    dark: false,
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
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          ),
          Expanded(
            child: Column(
              children: const [
                Text(
                  'Sand Sort',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Level 1',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
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

class _SandBg extends StatelessWidget {
  const _SandBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFF4E3),
            Color(0xFFF6E6C4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}