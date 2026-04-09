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

class _StoryPreviewScreenState extends State<StoryPreviewScreen> {
  final PageController _pageController = PageController();
  final FlutterTts _tts = FlutterTts();
  final StoryRepository _repository = StoryRepository();
  int _pageIndex = 0;
  bool _speaking = false;
  bool _isSubmitting = false;

  SceneModel get _scene => widget.scenes[_pageIndex];

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleTts() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    await _tts.setLanguage(_languageCode(widget.story.language));
    await _tts.setSpeechRate(0.42);
    await _tts.speak(_scene.narration);
    if (mounted) setState(() => _speaking = true);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      await _repository.submitForReview(story: widget.story, scenes: widget.scenes);
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFF12062E), Color(0xFF37106B), Color(0xFF101B5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: <Widget>[
                    _GlassCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.story.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          const Text(
                            'Preview before submit',
                            style: TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PagePill(label: '${_pageIndex + 1}/${widget.scenes.length}'),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.scenes.length,
                  onPageChanged: (int index) async {
                    await _tts.stop();
                    if (!mounted) return;
                    setState(() {
                      _pageIndex = index;
                      _speaking = false;
                    });
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final SceneModel scene = widget.scenes[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  Image.network(
                                    scene.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.white.withOpacity(0.08),
                                      child: const Center(
                                        child: Icon(Icons.broken_image_rounded, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: <Color>[Color(0x00000000), Color(0xC0000000)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.40),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.16)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Text(
                                            scene.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            scene.caption,
                                            style: const TextStyle(
                                              color: Color(0xFFFFF0FF),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            scene.narration,
                                            style: const TextStyle(
                                              color: Color(0xFFE9D5FF),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (_pageIndex <= 0) return;
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  label: const Text('Previous'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(50),
                                    side: BorderSide(color: Colors.white.withOpacity(0.22)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _toggleTts,
                                  icon: Icon(_speaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                                  label: Text(_speaking ? 'Stop TTS' : 'Play TTS'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(50),
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF5B21B6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (_pageIndex >= widget.scenes.length - 1) return;
                                    _pageController.nextPage(
                                      duration: const Duration(milliseconds: 250),
                                      curve: Curves.easeOut,
                                    );
                                  },
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  label: const Text('Next'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(50),
                                    side: BorderSide(color: Colors.white.withOpacity(0.22)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (widget.allowSubmit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: const Icon(Icons.publish_rounded),
                      label: Text(_isSubmitting ? 'Submitting...' : 'Submit for Review'),
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
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.10),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _PagePill extends StatelessWidget {
  const _PagePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
