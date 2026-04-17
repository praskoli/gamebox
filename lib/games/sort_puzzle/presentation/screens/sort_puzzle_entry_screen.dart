import 'package:flutter/material.dart';

import '../../domain/sort_puzzle_variant.dart';
import 'sort_puzzle_mode_level_select_screen.dart';

class SortPuzzleEntryScreen extends StatefulWidget {
  const SortPuzzleEntryScreen({super.key});

  @override
  State<SortPuzzleEntryScreen> createState() => _SortPuzzleEntryScreenState();
}

class _SortPuzzleEntryScreenState extends State<SortPuzzleEntryScreen> {
  SortPuzzleVariant _selectedVariant = SortPuzzleVariant.color;

  @override
  Widget build(BuildContext context) {
    final List<_OfficialModeCardData> modes = _modesFor(_selectedVariant);
    final _VariantTheme theme = _themeFor(_selectedVariant);

    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Stack(
        children: [
          _EntryBackground(theme: theme),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: theme.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Sort Puzzle',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Official platform challenges',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                SizedBox(
                  height: 58,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: SortPuzzleVariant.values.map((variant) {
                      final bool selected = variant == _selectedVariant;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ChoiceChip(
                          label: Text(variant.title),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _selectedVariant = variant;
                            });
                          },
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : theme.textPrimary,
                          ),
                          selectedColor: theme.accent,
                          backgroundColor: theme.cardBackground,
                          side: BorderSide(
                            color: selected ? theme.accent : theme.cardBorder,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: modes.length,
                    itemBuilder: (context, index) {
                      final mode = modes[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == modes.length - 1 ? 0 : 14,
                        ),
                        child: _OfficialModeCard(
                          theme: theme,
                          data: mode,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => SortPuzzleModeLevelSelectScreen(
                                  variant: _selectedVariant,
                                  modeKey: mode.modeKey,
                                  modeTitle: mode.title,
                                  description: mode.description,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_OfficialModeCardData> _modesFor(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.color:
        return const [
          _OfficialModeCardData(
            modeKey: 'classic_journey',
            title: 'Classic Journey',
            badge: 'Progression',
            description:
            'Structured levels with smooth difficulty ramps, stars, unlocks, and satisfying sort flow.',
            icon: Icons.auto_awesome_rounded,
          ),
          _OfficialModeCardData(
            modeKey: 'move_challenge',
            title: 'Move Challenge',
            badge: 'Efficiency',
            description:
            'Finish levels within tight move goals and sharpen every decision.',
            icon: Icons.flag_rounded,
          ),
          _OfficialModeCardData(
            modeKey: 'time_challenge',
            title: 'Time Challenge',
            badge: 'Countdown',
            description:
            'Beat the clock with fast sorting, quick pattern reading, and smart empty-tube control.',
            icon: Icons.timer_rounded,
          ),
        ];
      case SortPuzzleVariant.ball:
        return const [
          _OfficialModeCardData(
            modeKey: 'classic_journey',
            title: 'Classic Journey',
            badge: 'Core Mode',
            description:
            'Glossy tube puzzles with clean progression and polished official levels.',
            icon: Icons.sports_baseball_rounded,
          ),
          _OfficialModeCardData(
            modeKey: 'move_challenge',
            title: 'Move Challenge',
            badge: 'Efficiency',
            description:
            'Solve in fewer moves and earn stronger star ratings.',
            icon: Icons.flag_rounded,
          ),
          _OfficialModeCardData(
            modeKey: 'time_challenge',
            title: 'Time Challenge',
            badge: 'Countdown',
            description:
            'Fast-paced ball sorting with pressure and precision.',
            icon: Icons.timer_rounded,
          ),
        ];
      case SortPuzzleVariant.water:
        return const [
          _OfficialModeCardData(
            modeKey: 'classic_journey',
            title: 'Classic Journey',
            badge: 'Pour Mode',
            description:
            'Official liquid-layer puzzles with steady progression and world unlocks.',
            icon: Icons.water_drop_rounded,
          ),
          _OfficialModeCardData(
            modeKey: 'time_challenge',
            title: 'Time Challenge',
            badge: 'Countdown',
            description:
            'Pour under pressure and keep colors flowing efficiently.',
            icon: Icons.timer_rounded,
          ),
        ];
      case SortPuzzleVariant.sand:
        return const [
          _OfficialModeCardData(
            modeKey: 'classic_journey',
            title: 'Classic Journey',
            badge: 'Core Mode',
            description:
            'Warm desert-inspired sand sorting with layered challenge progression.',
            icon: Icons.grain_rounded,
          ),
          _OfficialModeCardData(
            modeKey: 'move_challenge',
            title: 'Move Challenge',
            badge: 'Efficiency',
            description:
            'Tighter move counts reward cleaner planning and fewer mistakes.',
            icon: Icons.flag_rounded,
          ),
        ];
      case SortPuzzleVariant.bird:
        return const [
          _OfficialModeCardData(
            modeKey: 'classic_journey',
            title: 'Classic Journey',
            badge: 'Perch Mode',
            description:
            'Official bird-perch puzzles with gentle progression and world unlocks.',
            icon: Icons.pets_rounded,
          ),
          _OfficialModeCardData(
            modeKey: 'move_challenge',
            title: 'Move Challenge',
            badge: 'Efficiency',
            description:
            'Perch the flock cleanly using fewer moves and smarter branch use.',
            icon: Icons.flag_rounded,
          ),
        ];
    }
  }

  _VariantTheme _themeFor(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.color:
        return const _VariantTheme(
          pageBackground: Color(0xFFF4F6FF),
          cardBackground: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFD7DDF0),
          accent: Color(0xFF6B7CFF),
          accent2: Color(0xFFA98BFF),
          textPrimary: Color(0xFF111827),
          textSecondary: Color(0xFF6B7280),
        );
      case SortPuzzleVariant.ball:
        return const _VariantTheme(
          pageBackground: Color(0xFF07143A),
          cardBackground: Color(0xFF0E1B4D),
          cardBorder: Color(0x334C8DFF),
          accent: Color(0xFF6C63FF),
          accent2: Color(0xFFEC4899),
          textPrimary: Colors.white,
          textSecondary: Color(0xCCFFFFFF),
        );
      case SortPuzzleVariant.water:
        return const _VariantTheme(
          pageBackground: Color(0xFF081844),
          cardBackground: Color(0xFF0E2A63),
          cardBorder: Color(0x331CB6FF),
          accent: Color(0xFF1CB6FF),
          accent2: Color(0xFF4C8DFF),
          textPrimary: Colors.white,
          textSecondary: Color(0xCCFFFFFF),
        );
      case SortPuzzleVariant.sand:
        return const _VariantTheme(
          pageBackground: Color(0xFFFFF3E3),
          cardBackground: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFE5D4B5),
          accent: Color(0xFFE39B2E),
          accent2: Color(0xFFFFC94A),
          textPrimary: Color(0xFF111827),
          textSecondary: Color(0xFF6B7280),
        );
      case SortPuzzleVariant.bird:
        return const _VariantTheme(
          pageBackground: Color(0xFFE8F8FF),
          cardBackground: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFD6E9F4),
          accent: Color(0xFF14A7FF),
          accent2: Color(0xFF3CCB7F),
          textPrimary: Color(0xFF111827),
          textSecondary: Color(0xFF6B7280),
        );
    }
  }
}

class _OfficialModeCardData {
  const _OfficialModeCardData({
    required this.modeKey,
    required this.title,
    required this.badge,
    required this.description,
    required this.icon,
  });

  final String modeKey;
  final String title;
  final String badge;
  final String description;
  final IconData icon;
}

class _OfficialModeCard extends StatelessWidget {
  const _OfficialModeCard({
    required this.theme,
    required this.data,
    required this.onTap,
  });

  final _VariantTheme theme;
  final _OfficialModeCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = theme.pageBackground.computeLuminance() < 0.2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(
                  theme.accent.withOpacity(dark ? 0.16 : 0.10),
                  theme.cardBackground,
                ),
                Color.alphaBlend(
                  theme.accent2.withOpacity(dark ? 0.12 : 0.06),
                  theme.cardBackground,
                ),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.black.withOpacity(0.18)
                    : const Color(0x16000000),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.accent, theme.accent2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    data.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: dark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: dark
                                ? Colors.white.withOpacity(0.14)
                                : theme.cardBorder,
                          ),
                        ),
                        child: Text(
                          data.badge,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data.description,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          fontWeight: FontWeight.w700,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withOpacity(0.10)
                        : Colors.black.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.textPrimary,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntryBackground extends StatelessWidget {
  const _EntryBackground({
    required this.theme,
  });

  final _VariantTheme theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: theme.pageBackground),
        Positioned(
          top: -60,
          right: -20,
          child: _bubble(theme.accent.withOpacity(0.10), 180),
        ),
        Positioned(
          top: 220,
          left: -30,
          child: _bubble(theme.accent2.withOpacity(0.08), 130),
        ),
        Positioned(
          bottom: -30,
          right: 10,
          child: _bubble(theme.accent.withOpacity(0.06), 140),
        ),
      ],
    );
  }

  Widget _bubble(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _VariantTheme {
  const _VariantTheme({
    required this.pageBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.accent,
    required this.accent2,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color pageBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color accent;
  final Color accent2;
  final Color textPrimary;
  final Color textSecondary;
}