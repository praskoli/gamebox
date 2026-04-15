import 'package:flutter/material.dart';

import '../../domain/sort_level.dart';
import '../controller/sort_puzzle_controller.dart';
import '../widgets/sort_container_widget.dart';
import '../widgets/sort_puzzle_hud.dart';

class ColorSortGameView extends StatelessWidget {
  const ColorSortGameView({
    super.key,
    required this.level,
    required this.controller,
  });

  final SortLevel level;
  final SortPuzzleController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      body: Stack(
        children: [
          const _SoftBg(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Color Sort',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Level ${level.levelNumber}',
                              style: const TextStyle(
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
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                  child: SortPuzzleHud(
                    levelTitle: level.title,
                    subtitle: _subtitleFor(level),
                    moves: controller.session.moveCount,
                    elapsedText: _elapsedText(controller),
                    onUndo: controller.undo,
                    onHint: controller.applyHint,
                    onRestart: controller.restart,
                    canUndo: level.allowUndo,
                    canHint: level.allowHints,
                    accentColor: const Color(0xFF6B7CFF),
                    dark: false,
                  ),
                ),
                if (level.specialRules.hasMoveLimit || level.specialRules.hasTimeLimit)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        if (level.specialRules.hasMoveLimit)
                          _RulePill(
                            icon: Icons.flag_rounded,
                            label: 'Move Limit',
                            value: '${level.specialRules.moveLimit}',
                            color: const Color(0xFF6B7CFF),
                          ),
                        if (level.specialRules.hasMoveLimit &&
                            level.specialRules.hasTimeLimit)
                          const SizedBox(width: 8),
                        if (level.specialRules.hasTimeLimit)
                          _RulePill(
                            icon: Icons.timer_rounded,
                            label: 'Time',
                            value: '${level.specialRules.timeLimitSeconds}s',
                            color: const Color(0xFFFF8A3D),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: controller.session.containers.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
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

  String _elapsedText(SortPuzzleController controller) {
    if (controller.remainingTime != null) {
      return _fmt(controller.remainingTime!);
    }
    return _fmt(controller.session.elapsed);
  }

  String _subtitleFor(SortLevel level) {
    if (level.specialRules.worldKey != null) {
      return 'World: ${level.specialRules.worldKey}';
    }
    if (level.specialRules.hasMoveLimit) {
      return 'Finish within the move target';
    }
    if (level.specialRules.hasTimeLimit) {
      return 'Beat the countdown';
    }
    return 'Sort matching color stacks';
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _RulePill extends StatelessWidget {
  const _RulePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftBg extends StatelessWidget {
  const _SoftBg();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFFF4F6FF)),
        Positioned(
          top: 190,
          left: -50,
          child: Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0x18FFFFFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: 14,
          child: Container(
            width: 118,
            height: 118,
            decoration: const BoxDecoration(
              color: Color(0x14FFFFFF),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}