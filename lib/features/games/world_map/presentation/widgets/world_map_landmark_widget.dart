import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/world_map_section_theme.dart';

class WorldMapLandmarkWidget extends StatelessWidget {
  const WorldMapLandmarkWidget({
    super.key,
    required this.type,
    required this.width,
  });

  final WorldMapLandmarkType type;
  final double width;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case WorldMapLandmarkType.fruitCart:
        return _FruitCartOverlay(width: width);
      case WorldMapLandmarkType.woodenBridge:
        return _WoodenBridgeOverlay(width: width);
      case WorldMapLandmarkType.juiceWaterfall:
        return _JuiceWaterfallOverlay(width: width);
      case WorldMapLandmarkType.trainCrossingGate:
        return _TrainCrossingOverlay(width: width);
      case WorldMapLandmarkType.picnicGround:
        return _PicnicGroundOverlay(width: width);
      case WorldMapLandmarkType.candyTunnel:
        return _CandyTunnelOverlay(width: width);
      case WorldMapLandmarkType.balloonArch:
        return _BalloonFestivalOverlay(width: width);
      case WorldMapLandmarkType.marketStall:
        return _MarketOverlay(width: width);
      case WorldMapLandmarkType.orchardFence:
        return _OrchardOverlay(width: width);
      case WorldMapLandmarkType.windmill:
        return _WindmillOverlay(width: width);
      case WorldMapLandmarkType.fountain:
        return _FountainOverlay(width: width);
      case WorldMapLandmarkType.toyTrainTrackCrossing:
        return _ToyTrainOverlay(width: width);
      case WorldMapLandmarkType.crystalCavern:
        return _CrystalOverlay(width: width);
      case WorldMapLandmarkType.dreamMeadow:
        return _DreamCloudOverlay(width: width);
      case WorldMapLandmarkType.bubbleForest:
        return _BubbleForestOverlay(width: width);
      case WorldMapLandmarkType.toyWorkshop:
        return _ToyWorkshopOverlay(width: width);
    }
  }
}

