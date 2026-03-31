import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../platform/play_access/domain/play_pause_message.dart';

class AnimatedPlayPauseMessageCard extends StatefulWidget {
  const AnimatedPlayPauseMessageCard({
    super.key,
    required this.message,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.isBlocking = false,
    this.showClose = false,
    this.onClose,
  });

  final PlayPauseMessage message;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final bool isBlocking;
  final bool showClose;
  final VoidCallback? onClose;

  @override
  State<AnimatedPlayPauseMessageCard> createState() =>
      _AnimatedPlayPauseMessageCardState();
}

class _AnimatedPlayPauseMessageCardState
    extends State<AnimatedPlayPauseMessageCard>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.message.gradientColors;

    final card = FadeTransition(
      opacity: CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOut,
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.first,
                colors.last,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.22),
                blurRadius: 22,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _floatController,
                      _pulseController,
                    ]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _PlayPauseDecorPainter(
                          style: widget.message.animationStyle,
                          floatValue: _floatController.value,
                          pulseValue: _pulseController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showClose)
                    Align(
                      alignment: Alignment.topRight,
                      child: InkWell(
                        onTap: widget.onClose,
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  _AnimatedBadge(
                    icon: widget.message.icon,
                    colors: colors,
                    pulseController: _pulseController,
                    floatController: _floatController,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.message.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.message.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (widget.primaryActionLabel != null)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: widget.onPrimaryAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: colors.first,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          widget.primaryActionLabel!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  if (widget.secondaryActionLabel != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: widget.onSecondaryAction,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          widget.secondaryActionLabel!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!widget.isBlocking) {
      return card;
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.30),
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: card,
        ),
      ),
    );
  }
}

class _AnimatedBadge extends StatelessWidget {
  const _AnimatedBadge({
    required this.icon,
    required this.colors,
    required this.pulseController,
    required this.floatController,
  });

  final IconData icon;
  final List<Color> colors;
  final AnimationController pulseController;
  final AnimationController floatController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([pulseController, floatController]),
      builder: (context, _) {
        final scale = 1 + (pulseController.value * 0.08);
        final dy = math.sin(floatController.value * math.pi) * 5;

        return Transform.translate(
          offset: Offset(0, -dy),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.20),
                border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlayPauseDecorPainter extends CustomPainter {
  const _PlayPauseDecorPainter({
    required this.style,
    required this.floatValue,
    required this.pulseValue,
  });

  final PlayPauseAnimationStyle style;
  final double floatValue;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final whiteSoft = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    final whiteLine = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (style) {
      case PlayPauseAnimationStyle.recharge:
        _drawRecharge(canvas, size, whiteSoft, whiteLine);
        break;
      case PlayPauseAnimationStyle.familyUnlock:
        _drawFamilyUnlock(canvas, size, whiteSoft, whiteLine);
        break;
      case PlayPauseAnimationStyle.confidencePause:
        _drawConfidence(canvas, size, whiteSoft, whiteLine);
        break;
      case PlayPauseAnimationStyle.familyTeam:
        _drawFamilyTeam(canvas, size, whiteSoft, whiteLine);
        break;
    }
  }

  void _drawRecharge(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final yShift = math.sin(floatValue * math.pi) * 6;
    canvas.drawCircle(Offset(size.width * 0.14, size.height * 0.18 + yShift), 12, fill);
    canvas.drawCircle(Offset(size.width * 0.84, size.height * 0.24 - yShift), 8, fill);
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.74),
      26 + (pulseValue * 4),
      stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.16, size.height * 0.78), radius: 20),
      0,
      math.pi,
      false,
      stroke,
    );
  }

  void _drawFamilyUnlock(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final bubbleDx = math.sin(floatValue * math.pi * 2) * 6;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.72 + bubbleDx, size.height * 0.12, 48, 34),
      const Radius.circular(14),
    );
    canvas.drawRRect(rrect, fill);

    final lockRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.70, 44, 34),
      const Radius.circular(10),
    );
    canvas.drawRRect(lockRect, fill);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.16, size.height * 0.71),
        width: 26,
        height: 24,
      ),
      math.pi,
      math.pi,
      false,
      stroke,
    );
  }

  void _drawConfidence(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final shield = Path()
      ..moveTo(size.width * 0.12, size.height * 0.18)
      ..lineTo(size.width * 0.18, size.height * 0.14)
      ..lineTo(size.width * 0.24, size.height * 0.18)
      ..lineTo(size.width * 0.22, size.height * 0.28)
      ..lineTo(size.width * 0.18, size.height * 0.34)
      ..lineTo(size.width * 0.14, size.height * 0.28)
      ..close();
    canvas.drawPath(shield, fill);

    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.78),
      16 + (pulseValue * 3),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.78),
      7,
      fill,
    );
  }

  void _drawFamilyTeam(Canvas canvas, Size size, Paint fill, Paint stroke) {
    final left = Offset(size.width * 0.14, size.height * 0.20);
    final right = Offset(size.width * 0.24, size.height * 0.20);
    canvas.drawCircle(left, 10, fill);
    canvas.drawCircle(right, 10, fill);
    canvas.drawLine(left, right, stroke);

    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.72),
      18 + (pulseValue * 2),
      stroke,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.78),
      10,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _PlayPauseDecorPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.floatValue != floatValue ||
        oldDelegate.pulseValue != pulseValue;
  }
}