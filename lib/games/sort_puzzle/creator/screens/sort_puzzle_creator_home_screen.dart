import 'package:flutter/material.dart';

import '../../domain/sort_puzzle_variant.dart';
import 'sort_puzzle_creator_screen.dart';

class SortPuzzleCreatorHomeScreen extends StatelessWidget {
  const SortPuzzleCreatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Create Sort Puzzle',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF17A8FF), Color(0xFF7C5CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2217A8FF),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sort Puzzle Creator',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Pick a variant and design your own playable sort puzzle challenge.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.35,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: SortPuzzleVariant.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.06,
              ),
              itemBuilder: (BuildContext context, int index) {
                final SortPuzzleVariant variant = SortPuzzleVariant.values[index];
                final _VariantTheme theme = _themeFor(variant);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SortPuzzleCreatorScreen(variant: variant),
                        ),
                      );
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.top, theme.bottom],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [theme.iconTop, theme.iconBottom],
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                theme.icon,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _variantLabel(variant),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              theme.subtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _variantLabel(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return 'Bird Sort';
      case SortPuzzleVariant.ball:
        return 'Ball Sort';
      case SortPuzzleVariant.color:
        return 'Color Sort';
      case SortPuzzleVariant.water:
        return 'Water Sort';
      case SortPuzzleVariant.sand:
        return 'Sand Sort';
    }
  }

  _VariantTheme _themeFor(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return const _VariantTheme(
          top: Color(0xFFE8F8FF),
          bottom: Color(0xFFF5FDFF),
          border: Color(0xFFD8ECF6),
          iconTop: Color(0xFF17A8FF),
          iconBottom: Color(0xFF4FD26B),
          icon: Icons.pets_rounded,
          subtitle: 'Perch birds by matching groups',
        );
      case SortPuzzleVariant.ball:
        return const _VariantTheme(
          top: Color(0xFFF0F4FF),
          bottom: Color(0xFFF7F2FF),
          border: Color(0xFFE0E3F5),
          iconTop: Color(0xFF4A8CFF),
          iconBottom: Color(0xFF7C5CFF),
          icon: Icons.sports_baseball_rounded,
          subtitle: 'Group glossy balls into clean tubes',
        );
      case SortPuzzleVariant.color:
        return const _VariantTheme(
          top: Color(0xFFFFF7ED),
          bottom: Color(0xFFFFFBF3),
          border: Color(0xFFF3DEC5),
          iconTop: Color(0xFFFF9E2C),
          iconBottom: Color(0xFFFF5F6D),
          icon: Icons.palette_rounded,
          subtitle: 'Sort bright color stacks',
        );
      case SortPuzzleVariant.water:
        return const _VariantTheme(
          top: Color(0xFFEFF6FF),
          bottom: Color(0xFFF6FBFF),
          border: Color(0xFFD8E8F7),
          iconTop: Color(0xFF17A8FF),
          iconBottom: Color(0xFF5B67F1),
          icon: Icons.water_drop_rounded,
          subtitle: 'Pour matching liquid layers',
        );
      case SortPuzzleVariant.sand:
        return const _VariantTheme(
          top: Color(0xFFFFF4E7),
          bottom: Color(0xFFFFFBF4),
          border: Color(0xFFF0DEC6),
          iconTop: Color(0xFFE39B2E),
          iconBottom: Color(0xFFFFC94A),
          icon: Icons.grain_rounded,
          subtitle: 'Layer flowing sand colors',
        );
    }
  }
}

class _VariantTheme {
  const _VariantTheme({
    required this.top,
    required this.bottom,
    required this.border,
    required this.iconTop,
    required this.iconBottom,
    required this.icon,
    required this.subtitle,
  });

  final Color top;
  final Color bottom;
  final Color border;
  final Color iconTop;
  final Color iconBottom;
  final IconData icon;
  final String subtitle;
}