class _CinematicPanel extends StatelessWidget {
  const _CinematicPanel({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

class _FruitCartOverlay extends StatefulWidget {
  const _FruitCartOverlay({required this.width});
  final double width;

  @override
  State<_FruitCartOverlay> createState() => _FruitCartOverlayState();
}

class _FruitCartOverlayState extends State<_FruitCartOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final tilt = math.sin(_controller.value * math.pi * 2) * 0.03;
          final dx = math.cos(_controller.value * math.pi * 2) * 5;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(
                  child: Transform.translate(
                    offset: Offset(dx, 0),
                    child: Transform.rotate(
                      angle: tilt,
                      child: Text(
                        '🛒🍎🍐',
                        style: TextStyle(fontSize: widget.width * 0.16),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                top: 10,
                child: Opacity(
                  opacity: 0.55,
                  child: Transform.translate(
                    offset: Offset(0, -8 * _controller.value),
                    child: const Text('🍃', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
              Positioned(
                right: 28,
                top: 22,
                child: Opacity(
                  opacity: 0.48,
                  child: Transform.translate(
                    offset: Offset(0, -10 * ((1 + _controller.value) / 2)),
                    child: const Text('🍃', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _WoodenBridgeOverlay extends StatefulWidget {
  const _WoodenBridgeOverlay({required this.width});
  final double width;

  @override
  State<_WoodenBridgeOverlay> createState() => _WoodenBridgeOverlayState();
}

class _WoodenBridgeOverlayState extends State<_WoodenBridgeOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 94,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dy = math.sin(_controller.value * math.pi * 2) * 2;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 8 + dy,
                child: const Center(
                  child: Text('🌉', style: TextStyle(fontSize: 48)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _JuiceWaterfallOverlay extends StatefulWidget {
  const _JuiceWaterfallOverlay({required this.width});
  final double width;

  @override
  State<_JuiceWaterfallOverlay> createState() => _JuiceWaterfallOverlayState();
}

class _JuiceWaterfallOverlayState extends State<_JuiceWaterfallOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 150,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final splashScale = 0.88 + (math.sin(_controller.value * math.pi * 2).abs() * 0.18);
          final shimmer = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 6,
                child: Opacity(
                  opacity: 0.44,
                  child: Container(
                    width: 20,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0x66FFF7AE),
                          const Color(0xAAF59E0B),
                          const Color(0x33F59E0B),
                        ],
                        stops: [0.0, shimmer.clamp(0.2, 0.8), 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: widget.width * 0.40,
                child: Opacity(
                  opacity: 0.26,
                  child: Container(
                    width: 10,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0x99FFF7AE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: widget.width * 0.40,
                child: Opacity(
                  opacity: 0.26,
                  child: Container(
                    width: 10,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0x99FFF7AE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                child: Transform.scale(
                  scale: splashScale,
                  child: const Text(
                    '💦',
                    style: TextStyle(fontSize: 42),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                top: 10,
                child: Opacity(
                  opacity: 0.54,
                  child: Transform.translate(
                    offset: Offset(0, 6 * math.sin(_controller.value * math.pi * 2)),
                    child: const Text('✨', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _TrainCrossingOverlay extends StatefulWidget {
  const _TrainCrossingOverlay({required this.width});
  final double width;

  @override
  State<_TrainCrossingOverlay> createState() => _TrainCrossingOverlayState();
}

class _TrainCrossingOverlayState extends State<_TrainCrossingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 138,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final x = -70 + ((widget.width + 140) * _controller.value);
          final blinkOn = _controller.value < 0.5;
          final barrierAngle = -0.08 - (0.18 * math.sin(_controller.value * math.pi * 2).abs());
          return Stack(
            children: [
              Positioned(
                left: 20,
                right: 20,
                bottom: 34,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                left: x,
                bottom: 30,
                child: const Text(
                  '🚂',
                  style: TextStyle(fontSize: 42),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 16,
                child: Transform.rotate(
                  angle: barrierAngle,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 66,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444), width: 2),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 20,
                child: Row(
                  children: [
                    _SignalLight(active: blinkOn),
                    const SizedBox(width: 6),
                    _SignalLight(active: !blinkOn),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _SignalLight extends StatelessWidget {
  const _SignalLight({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFEF4444) : const Color(0xFFFCA5A5),
        shape: BoxShape.circle,
        boxShadow: active
            ? const [
          BoxShadow(
            color: Color(0x44EF4444),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ]
            : const [],
      ),
    );
  }
}

class _PicnicGroundOverlay extends StatefulWidget {
  const _PicnicGroundOverlay({required this.width});
  final double width;

  @override
  State<_PicnicGroundOverlay> createState() => _PicnicGroundOverlayState();
}

class _PicnicGroundOverlayState extends State<_PicnicGroundOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 110,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final butterflyY = math.sin(_controller.value * math.pi * 2) * 10;
          final clothScale = 1 + (math.sin(_controller.value * math.pi * 2) * 0.035);
          return Stack(
            children: [
              Positioned(
                left: widget.width * 0.16,
                bottom: 14,
                child: Transform.scale(
                  scale: clothScale,
                  child: Container(
                    width: 84,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0x44F472B6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 26,
                bottom: 20,
                child: Text('🧺', style: TextStyle(fontSize: 30)),
              ),
              Positioned(
                right: 38,
                top: 16 + butterflyY,
                child: const Text('🦋', style: TextStyle(fontSize: 20)),
              ),
              Positioned(
                left: widget.width * 0.56,
                bottom: 18,
                child: const Text('🌼', style: TextStyle(fontSize: 22)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CandyTunnelOverlay extends StatefulWidget {
  const _CandyTunnelOverlay({required this.width});
  final double width;

  @override
  State<_CandyTunnelOverlay> createState() => _CandyTunnelOverlayState();
}

class _CandyTunnelOverlayState extends State<_CandyTunnelOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 118,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = 0.9 + (math.sin(_controller.value * math.pi * 2).abs() * 0.16);
          final sparkleOpacity = 0.18 + (math.sin(_controller.value * math.pi * 2).abs() * 0.35);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 20,
                child: Transform.scale(
                  scale: glow,
                  child: Container(
                    width: widget.width * 0.44,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0x44FDE68A), Color(0x66F59E0B), Color(0x22FFFFFF)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                child: const Text(
                  '🍭🍬🍩',
                  style: TextStyle(fontSize: 34),
                ),
              ),
              Positioned(
                left: 20,
                top: 10,
                child: Opacity(
                  opacity: sparkleOpacity,
                  child: const Text('✨', style: TextStyle(fontSize: 18)),
                ),
              ),
              Positioned(
                right: 24,
                top: 24,
                child: Opacity(
                  opacity: sparkleOpacity * 0.9,
                  child: const Text('✨', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _BalloonFestivalOverlay extends StatefulWidget {
  const _BalloonFestivalOverlay({required this.width});
  final double width;

  @override
  State<_BalloonFestivalOverlay> createState() => _BalloonFestivalOverlayState();
}

class _BalloonFestivalOverlayState extends State<_BalloonFestivalOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 160,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final base = _controller.value;
          final b1 = 90 - (base * 44);
          final b2 = 104 - (((base + 0.35) % 1.0) * 36);
          final b3 = 86 - (((base + 0.70) % 1.0) * 48);
          return Stack(
            children: [
              Positioned(left: 14, top: b1, child: const Text('🎈', style: TextStyle(fontSize: 26))),
              Positioned(right: 20, top: b2, child: const Text('🎈', style: TextStyle(fontSize: 28))),
              Positioned(left: widget.width * 0.44, top: b3, child: const Text('🎈', style: TextStyle(fontSize: 22))),
              Positioned(
                left: 10,
                right: 10,
                bottom: 28,
                child: Transform.rotate(
                  angle: math.sin(base * math.pi * 2) * 0.02,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0x66FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Text(
                  '🎊 🎉 🎊',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _MarketOverlay extends StatefulWidget {
  const _MarketOverlay({required this.width});
  final double width;

  @override
  State<_MarketOverlay> createState() => _MarketOverlayState();
}

class _MarketOverlayState extends State<_MarketOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 126,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final sway = math.sin(_controller.value * math.pi * 2) * 3;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 10,
                child: Transform.rotate(
                  angle: sway * 0.004,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('🎏', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 10),
                      Text('🎏', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 10),
                      Text('🎏', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                bottom: 18 + sway,
                child: const Text('🍊🍇', style: TextStyle(fontSize: 30)),
              ),
              Positioned(
                right: 20,
                bottom: 16 - sway,
                child: const Text('🍍🥭', style: TextStyle(fontSize: 30)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _OrchardOverlay extends StatefulWidget {
  const _OrchardOverlay({required this.width});
  final double width;

  @override
  State<_OrchardOverlay> createState() => _OrchardOverlayState();
}

class _OrchardOverlayState extends State<_OrchardOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 132,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final drift = _controller.value;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: const Center(
                  child: Text('🍎🍎', style: TextStyle(fontSize: 34)),
                ),
              ),
              Positioned(
                left: 20,
                top: 18 + (drift * 24),
                child: Opacity(
                  opacity: 0.34,
                  child: const Text('🍃', style: TextStyle(fontSize: 18)),
                ),
              ),
              Positioned(
                right: 24,
                top: 28 + (((drift + 0.4) % 1.0) * 22),
                child: Opacity(
                  opacity: 0.30,
                  child: const Text('🍃', style: TextStyle(fontSize: 20)),
                ),
              ),
              Positioned(
                left: widget.width * 0.46,
                top: 14 + (((drift + 0.7) % 1.0) * 28),
                child: Opacity(
                  opacity: 0.24,
                  child: const Text('🍃', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _WindmillOverlay extends StatefulWidget {
  const _WindmillOverlay({required this.width});
  final double width;

  @override
  State<_WindmillOverlay> createState() => _WindmillOverlayState();
}

class _WindmillOverlayState extends State<_WindmillOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 114,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 12,
                child: Container(width: 8, height: 30, color: Colors.white38),
              ),
              Transform.rotate(
                angle: _controller.value * math.pi * 2,
                child: const Icon(Icons.close_rounded, size: 46, color: Colors.white70),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _FountainOverlay extends StatefulWidget {
  const _FountainOverlay({required this.width});
  final double width;

  @override
  State<_FountainOverlay> createState() => _FountainOverlayState();
}

class _FountainOverlayState extends State<_FountainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 148,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final jetHeight = 24 + (math.sin(_controller.value * math.pi * 2).abs() * 20);
          final rippleScale = 0.88 + (_controller.value * 0.28);
          final rippleOpacity = 0.34 * (1 - _controller.value);
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                bottom: 12,
                child: Opacity(
                  opacity: rippleOpacity,
                  child: Transform.scale(
                    scale: rippleScale,
                    child: Container(
                      width: 90,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.55), width: 2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                child: const Text('⛲', style: TextStyle(fontSize: 46)),
              ),
              Positioned(
                bottom: 54,
                child: Container(
                  width: 12,
                  height: jetHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.68),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ToyTrainOverlay extends StatefulWidget {
  const _ToyTrainOverlay({required this.width});
  final double width;

  @override
  State<_ToyTrainOverlay> createState() => _ToyTrainOverlayState();
}

class _ToyTrainOverlayState extends State<_ToyTrainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final x = -42 + ((widget.width + 84) * _controller.value);
          return Stack(
            children: [
              Positioned(
                left: x,
                bottom: 18,
                child: const Text('🚂🧸', style: TextStyle(fontSize: 32)),
              ),
              Positioned(
                right: 12,
                top: 18,
                child: Opacity(
                  opacity: 0.34 + (0.26 * (1 - _controller.value)),
                  child: const Text('💨', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _CrystalOverlay extends StatefulWidget {
  const _CrystalOverlay({required this.width});
  final double width;

  @override
  State<_CrystalOverlay> createState() => _CrystalOverlayState();
}

class _CrystalOverlayState extends State<_CrystalOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 120,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = 0.88 + (math.sin(_controller.value * math.pi * 2).abs() * 0.18);
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: glow,
                child: const Text(
                  '💎✨💎',
                  style: TextStyle(fontSize: 34),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _DreamCloudOverlay extends StatefulWidget {
  const _DreamCloudOverlay({required this.width});
  final double width;

  @override
  State<_DreamCloudOverlay> createState() => _DreamCloudOverlayState();
}

class _DreamCloudOverlayState extends State<_DreamCloudOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 130,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dx = math.sin(_controller.value * math.pi * 2) * 12;
          return Stack(
            children: [
              Positioned(
                left: 20 + dx,
                top: 10,
                child: const Text('☁️', style: TextStyle(fontSize: 28)),
              ),
              Positioned(
                right: 26 - dx,
                top: 22,
                child: const Text('🌙', style: TextStyle(fontSize: 24)),
              ),
              Positioned(
                left: widget.width * 0.48,
                bottom: 16,
                child: const Text('⭐', style: TextStyle(fontSize: 22)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _BubbleForestOverlay extends StatefulWidget {
  const _BubbleForestOverlay({required this.width});
  final double width;

  @override
  State<_BubbleForestOverlay> createState() => _BubbleForestOverlayState();
}

class _BubbleForestOverlayState extends State<_BubbleForestOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 152,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final y1 = 92 - (_controller.value * 44);
          final y2 = 104 - (((_controller.value + 0.4) % 1.0) * 34);
          final y3 = 114 - (((_controller.value + 0.75) % 1.0) * 40);
          return Stack(
            children: [
              Positioned(left: 16, bottom: y1, child: const Text('🫧', style: TextStyle(fontSize: 30))),
              Positioned(right: 24, bottom: y2, child: const Text('🫧', style: TextStyle(fontSize: 26))),
              Positioned(left: widget.width * 0.52, bottom: y3, child: const Text('🫧', style: TextStyle(fontSize: 22))),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ToyWorkshopOverlay extends StatefulWidget {
  const _ToyWorkshopOverlay({required this.width});
  final double width;

  @override
  State<_ToyWorkshopOverlay> createState() => _ToyWorkshopOverlayState();
}

class _ToyWorkshopOverlayState extends State<_ToyWorkshopOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return _CinematicPanel(
      width: widget.width,
      height: 134,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final spin = _controller.value * math.pi * 2;
          final rocketDy = math.sin(_controller.value * math.pi * 2) * 6;
          return Stack(
            children: [
              Positioned(
                left: 18,
                bottom: 18,
                child: Transform.rotate(
                  angle: spin,
                  child: const Icon(Icons.settings, size: 28, color: Colors.white70),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 26 + rocketDy,
                child: const Text('🚀', style: TextStyle(fontSize: 30)),
              ),
              Positioned(
                left: widget.width * 0.38,
                top: 16,
                child: const Text('🧩', style: TextStyle(fontSize: 24)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}