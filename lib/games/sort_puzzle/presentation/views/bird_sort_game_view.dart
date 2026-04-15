import 'package:flutter/material.dart';

import '../../domain/sort_level.dart';
import '../controller/sort_puzzle_controller.dart';
import '../widgets/sort_container_widget.dart';
import '../widgets/sort_puzzle_hud.dart';

class BirdSortGameView extends StatelessWidget {
  const BirdSortGameView({
    super.key,
    required this.level,
    required this.controller,
  });

  final SortLevel level;
  final SortPuzzleController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F7FF),
      body: Stack(
        children: [
          const _BirdBg(),
          SafeArea(
            child: Column(
              children: [
                const _Header(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: SortPuzzleHud(
                    levelTitle: level.title,
                    subtitle: 'Perch the same birds together',
                    moves: controller.session.moveCount,
                    elapsedText: _fmt(controller.session.elapsed),
                    onUndo: controller.undo,
                    onHint: controller.applyHint,
                    onRestart: controller.restart,
                    canUndo: level.allowUndo,
                    canHint: level.allowHints,
                    accentColor: const Color(0xFF14A7FF),
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
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.72,
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
  const _Header();

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
                  'Bird Sort',
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

class _BirdBg extends StatelessWidget {
  const _BirdBg();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFCDEEFF),
                Color(0xFFEAF9FF),
                Color(0xFFDFF6FF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 160,
          left: -20,
          child: _cloud(160, 72, 0.62),
        ),
        Positioned(
          top: 260,
          right: -20,
          child: _cloud(180, 78, 0.58),
        ),
        Positioned(
          bottom: -20,
          left: -10,
          right: -10,
          child: Container(
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFC7F3D0),
                  Color(0xFFE4F7D9),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(80)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cloud(double width, double height, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}