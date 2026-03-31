import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../world_map_section_data.dart';
import 'world_map_landmark_widget.dart';

class SegmentedWorldMapBackground extends StatelessWidget {
  const SegmentedWorldMapBackground({
    super.key,
    required this.sections,
  });

  final List<WorldMapSectionData> sections;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: sections
          .map(
            (section) => Positioned(
          left: 0,
          right: 0,
          top: section.top,
          height: section.height,
          child: _SectionBackground(section: section),
        ),
      )
          .toList(),
    );
  }
}

class _SectionBackground extends StatelessWidget {
  const _SectionBackground({
    required this.section,
  });

  final WorldMapSectionData section;

  @override
  Widget build(BuildContext context) {
    final theme = section.theme;
    final leftDecoration =
    theme.decorations[(section.sectionIndex * 2) % theme.decorations.length];
    final rightDecoration =
    theme.decorations[(section.sectionIndex * 2 + 1) % theme.decorations.length];

    final screenWidth = MediaQuery.of(context).size.width;
    final overlayWidth = math.min(screenWidth * 0.82, 320.0);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.topColor, theme.bottomColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              theme.backgroundAsset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.topColor, theme.bottomColor],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.04),
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          if (theme.showParallaxClouds)
            Positioned.fill(
              child: _MovingCloudLayer(
                sectionIndex: section.sectionIndex,
              ),
            ),
          if (theme.showLightRays)
            Positioned.fill(
              child: _LightRayLayer(
                sectionIndex: section.sectionIndex,
              ),
            ),
          if (theme.showSparkles)
            Positioned.fill(
              child: _SparkleDriftLayer(
                sectionIndex: section.sectionIndex,
              ),
            ),
          if (theme.showBubbles)
            Positioned.fill(
              child: _BubbleRiseLayer(
                sectionIndex: section.sectionIndex,
              ),
            ),
          Positioned(
            left: -6,
            top: 26,
            child: _AnimatedDecorationEmoji(
              emoji: leftDecoration,
              size: 36,
              opacity: 0.34,
              durationMs: 2400 + ((section.sectionIndex % 3) * 260),
            ),
          ),
          Positioned(
            right: -4,
            top: 94,
            child: _AnimatedDecorationEmoji(
              emoji: rightDecoration,
              size: 40,
              opacity: 0.34,
              durationMs: 2800 + ((section.sectionIndex % 4) * 240),
            ),
          ),
          Positioned(
            left: section.sectionIndex.isEven ? 10 : null,
            right: section.sectionIndex.isEven ? null : 10,
            bottom: 8,
            child: WorldMapLandmarkWidget(
              type: theme.landmarkType,
              width: overlayWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDecorationEmoji extends StatefulWidget {
  const _AnimatedDecorationEmoji({
    required this.emoji,
    required this.size,
    required this.opacity,
    required this.durationMs,
  });

  final String emoji;
  final double size;
  final double opacity;
  final int durationMs;

  @override
  State<_AnimatedDecorationEmoji> createState() => _AnimatedDecorationEmojiState();
}

class _AnimatedDecorationEmojiState extends State<_AnimatedDecorationEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: Duration(milliseconds: widget.durationMs))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dy = 10 - (_controller.value * 20);
          final scale = 0.94 + (_controller.value * 0.10);
          return Opacity(
            opacity: widget.opacity,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(
                scale: scale,
                child: Text(
                  widget.emoji,
                  style: TextStyle(fontSize: widget.size),
                ),
              ),
            ),
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

class _MovingCloudLayer extends StatefulWidget {
  const _MovingCloudLayer({
    required this.sectionIndex,
  });

  final int sectionIndex;

  @override
  State<_MovingCloudLayer> createState() => _MovingCloudLayerState();
}

class _MovingCloudLayerState extends State<_MovingCloudLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 12000))
    ..repeat();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final width = MediaQuery.of(context).size.width;
          final a = -90 + ((width + 180) * _controller.value);
          final b = width - ((width + 220) * _controller.value);
          return Stack(
            children: [
              Positioned(
                left: a,
                top: 20,
                child: Opacity(
                  opacity: 0.24,
                  child: const Icon(Icons.cloud_rounded, size: 74, color: Colors.white),
                ),
              ),
              Positioned(
                left: b,
                top: 74,
                child: Opacity(
                  opacity: 0.16,
                  child: const Icon(Icons.cloud_rounded, size: 58, color: Colors.white),
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

class _LightRayLayer extends StatefulWidget {
  const _LightRayLayer({
    required this.sectionIndex,
  });

  final int sectionIndex;

  @override
  State<_LightRayLayer> createState() => _LightRayLayerState();
}

class _LightRayLayerState extends State<_LightRayLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat(reverse: true);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final opacity = 0.10 + (_controller.value * 0.08);
          return Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 260,
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.65),
                          Colors.white.withOpacity(0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
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

class _SparkleDriftLayer extends StatefulWidget {
  const _SparkleDriftLayer({
    required this.sectionIndex,
  });

  final int sectionIndex;

  @override
  State<_SparkleDriftLayer> createState() => _SparkleDriftLayerState();
}

class _SparkleDriftLayerState extends State<_SparkleDriftLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..repeat();

  static const _points = [
    Offset(0.12, 0.18),
    Offset(0.74, 0.16),
    Offset(0.28, 0.38),
    Offset(0.82, 0.52),
    Offset(0.58, 0.66),
    Offset(0.18, 0.76),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: List.generate(_points.length, (index) {
              final point = _points[index];
              final t = ((_controller.value + (index * 0.16)) % 1.0);
              final opacity = (math.sin(t * math.pi * 2).abs() * 0.55) + 0.08;
              final scale = 0.8 + (math.sin(t * math.pi * 2).abs() * 0.7);
              final dy = math.cos(t * math.pi * 2) * 6;
              return Positioned(
                left: size.width * point.dx,
                top: (size.height * point.dy * 0.24) + dy,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
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

class _BubbleRiseLayer extends StatefulWidget {
  const _BubbleRiseLayer({
    required this.sectionIndex,
  });

  final int sectionIndex;

  @override
  State<_BubbleRiseLayer> createState() => _BubbleRiseLayerState();
}

class _BubbleRiseLayerState extends State<_BubbleRiseLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
    ..repeat();

  static const _bubbles = [
    (0.10, 0.82, 28.0),
    (0.22, 0.70, 18.0),
    (0.82, 0.74, 34.0),
    (0.74, 0.52, 22.0),
    (0.58, 0.86, 20.0),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: List.generate(_bubbles.length, (index) {
              final item = _bubbles[index];
              final phase = ((_controller.value + (index * 0.13)) % 1.0);
              final rise = phase * 54;
              final drift = math.sin(phase * math.pi * 2) * 6;
              final scale = 0.88 + (math.sin(phase * math.pi * 2).abs() * 0.16);
              return Positioned(
                left: (size.width * item.$1) + drift,
                top: (size.height * item.$2 * 0.22) - rise + 110,
                child: Opacity(
                  opacity: 0.18 + ((1 - phase) * 0.24),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: item.$3,
                      height: item.$3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.72), width: 1.4),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.20),
                            Colors.white.withOpacity(0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
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