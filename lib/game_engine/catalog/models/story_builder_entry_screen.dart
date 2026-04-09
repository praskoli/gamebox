import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../story_creator/data/story_repository.dart';
import '../../../story_creator/presentation/story_meta_screen.dart';
import '../../../story_creator/presentation/story_review_screen.dart';

class StoryBuilderEntryScreen extends StatelessWidget {
  const StoryBuilderEntryScreen({super.key});

  Future<void> _openBuilder(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final bool isGuest = user == null || user.isAnonymous;

    if (isGuest) {
      final bool shouldLogin =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7C5CFF),
                        Color(0xFFB266FF),
                        Color(0xFFFF66D8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_stories,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Save Your Stories ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign in to create, save, and publish your stories.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ) ??
              false;

      if (!shouldLogin) return;

      final result = await Navigator.of(context).pushNamed('/login');
      if (result != true) return;
    }

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StoryMetaScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double minHeight =
        MediaQuery.of(context).size.height -
            MediaQuery.of(context).padding.top -
            MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF18093A),
              Color(0xFF37106B),
              Color(0xFF6D28D9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _StoryBackgroundGlow()),
              FutureBuilder<bool>(
                future: StoryRepository().isCurrentUserAdminReviewer(),
                builder: (context, snapshot) {
                  final bool isAdmin = snapshot.data ?? false;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _CircleGlassButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              if (snapshot.connectionState == ConnectionState.waiting)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.14),
                                    ),
                                  ),
                                  child: const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else if (isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _StoryNeonTitle(text: 'Story'),
                          const _StoryNeonTitle(text: 'Studio'),
                          const SizedBox(height: 12),
                          const Text(
                            '✨ Imagine • Build • Tell ✨',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFCE7F3),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.14),
                              ),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Column(
                              children: <Widget>[
                                _StoryOrbIcon(),
                                SizedBox(height: 16),
                                Text(
                                  'Create Stories',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Build scene-based stories with image upload, narration, preview, TTS, and review-ready submission.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFE9D5FF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _MiniFeatureRow(
                                  icon: Icons.image_outlined,
                                  title: 'Scene-based story creation',
                                  subtitle:
                                  'Create each scene with image, narration, and sound.',
                                ),
                                SizedBox(height: 12),
                                _MiniFeatureRow(
                                  icon: Icons.preview_rounded,
                                  title: 'Preview before submit',
                                  subtitle:
                                  'Play the story with captions, narration, and TTS.',
                                ),
                                SizedBox(height: 12),
                                _MiniFeatureRow(
                                  icon: Icons.verified_rounded,
                                  title: 'Review-ready publishing flow',
                                  subtitle:
                                  'Submit safely for admin approval without touching DIY game flows.',
                                ),
                              ],
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(height: 18),
                            const _AdminSectionHeader(
                              title: 'Story Review Studio',
                              subtitle:
                              'Visible only to configured review admins.',
                            ),
                            const SizedBox(height: 14),
                            const _StoryReviewCard(),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _openBuilder(context),
                              icon: const Icon(Icons.auto_stories_rounded),
                              label: const Text('Start Story Creation'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
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
                          ),
                        ],
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

class _AdminSectionHeader extends StatelessWidget {
  const _AdminSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFFE9D5FF),
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _StoryReviewCard extends StatelessWidget {
  const _StoryReviewCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const StoryReviewScreen(),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFDF2F8),
                Color(0xFFEEF2FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
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
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEC4899),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Review Stories',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Open pending, published, and rejected story reviews',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _ReviewTagChip(label: 'Pending'),
                    _ReviewTagChip(label: 'Published'),
                    _ReviewTagChip(label: 'Rejected'),
                    _ReviewTagChip(label: 'Admin'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Open the story review studio and manage all submitted stories with swipeable review tabs.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF374151),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC4899),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewTagChip extends StatelessWidget {
  const _ReviewTagChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _CircleGlassButton extends StatelessWidget {
  const _CircleGlassButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _StoryOrbIcon extends StatelessWidget {
  const _StoryOrbIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF4FD8), Color(0xFF7C5CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x44FF4FD8),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_stories_rounded,
        color: Colors.white,
        size: 42,
      ),
    );
  }
}

class _MiniFeatureRow extends StatelessWidget {
  const _MiniFeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFE9D5FF),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryBackgroundGlow extends StatelessWidget {
  const _StoryBackgroundGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _StoryGlowPainter()),
    );
  }
}

class _StoryGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint pinkGlow = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0x55FF66D8), Color(0x00FF66D8)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.18, size.height * 0.14),
          radius: size.width * 0.42,
        ),
      );

    final Paint violetGlow = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[Color(0x447C5CFF), Color(0x007C5CFF)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.78),
          radius: size.width * 0.46,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.14),
      size.width * 0.42,
      pinkGlow,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.78),
      size.width * 0.46,
      violetGlow,
    );

    final Paint sparklePaint = Paint()..color = Colors.white.withOpacity(0.16);
    for (int i = 0; i < 26; i++) {
      final double dx = (size.width / 26) * i + 10;
      final double dy = (size.height / 30) * ((i * 3) % 15) + 18;
      canvas.drawCircle(Offset(dx % size.width, dy), 1.2, sparklePaint);
    }

    final Paint trailPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.58,
        size.width * 0.58,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.80,
        size.width * 0.92,
        size.height * 0.60,
      );

    canvas.drawPath(path, trailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StoryNeonTitle extends StatelessWidget {
  const _StoryNeonTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF4FD8),
            letterSpacing: 1.0,
            height: 0.9,
            shadows: <Shadow>[
              Shadow(color: Color(0xFFFF4FD8), blurRadius: 24),
              Shadow(color: Color(0xFF7C5CFF), blurRadius: 40),
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
            shadows: <Shadow>[
              Shadow(color: Color(0xFFFFC8F2), blurRadius: 12),
            ],
          ),
        ),
      ],
    );
  }
}