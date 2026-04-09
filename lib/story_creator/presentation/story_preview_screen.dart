import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/story_repository.dart';
import '../domain/scene_model.dart';
import '../domain/story_model.dart';

class StoryPreviewScreen extends StatefulWidget {
  const StoryPreviewScreen({
    super.key,
    required this.story,
    required this.scenes,
    this.allowSubmit = false,
  });

  final StoryModel story;
  final List<SceneModel> scenes;
  final bool allowSubmit;

  @override
  State<StoryPreviewScreen> createState() => _StoryPreviewScreenState();
}

class _StoryPreviewScreenState extends State<StoryPreviewScreen>
    with TickerProviderStateMixin {
  final FlutterTts _tts = FlutterTts();
  final StoryRepository _repository = StoryRepository();

  late final AnimationController _transitionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  final Map<int, ImageProvider> _sceneImageProviders = <int, ImageProvider>{};
  final Set<int> _precachedSceneIndexes = <int>{};
  bool _brandAssetReady = false;

  int _index = 0;
  int _previousIndex = 0;
  bool _speaking = false;
  bool _isTransitioning = false;
  bool _isSubmitting = false;

  Timer? _autoplayDelayTimer;
  Future<void>? _backgroundWarmFuture;

  int get _totalPages => widget.scenes.length + 1;
  bool get _isBrandScene => _index == widget.scenes.length;
  String get _creatorName => widget.story.creatorName.trim();

  @override
  void initState() {
    super.initState();

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.035,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _transitionController,
        curve: Curves.easeOutCubic,
      ),
    );

    _primeImageProviders();

    _tts.setCompletionHandler(() async {
      if (!mounted) return;

      setState(() => _speaking = false);

      if (_index < _totalPages - 1) {
        _autoplayDelayTimer?.cancel();
        _autoplayDelayTimer = Timer(
          const Duration(milliseconds: 650),
              () async {
            if (!mounted) return;
            await _goToIndex(_index + 1, autoPlayAfter: true);
          },
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _warmWindowAround(_index);
      _backgroundWarmFuture = _warmRemainingScenesInBackground();
      if (!mounted) return;
      await _playCurrentScene(initial: true);
    });
  }

  @override
  void dispose() {
    _autoplayDelayTimer?.cancel();
    _tts.stop();
    _transitionController.dispose();
    super.dispose();
  }

  void _primeImageProviders() {
    for (int i = 0; i < widget.scenes.length; i++) {
      final String url = widget.scenes[i].imageUrl.trim();
      if (url.isNotEmpty) {
        _sceneImageProviders[i] = NetworkImage(url);
      }
    }
  }

  Future<void> _precacheBrandAsset() async {
    if (_brandAssetReady || !mounted) return;
    try {
      await precacheImage(
        const AssetImage('assets/images/gamebox.png'),
        context,
      );
      _brandAssetReady = true;
    } catch (_) {}
  }

  Future<void> _precacheSceneIndex(int index) async {
    if (!mounted) return;
    if (index < 0 || index >= widget.scenes.length) return;
    if (_precachedSceneIndexes.contains(index)) return;

    final ImageProvider? provider = _sceneImageProviders[index];
    if (provider == null) return;

    try {
      await precacheImage(provider, context);
      _precachedSceneIndexes.add(index);
    } catch (_) {}
  }

  Future<void> _warmWindowAround(int centerIndex) async {
    if (!mounted) return;

    await _precacheBrandAsset();

    final List<Future<void>> futures = <Future<void>>[];

    for (int i = centerIndex - 1; i <= centerIndex + 3; i++) {
      if (i >= 0 && i < widget.scenes.length) {
        futures.add(_precacheSceneIndex(i));
      }
    }

    await Future.wait(futures);
  }

  Future<void> _warmRemainingScenesInBackground() async {
    if (!mounted) return;

    await _precacheBrandAsset();

    for (int i = 0; i < widget.scenes.length; i++) {
      if (!mounted) return;
      if (_precachedSceneIndexes.contains(i)) continue;

      await _precacheSceneIndex(i);
      await Future<void>.delayed(const Duration(milliseconds: 35));
    }
  }

  Future<void> _playCurrentScene({bool initial = false}) async {
    await _tts.stop();

    if (!mounted) return;

    await _warmWindowAround(_index);

    if (!initial) {
      setState(() {
        _speaking = false;
        _isTransitioning = true;
      });

      _transitionController.reset();
      await _transitionController.forward();
    } else {
      _transitionController.value = 1.0;
    }

    if (!mounted) return;

    setState(() {
      _isTransitioning = false;
    });

    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;

    await _tts.setLanguage(_languageCode(widget.story.language));
    await _tts.setSpeechRate(0.42);

    if (_isBrandScene) {
      await _tts.speak(
        'This story was created using GameBox DIY Studio. Create your own stories today.',
      );
    } else {
      await _tts.speak(widget.scenes[_index].narration);
    }

    if (mounted) {
      setState(() => _speaking = true);
    }
  }

  Future<void> _togglePlay() async {
    _autoplayDelayTimer?.cancel();

    if (_speaking) {
      await _tts.stop();
      if (mounted) {
        setState(() => _speaking = false);
      }
      return;
    }

    await _playCurrentScene();
  }

  Future<void> _goToIndex(
      int newIndex, {
        required bool autoPlayAfter,
      }) async {
    if (newIndex < 0 || newIndex >= _totalPages) return;
    if (_isTransitioning) return;
    if (newIndex == _index) return;

    _autoplayDelayTimer?.cancel();
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _speaking = false;
      _previousIndex = _index;
      _index = newIndex;
    });

    await _warmWindowAround(newIndex);

    if (!mounted) return;

    if (autoPlayAfter) {
      await _playCurrentScene();
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _repository.submitForReview(
        story: widget.story,
        scenes: widget.scenes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story submitted for review.')),
      );
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _languageCode(String label) {
    switch (label.toLowerCase()) {
      case 'telugu':
        return 'te-IN';
      case 'hindi':
        return 'hi-IN';
      case 'english':
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? currentProvider =
    !_isBrandScene ? _sceneImageProviders[_index] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0823),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AnimatedBuilder(
              animation: _transitionController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: _SceneVisual(
                sceneKey: ValueKey<String>('preview_scene_$_index'),
                isBrandScene: _isBrandScene,
                sceneImageProvider: currentProvider,
                scene: !_isBrandScene ? widget.scenes[_index] : null,
              ),
            ),
            const _EdgeFadeOverlay(),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 14,
              right: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.story.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _creatorName.isNotEmpty
                                ? 'Preview • by $_creatorName'
                                : 'Preview before submit',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Pill(text: '${_index + 1}/$_totalPages'),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: widget.allowSubmit
                  ? MediaQuery.of(context).padding.bottom + 86
                  : MediaQuery.of(context).padding.bottom + 14,
              child: _StoryBottomBar(
                currentIndex: _index,
                previousIndex: _previousIndex,
                totalPages: _totalPages,
                isPlaying: _speaking,
                onPlayPauseTap: _togglePlay,
              ),
            ),
            if (widget.allowSubmit)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit for Review',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: const Color(0xFFFF4FD8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StoryBottomBar extends StatelessWidget {
  const _StoryBottomBar({
    required this.currentIndex,
    required this.previousIndex,
    required this.totalPages,
    required this.isPlaying,
    required this.onPlayPauseTap,
  });

  final int currentIndex;
  final int previousIndex;
  final int totalPages;
  final bool isPlaying;
  final VoidCallback onPlayPauseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: <Widget>[
          _PlayPauseChip(
            isPlaying: isPlaying,
            onTap: onPlayPauseTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SceneProgressStrip(
              total: totalPages,
              currentIndex: currentIndex,
              previousIndex: previousIndex,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayPauseChip extends StatelessWidget {
  const _PlayPauseChip({
    required this.isPlaying,
    required this.onTap,
  });

  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF5B21B6),
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              isPlaying ? 'Pause' : 'Play',
              style: const TextStyle(
                color: Color(0xFF5B21B6),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneProgressStrip extends StatefulWidget {
  const _SceneProgressStrip({
    required this.total,
    required this.currentIndex,
    required this.previousIndex,
  });

  final int total;
  final int currentIndex;
  final int previousIndex;

  @override
  State<_SceneProgressStrip> createState() => _SceneProgressStripState();
}

class _SceneProgressStripState extends State<_SceneProgressStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _SceneProgressStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerCurrentNode();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerCurrentNode();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _centerCurrentNode() {
    if (!_scrollController.hasClients) return;
    if (widget.total <= 10) return;

    const double nodeWidth = 32;
    const double sidePadding = 2;
    final double itemExtent = nodeWidth + (sidePadding * 2);
    final double viewport = _scrollController.position.viewportDimension;
    final double target =
        (widget.currentIndex * itemExtent) - (viewport / 2) + (itemExtent / 2);

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double clamped = target.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.total <= 10) {
      return Row(
        children: List<Widget>.generate(widget.total, (int index) {
          final bool completed = index < widget.currentIndex;
          final bool current = index == widget.currentIndex;
          final bool recentlyCompleted = index == widget.previousIndex &&
              widget.previousIndex < widget.currentIndex;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _SceneProgressNode(
                completed: completed,
                current: current,
                recentlyCompleted: recentlyCompleted,
              ),
            ),
          );
        }),
      );
    }

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List<Widget>.generate(widget.total, (int index) {
          final bool completed = index < widget.currentIndex;
          final bool current = index == widget.currentIndex;
          final bool recentlyCompleted = index == widget.previousIndex &&
              widget.previousIndex < widget.currentIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: SizedBox(
              width: 32,
              child: _SceneProgressNode(
                completed: completed,
                current: current,
                recentlyCompleted: recentlyCompleted,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SceneProgressNode extends StatefulWidget {
  const _SceneProgressNode({
    required this.completed,
    required this.current,
    required this.recentlyCompleted,
  });

  final bool completed;
  final bool current;
  final bool recentlyCompleted;

  @override
  State<_SceneProgressNode> createState() => _SceneProgressNodeState();
}

class _SceneProgressNodeState extends State<_SceneProgressNode>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _trailController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _trailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    if (widget.current) {
      _pulseController.repeat(reverse: true);
    }

    if (widget.recentlyCompleted) {
      _trailController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant _SceneProgressNode oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.current && !oldWidget.current) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.current && oldWidget.current) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }

    if (widget.recentlyCompleted && !oldWidget.recentlyCompleted) {
      _trailController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _trailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color completeColor = Colors.orange.shade300;
    final Color currentColor = const Color(0xFFFFA726);
    final Color upcomingBorder = Colors.orange.shade300.withOpacity(0.95);

    return AnimatedBuilder(
      animation:
      Listenable.merge(<Listenable>[_pulseController, _trailController]),
      builder: (context, child) {
        final double pulse = widget.current ? (_pulseController.value * 4) : 0;
        final double size = widget.current ? 22 + pulse : 18;

        final double trailGlow =
        widget.recentlyCompleted ? (1 - _trailController.value) : 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 26,
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.completed || widget.current
                  ? (widget.current ? currentColor : completeColor)
                  : Colors.transparent,
              border: Border.all(
                color: widget.current
                    ? currentColor
                    : widget.completed
                    ? completeColor
                    : upcomingBorder,
                width: widget.current ? 2.2 : 1.8,
              ),
              boxShadow: <BoxShadow>[
                if (widget.current)
                  BoxShadow(
                    color: currentColor.withOpacity(0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                if (widget.completed)
                  BoxShadow(
                    color: completeColor.withOpacity(0.18 + (trailGlow * 0.35)),
                    blurRadius: 8 + (trailGlow * 8),
                    spreadRadius: trailGlow * 1.2,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SceneVisual extends StatelessWidget {
  const _SceneVisual({
    required this.sceneKey,
    required this.isBrandScene,
    required this.sceneImageProvider,
    required this.scene,
  });

  final Key sceneKey;
  final bool isBrandScene;
  final ImageProvider? sceneImageProvider;
  final SceneModel? scene;

  @override
  Widget build(BuildContext context) {
    final _MotionPreset preset = _MotionPreset.fromScene(
      title: scene?.title ?? '',
      narration: scene?.narration ?? '',
      isBrandScene: isBrandScene,
    );

    final String ambientType = _detectSceneType(scene, isBrandScene);

    return _CinematicMotionLayer(
      key: sceneKey,
      preset: preset,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (isBrandScene)
            Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(
                  'assets/images/gamebox.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 120,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.28),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: const Text(
                        'Create your own stories in minutes',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            _NetworkSceneImage(sceneImageProvider: sceneImageProvider),
          _AmbientEffectsLayer(type: ambientType),
        ],
      ),
    );
  }

  String _detectSceneType(SceneModel? scene, bool isBrandScene) {
    if (isBrandScene) return 'magic';

    final String text =
    '${scene?.title ?? ''} ${scene?.narration ?? ''}'.toLowerCase();

    if (text.contains('jungle') ||
        text.contains('forest') ||
        text.contains('tree') ||
        text.contains('leaves')) {
      return 'forest';
    }

    if (text.contains('magic') ||
        text.contains('night') ||
        text.contains('stars') ||
        text.contains('moon') ||
        text.contains('sparkle')) {
      return 'magic';
    }

    if (text.contains('water') ||
        text.contains('river') ||
        text.contains('waterfall') ||
        text.contains('mist') ||
        text.contains('ocean')) {
      return 'water';
    }

    return 'none';
  }
}

class _NetworkSceneImage extends StatelessWidget {
  const _NetworkSceneImage({
    required this.sceneImageProvider,
  });

  final ImageProvider? sceneImageProvider;

  @override
  Widget build(BuildContext context) {
    if (sceneImageProvider == null) {
      return Container(
        color: const Color(0xFF12062E),
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_rounded,
          color: Colors.white70,
          size: 54,
        ),
      );
    }

    return Image(
      image: sceneImageProvider!,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFF12062E),
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_rounded,
            color: Colors.white70,
            size: 54,
          ),
        );
      },
    );
  }
}

class _CinematicMotionLayer extends StatefulWidget {
  const _CinematicMotionLayer({
    super.key,
    required this.child,
    required this.preset,
  });

  final Widget child;
  final _MotionPreset preset;

  @override
  State<_CinematicMotionLayer> createState() => _CinematicMotionLayerState();
}

class _CinematicMotionLayerState extends State<_CinematicMotionLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _MotionPreset preset = widget.preset;

    return AnimatedBuilder(
      animation: _motionController,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_motionController.value);
        final double scale =
            preset.scaleStart + ((preset.scaleEnd - preset.scaleStart) * t);
        final double dx =
            preset.dxStart + ((preset.dxEnd - preset.dxStart) * t);
        final double dy =
            preset.dyStart + ((preset.dyEnd - preset.dyStart) * t);

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _MotionPreset {
  const _MotionPreset({
    required this.scaleStart,
    required this.scaleEnd,
    required this.dxStart,
    required this.dxEnd,
    required this.dyStart,
    required this.dyEnd,
  });

  final double scaleStart;
  final double scaleEnd;
  final double dxStart;
  final double dxEnd;
  final double dyStart;
  final double dyEnd;

  factory _MotionPreset.fromScene({
    required String title,
    required String narration,
    required bool isBrandScene,
  }) {
    if (isBrandScene) {
      return const _MotionPreset(
        scaleStart: 1.04,
        scaleEnd: 1.09,
        dxStart: -6,
        dxEnd: 6,
        dyStart: 0,
        dyEnd: -4,
      );
    }

    final String text = '${title.toLowerCase()} ${narration.toLowerCase()}';

    if (_containsAny(text, <String>[
      'jungle',
      'walk',
      'walking',
      'journey',
      'path',
      'forest',
      'travel',
      'road',
      'trail',
      'adventure',
    ])) {
      return const _MotionPreset(
        scaleStart: 1.06,
        scaleEnd: 1.11,
        dxStart: -16,
        dxEnd: 14,
        dyStart: 0,
        dyEnd: -3,
      );
    }

    if (_containsAny(text, <String>[
      'water',
      'river',
      'waterfall',
      'ocean',
      'mist',
      'lake',
      'rainbow',
      'boat',
      'sea',
    ])) {
      return const _MotionPreset(
        scaleStart: 1.05,
        scaleEnd: 1.09,
        dxStart: -8,
        dxEnd: 8,
        dyStart: -4,
        dyEnd: 6,
      );
    }

    if (_containsAny(text, <String>[
      'night',
      'stars',
      'moon',
      'dream',
      'magic',
      'mystery',
      'hidden',
      'attic',
      'cave',
      'glow',
    ])) {
      return const _MotionPreset(
        scaleStart: 1.08,
        scaleEnd: 1.14,
        dxStart: 0,
        dxEnd: 4,
        dyStart: 4,
        dyEnd: -8,
      );
    }

    if (_containsAny(text, <String>[
      'run',
      'running',
      'chase',
      'danger',
      'escape',
      'rush',
      'quickly',
      'bridge',
      'climb',
      'cross',
    ])) {
      return const _MotionPreset(
        scaleStart: 1.07,
        scaleEnd: 1.13,
        dxStart: -12,
        dxEnd: 12,
        dyStart: 2,
        dyEnd: -2,
      );
    }

    return const _MotionPreset(
      scaleStart: 1.05,
      scaleEnd: 1.10,
      dxStart: -5,
      dxEnd: 5,
      dyStart: 2,
      dyEnd: -4,
    );
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final String keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}

class _AmbientEffectsLayer extends StatelessWidget {
  const _AmbientEffectsLayer({
    required this.type,
  });

  final String type;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'forest':
        return const _FloatingLeaves();
      case 'magic':
        return const _Sparkles();
      case 'water':
        return const _MistEffect();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _FloatingLeaves extends StatefulWidget {
  const _FloatingLeaves();

  @override
  State<_FloatingLeaves> createState() => _FloatingLeavesState();
}

class _FloatingLeavesState extends State<_FloatingLeaves>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Stack(
            children: List<Widget>.generate(6, (int i) {
              final double t = (_controller.value + i * 0.16) % 1;
              final double xDrift = (t * 20) - 10;

              return Positioned(
                top: t * size.height,
                left: ((i * 58.0) % size.width) + xDrift,
                child: Opacity(
                  opacity: 0.20,
                  child: Transform.rotate(
                    angle: t * 6,
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFFB7FFB0),
                      size: 16,
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
}

class _Sparkles extends StatefulWidget {
  const _Sparkles();

  @override
  State<_Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<_Sparkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return Stack(
            children: List<Widget>.generate(10, (int i) {
              final double t = (_controller.value + i * 0.09) % 1;
              final double opacity = 0.2 + ((i % 3) * 0.08);

              return Positioned(
                top: (t * size.height),
                left: ((i * 43.0) % size.width),
                child: Opacity(
                  opacity: opacity,
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: 8,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _MistEffect extends StatefulWidget {
  const _MistEffect();

  @override
  State<_MistEffect> createState() => _MistEffectState();
}

class _MistEffectState extends State<_MistEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final double dx = (_controller.value * 40) - 20;
          return Transform.translate(
            offset: Offset(dx, 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.white.withOpacity(0.06),
                    Colors.transparent,
                    Colors.white.withOpacity(0.03),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EdgeFadeOverlay extends StatelessWidget {
  const _EdgeFadeOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFF0E0823).withOpacity(0.58),
            Colors.transparent,
            Colors.transparent,
            const Color(0xFF0E0823).withOpacity(0.42),
            const Color(0xFF0E0823).withOpacity(0.72),
          ],
          stops: const <double>[0.0, 0.18, 0.58, 0.82, 1.0],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.24),
          border: Border.all(
            color: Colors.white.withOpacity(0.16),
          ),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}