import 'package:flutter/material.dart';

import '../data/story_moderation_service.dart';
import '../domain/scene_model.dart';
import '../domain/story_model.dart';
import 'scene_editor_screen.dart';

class StoryMetaScreen extends StatefulWidget {
  const StoryMetaScreen({
    super.key,
    this.initialStory,
  });

  final StoryModel? initialStory;

  @override
  State<StoryMetaScreen> createState() => _StoryMetaScreenState();
}

class _StoryMetaScreenState extends State<StoryMetaScreen> {
  final StoryModerationService _moderationService = const StoryModerationService();

  late final TextEditingController _titleController;
  late StoryModel _draft;
  ModerationResult _titleModeration = const ModerationResult(
    isAllowed: true,
    status: 'draft',
  );
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initialStory ?? StoryModel.empty();
    _titleController = TextEditingController(text: _draft.title);
    _runTitleModeration(_draft.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _runTitleModeration(String value) async {
    final ModerationResult result = await _moderationService.moderateStoryTitle(value);
    if (!mounted) return;
    setState(() {
      _titleModeration = result;
    });
  }

  void _continueToScenes() {
    FocusScope.of(context).unfocus();
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      _showSnack('Please enter a story title.');
      return;
    }
    if (_titleModeration.shouldBlockSubmit) {
      _showSnack(_titleModeration.reason);
      return;
    }

    setState(() => _isBusy = true);

    final StoryModel story = _draft.copyWith(
      title: title,
      status: 'draft',
      isModerated: _titleModeration.status == 'ready',
    );

    final List<SceneModel> scenes = List<SceneModel>.generate(
      story.totalScenes,
          (int index) => SceneModel.empty(
        storyId: story.id,
        order: index,
      ),
    );

    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => SceneEditorScreen(
          initialStory: story,
          initialScenes: scenes,
        ),
      ),
    )
        .whenComplete(() {
      if (mounted) setState(() => _isBusy = false);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF12062E),
              Color(0xFF37106B),
              Color(0xFF101B5F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              const Positioned.fill(child: _StoryGlowBackground()),
              CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _GlassIconButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              const _TopPill(label: 'Story Setup'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const _NeonSectionHeading(text: 'Create Story'),
                          const SizedBox(height: 8),
                          const Text(
                            'Set the story basics first. Then build each scene one by one.',
                            style: TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    const Expanded(child: _FieldLabel('Story Title')),
                                    _ModerationPill(result: _titleModeration),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _GlassTextField(
                                  controller: _titleController,
                                  hintText: 'Enter a fun story title',
                                  maxLines: 1,
                                  onChanged: (String value) {
                                    _draft = _draft.copyWith(title: value);
                                    _runTitleModeration(value);
                                  },
                                ),
                                if (_titleModeration.reason.trim().isNotEmpty) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Text(
                                    _titleModeration.reason,
                                    style: TextStyle(
                                      color: _titleModeration.shouldBlockSubmit
                                          ? const Color(0xFFFFB4D8)
                                          : const Color(0xFFE9D5FF),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                const _FieldLabel('Theme'),
                                const SizedBox(height: 8),
                                _GlassDropdown<String>(
                                  value: _draft.theme,
                                  items: StoryModel.predefinedThemes,
                                  onChanged: (String? value) {
                                    if (value == null) return;
                                    setState(() => _draft = _draft.copyWith(theme: value));
                                  },
                                ),
                                const SizedBox(height: 16),
                                const _FieldLabel('Language'),
                                const SizedBox(height: 8),
                                _GlassDropdown<String>(
                                  value: _draft.language,
                                  items: StoryModel.predefinedLanguages,
                                  onChanged: (String? value) {
                                    if (value == null) return;
                                    setState(() => _draft = _draft.copyWith(language: value));
                                  },
                                ),
                                const SizedBox(height: 16),
                                const _FieldLabel('Total Scenes'),
                                const SizedBox(height: 12),
                                Row(
                                  children: <Widget>[
                                    _CounterButton(
                                      icon: Icons.remove,
                                      onTap: _draft.totalScenes > 1
                                          ? () => setState(() {
                                        _draft = _draft.copyWith(
                                          totalScenes: _draft.totalScenes - 1,
                                        );
                                      })
                                          : null,
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              '${_draft.totalScenes}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 28,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Maximum 15 scenes',
                                              style: TextStyle(
                                                color: Color(0xFFE9D5FF),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    _CounterButton(
                                      icon: Icons.add,
                                      onTap: _draft.totalScenes < StoryModel.maxScenes
                                          ? () => setState(() {
                                        _draft = _draft.copyWith(
                                          totalScenes: _draft.totalScenes + 1,
                                        );
                                      })
                                          : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const _MiniInfoCard(
                            icon: Icons.auto_awesome_rounded,
                            title: 'Auto review enabled',
                            subtitle:
                            'Story title is auto-checked. Scene titles, narration, and images are auto-reviewed inside the scene editor.',
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isBusy ? null : _continueToScenes,
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text('Continue to Scenes'),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModerationPill extends StatelessWidget {
  const _ModerationPill({required this.result});

  final ModerationResult result;

  @override
  Widget build(BuildContext context) {
    final bool isFlagged = result.status == 'flagged';
    final bool isReady = result.status == 'ready';
    final Color background = isFlagged
        ? const Color(0x33FF4FD8)
        : isReady
        ? const Color(0x3322C55E)
        : Colors.white.withOpacity(0.10);
    final Color textColor = isFlagged
        ? const Color(0xFFFFC6E9)
        : isReady
        ? const Color(0xFFBBF7D0)
        : Colors.white;
    final String label = isFlagged
        ? 'Flagged'
        : isReady
        ? 'Ready'
        : 'Draft';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StoryGlowBackground extends StatelessWidget {
  const _StoryGlowBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: <Color>[Color(0x22FF7AF6), Color(0x00000000)],
            center: Alignment(-0.8, -0.9),
            radius: 0.9,
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

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

class _TopPill extends StatelessWidget {
  const _TopPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
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

class _NeonSectionHeading extends StatelessWidget {
  const _NeonSectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 0.4,
        shadows: <Shadow>[
          Shadow(
            color: Color(0xFFFF86FF),
            blurRadius: 10,
          ),
          Shadow(
            color: Color(0xFFFF86FF),
            blurRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hintText,
    required this.maxLines,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFFCDB8FF)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF86FF), width: 1.2),
        ),
      ),
    );
  }
}

class _GlassDropdown<T> extends StatelessWidget {
  const _GlassDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF31115E),
      iconEnabledColor: Colors.white,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF86FF), width: 1.2),
        ),
      ),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      items: items
          .map((T item) => DropdownMenuItem<T>(
        value: item,
        child: Text(item.toString()),
      ))
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(onTap == null ? 0.04 : 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
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
      ),
    );
  }
}
