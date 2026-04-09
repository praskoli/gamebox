import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'diy_games_screen.dart';
import '../../game_engine/catalog/models/story_builder_entry_screen.dart';

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
      subtitle: 'Pick a template, shape the challenge, and make it yours.',
    ),
    _StudioCaption(
      title: 'Games and stories begin here',
      subtitle: 'Choose what you want to create and jump right in.',
    ),
    _StudioCaption(
      title: 'Your creativity, your rules',
      subtitle: 'Make playful experiences that feel personal and polished.',
    ),
    _StudioCaption(
      title: 'Small idea. Big fun.',
      subtitle: 'Start with a spark and turn it into something exciting.',
    ),
    _StudioCaption(
      title: 'One studio. Two creative paths.',
      subtitle: 'Build games today and get ready for stories next.',
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

  Future<void> _openGameStudio() async {
    final user = FirebaseAuth.instance.currentUser;

    final isGuest =
        user == null || user.isAnonymous || (user.providerData.isEmpty);

    if (isGuest) {
      final bool? shouldLogin = await showDialog<bool>(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C5CFF),
                    Color(0xFFFF4FD8),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sign in required',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login to create and publish your own games.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFEAD8FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6A11CB),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Not now'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (shouldLogin == true) {
        await Navigator.of(context).pushNamed('/login');
      }

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DiyGamesScreen(),
      ),
    );
  }

  void _openStoryStudio() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StoryBuilderEntryScreen(),
      ),
    );
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
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: _StudioBackgroundGlow()),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
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
                                  '✨ Create • Play • Imagine ✨',
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
                            SizedBox(
                              height: math.max(
                                20,
                                constraints.maxHeight * 0.08,
                              ),
                            ),
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
                                  _EntryActionCard(
                                    icon: Icons.sports_esports_rounded,
                                    title: 'Start Creating Games',
                                    subtitle:
                                    'Open game templates like Memory Match and start building right away.',
                                    buttonLabel: 'Open Game Studio',
                                    buttonIcon: Icons.arrow_forward_rounded,
                                    gradient: const [
                                      Color(0xFFFFD86F),
                                      Color(0xFFFF8A5B),
                                    ],
                                    onTap: _openGameStudio,
                                  ),
                                  const SizedBox(height: 14),
                                  _EntryActionCard(
                                    icon: Icons.auto_stories_rounded,
                                    title: 'Create Stories',
                                    subtitle:
                                    'Enter the story creation zone. Story tools are coming soon.',
                                    buttonLabel: 'Open Story Studio',
                                    buttonIcon: Icons.menu_book_rounded,
                                    gradient: const [
                                      Color(0xFF7C5CFF),
                                      Color(0xFFFF4FD8),
                                    ],
                                    onTap: _openStoryStudio,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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

class _EntryActionCard extends StatelessWidget {
  const _EntryActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final IconData buttonIcon;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 340;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: compact
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.last.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFE9D5FF),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionPill(
                    buttonLabel: buttonLabel,
                    buttonIcon: buttonIcon,
                  ),
                ],
              )
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.last.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFE9D5FF),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionPill(
                          buttonLabel: buttonLabel,
                          buttonIcon: buttonIcon,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.buttonLabel,
    required this.buttonIcon,
  });

  final String buttonLabel;
  final IconData buttonIcon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Text(
              buttonLabel,
              style: const TextStyle(
                color: Color(0xFF4C1D95),
                fontWeight: FontWeight.w900,
              ),
            ),
            Icon(
              buttonIcon,
              color: const Color(0xFF4C1D95),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Stack(
        children: [
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
      ),
    );
  }
}