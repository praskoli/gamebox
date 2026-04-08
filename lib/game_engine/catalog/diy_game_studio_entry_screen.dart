import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/memory_match/presentation/memory_diy_builder_screen.dart';
import 'diy_games_screen.dart';

class DiyGameStudioEntryScreen extends StatefulWidget {
  const DiyGameStudioEntryScreen({super.key});

  @override
  State<DiyGameStudioEntryScreen> createState() =>
      _DiyGameStudioEntryScreenState();
}

class _DiyGameStudioEntryScreenState extends State<DiyGameStudioEntryScreen> {
  static const List<_StudioCaption> _captions = <_StudioCaption>[
    _StudioCaption(
      title: 'Create. Play. Share.',
      subtitle: 'Turn simple ideas into fun games in minutes.',
    ),
    _StudioCaption(
      title: 'Build your own game world',
      subtitle: 'Pick a theme, shape the challenge, and make it yours.',
    ),
    _StudioCaption(
      title: 'From idea to playable',
      subtitle: 'Design a game, test it, and share it with the community.',
    ),
    _StudioCaption(
      title: 'Your creativity, your rules',
      subtitle: 'Make quick games that feel personal, playful, and polished.',
    ),
    _StudioCaption(
      title: 'Small idea. Big fun.',
      subtitle: 'Start with a spark and turn it into something people can play.',
    ),
    _StudioCaption(
      title: 'Launch your next hit',
      subtitle: 'Create a game that friends can play, cheer, and share.',
    ),
  ];

  late final Timer _timer;
  int _captionIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _captionIndex = (_captionIndex + 1) % _captions.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _StudioCaption caption = _captions[_captionIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7A1CF5),
              Color(0xFF3B0C72),
              Color(0xFF071A5D),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _StudioBackgroundGlow()),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        _NeonTitle(text: 'DIY Game'),
                        _NeonTitle(text: 'Studio'),
                        const SizedBox(height: 10),
                        const Text(
                          '✨ Create • Play • Share ✨',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFFF5E9FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: Column(
                        key: ValueKey<int>(_captionIndex),
                        children: [
                          Text(
                            caption.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFFF0FF),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            caption.subtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                  const MemoryDiyBuilderScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Start Creating'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5B21B6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const DiyGamesScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.grid_view_rounded),
                            label: const Text('Open Studio Hub'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.28),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudioCaption {
  const _StudioCaption({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _StudioBackgroundGlow extends StatelessWidget {
  const _StudioBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StudioGlowPainter(),
      ),
    );
  }
}

class _StudioGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinkGlow = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x55FF7AF6),
          Color(0x00FF7AF6),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.12, size.height * 0.06),
          radius: size.width * 0.45,
        ),
      );

    final Paint blueGlow = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0x332AA5FF),
          Color(0x002AA5FF),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.88, size.height * 0.84),
          radius: size.width * 0.42,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.12, size.height * 0.06),
      size.width * 0.45,
      pinkGlow,
    );
    canvas.drawCircle(
      Offset(size.width * 0.88, size.height * 0.84),
      size.width * 0.42,
      blueGlow,
    );

    final Paint starPaint = Paint()..color = Colors.white.withOpacity(0.18);
    for (int i = 0; i < 24; i++) {
      final double dx = (size.width / 24) * i + 8;
      final double dy = (size.height / 28) * (i % 14) + 16;
      canvas.drawCircle(Offset(dx % size.width, dy), 1.1, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
class _NeonTitle extends StatelessWidget {
  const _NeonTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Outer glow
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF4DFF),
            letterSpacing: 1.0,
            height: 0.9,
            shadows: [
              Shadow(
                color: Color(0xFFFF4DFF),
                blurRadius: 25,
              ),
              Shadow(
                color: Color(0xFFB026FF),
                blurRadius: 40,
              ),
            ],
          ),
        ),

        // Inner bright text
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.0,
            height: 0.9,
            shadows: [
              Shadow(
                color: Color(0xFFFF9BFF),
                blurRadius: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}