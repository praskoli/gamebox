import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/story_moderation_service.dart';
import '../data/story_repository.dart';
import '../data/story_storage_service.dart';
import '../domain/scene_model.dart';
import '../domain/story_model.dart';
import 'story_preview_screen.dart';

class SceneEditorScreen extends StatefulWidget {
  const SceneEditorScreen({
    super.key,
    required this.initialStory,
    required this.initialScenes,
  });

  final StoryModel initialStory;
  final List<SceneModel> initialScenes;

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  final StoryRepository _repository = StoryRepository();
  final StoryStorageService _storageService = StoryStorageService();
  final StoryModerationService _moderationService = const StoryModerationService();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _narrationController;
  late StoryModel _story;
  late List<SceneModel> _scenes;
  late List<ModerationResult> _titleChecks;
  late List<ModerationResult> _narrationChecks;
  late List<ModerationResult> _imageChecks;

  int _selectedIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _story = widget.initialStory;
    _scenes = List<SceneModel>.from(widget.initialScenes);
    _titleChecks = List<ModerationResult>.filled(
      _scenes.length,
      const ModerationResult(isAllowed: true, status: 'draft'),
    );
    _narrationChecks = List<ModerationResult>.filled(
      _scenes.length,
      const ModerationResult(isAllowed: true, status: 'draft'),
    );
    _imageChecks = _scenes
        .map((SceneModel scene) => scene.status == 'flagged'
        ? ModerationResult(
      isAllowed: true,
      status: 'flagged',
      reason: scene.flagReason,
    )
        : ModerationResult(
      isAllowed: scene.imageUrl.trim().isNotEmpty,
      status: scene.imageUrl.trim().isNotEmpty ? 'ready' : 'draft',
    ))
        .toList(growable: false);

    _titleController = TextEditingController(text: _currentScene.title);
    _narrationController = TextEditingController(text: _currentScene.narration);
    _primeCurrentSceneChecks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  SceneModel get _currentScene => _scenes[_selectedIndex];
  ModerationResult get _currentTitleCheck => _titleChecks[_selectedIndex];
  ModerationResult get _currentNarrationCheck => _narrationChecks[_selectedIndex];
  ModerationResult get _currentImageCheck => _imageChecks[_selectedIndex];

  Future<void> _primeCurrentSceneChecks() async {
    await _runTitleModeration(_selectedIndex, _currentScene.title);
    await _runNarrationModeration(_selectedIndex, _currentScene.narration);
  }

  void _selectScene(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedIndex = index;
      _titleController.text = _scenes[index].title;
      _narrationController.text = _scenes[index].narration;
    });
    _primeCurrentSceneChecks();
  }

  void _updateSceneAt(int index, SceneModel updated) {
    setState(() {
      _scenes[index] = updated;
    });
  }

  Future<void> _runTitleModeration(int index, String value) async {
    final ModerationResult result = await _moderationService.moderateSceneTitle(value);
    if (!mounted) return;
    setState(() {
      _titleChecks[index] = result;
      _syncSceneStatus(index);
    });
  }

  Future<void> _runNarrationModeration(int index, String value) async {
    final ModerationResult result = await _moderationService.moderateNarration(value);
    if (!mounted) return;
    setState(() {
      _narrationChecks[index] = result;
      _syncSceneStatus(index);
    });
  }

  void _syncSceneStatus(int index) {
    final SceneModel scene = _scenes[index];
    final ModerationResult titleCheck = _titleChecks[index];
    final ModerationResult narrationCheck = _narrationChecks[index];
    final ModerationResult imageCheck = _imageChecks[index];

    final List<String> reasons = <String>[
      if (titleCheck.reason.trim().isNotEmpty) titleCheck.reason.trim(),
      if (narrationCheck.reason.trim().isNotEmpty) narrationCheck.reason.trim(),
      if (imageCheck.reason.trim().isNotEmpty) imageCheck.reason.trim(),
    ];

    final String status;
    if (scene.title.trim().isEmpty ||
        scene.narration.trim().isEmpty ||
        scene.imageUrl.trim().isEmpty) {
      status = 'draft';
    } else if (titleCheck.isFlagged || narrationCheck.isFlagged || imageCheck.isFlagged) {
      status = 'flagged';
    } else {
      status = 'ready';
    }

    _scenes[index] = scene.copyWith(
      status: status,
      isModerated: titleCheck.status != 'draft' &&
          narrationCheck.status != 'draft' &&
          imageCheck.status != 'validating',
      flagReason: reasons.join(' • '),
      caption: SceneModel.generateCaption(scene.narration),
      durationSeconds: SceneModel.calculateDurationSeconds(scene.narration),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null) return;

    final File file = File(picked.path);
    setState(() {
      _imageChecks[_selectedIndex] = const ModerationResult(
        isAllowed: true,
        status: 'validating',
      );
      _syncSceneStatus(_selectedIndex);
    });

    final ModerationResult imageCheck = await _moderationService.moderateImage(file);
    if (!mounted) return;

    if (!imageCheck.isAllowed && imageCheck.shouldBlockSubmit) {
      setState(() {
        _imageChecks[_selectedIndex] = imageCheck;
        _syncSceneStatus(_selectedIndex);
      });
      _showSnack(imageCheck.reason);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final String storyId = _story.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : _story.id;
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        throw StateError('User must be logged in to upload images.');
      }

      final StoryImageUploadResult upload = await _storageService.uploadSceneImage(
        uid: uid,
        storyId: storyId,
        sceneId: _currentScene.id,
        file: file,
      );

      _story = _story.copyWith(id: storyId);
      _imageChecks[_selectedIndex] = imageCheck;
      _updateSceneAt(
        _selectedIndex,
        _currentScene.copyWith(
          storyId: storyId,
          imagePath: upload.path,
          imageUrl: upload.url,
          isModerated: true,
        ),
      );
      setState(() {
        _syncSceneStatus(_selectedIndex);
      });
      _showSnack(
        imageCheck.isFlagged
            ? 'Image uploaded and auto-flagged for review.'
            : 'Scene image uploaded.',
      );
    } catch (e) {
      _showSnack('Image upload failed: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    if (!_validateDraft(showMessage: true)) return;

    setState(() => _isSaving = true);
    try {
      await _repository.saveDraft(story: _story, scenes: _normalizedScenes);
      _showSnack('Story draft saved.');
    } catch (e) {
      _showSnack('Could not save draft: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _previewStory() async {
    if (!_validateDraft(showMessage: true)) return;

    setState(() => _isSaving = true);
    try {
      final StoryModel previewStory = _story.copyWith(status: 'preview_ready');
      await _repository.savePreviewReady(story: previewStory, scenes: _normalizedScenes);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StoryPreviewScreen(
            story: previewStory,
            scenes: _normalizedScenes,
            allowSubmit: true,
          ),
        ),
      );
    } catch (e) {
      _showSnack('Preview could not open: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitForReview() async {
    if (!_validateDraft(showMessage: true)) return;

    setState(() => _isSaving = true);
    try {
      await _repository.submitForReview(story: _story, scenes: _normalizedScenes);
      if (!mounted) return;
      _showSnack('Story submitted for review.');
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    } catch (e) {
      _showSnack('Submit failed: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _validateDraft({required bool showMessage}) {
    for (int i = 0; i < _scenes.length; i++) {
      final SceneModel scene = _normalizedScenes[i];
      if (scene.title.trim().isEmpty) {
        if (showMessage) _showSnack('Scene ${i + 1} title is missing.');
        return false;
      }
      if (scene.narration.trim().isEmpty) {
        if (showMessage) _showSnack('Scene ${i + 1} narration is missing.');
        return false;
      }
      if (SceneModel.countWords(scene.narration) > SceneModel.maxNarrationWords) {
        if (showMessage) {
          _showSnack('Scene ${i + 1} narration is more than 100 words.');
        }
        return false;
      }
      if (scene.imageUrl.trim().isEmpty) {
        if (showMessage) _showSnack('Scene ${i + 1} image is missing.');
        return false;
      }
    }
    return true;
  }

  List<SceneModel> get _normalizedScenes {
    return List<SceneModel>.generate(
      _scenes.length,
          (int index) {
        final SceneModel scene = _scenes[index];
        return scene.copyWith(
          storyId: _story.id,
          order: index,
          caption: SceneModel.generateCaption(scene.narration),
          durationSeconds: SceneModel.calculateDurationSeconds(scene.narration),
        );
      },
    );
  }

  int get _flaggedCount =>
      _normalizedScenes.where((SceneModel scene) => scene.status == 'flagged').length;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final SceneModel scene = _currentScene;

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
                          const Text(
                            'Story Scenes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            _story.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFE9D5FF),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _MiniStatusPill(label: '${_selectedIndex + 1}/${_scenes.length}'),
                  ],
                ),
              ),
              if (_flaggedCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x26FF4FD8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Text(
                      'Auto review flagged $_flaggedCount scene(s). You can still preview and submit. Admin will review flagged scenes before publishing.',
                      style: const TextStyle(
                        color: Color(0xFFFFD4EE),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: 58,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    final bool selected = index == _selectedIndex;
                    final SceneModel item = _scenes[index];
                    final bool flagged = item.status == 'flagged';
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _selectScene(index),
                      child: Ink(
                        width: 104,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.18)
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: flagged
                                ? const Color(0xFFFF86FF)
                                : selected
                                ? const Color(0xFFFF86FF)
                                : Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Scene ${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                flagged
                                    ? 'Flagged'
                                    : item.status == 'ready'
                                    ? 'Ready'
                                    : 'Draft',
                                style: TextStyle(
                                  color: flagged
                                      ? const Color(0xFFFFC6E9)
                                      : const Color(0xFFE9D5FF),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: _scenes.length,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    children: <Widget>[
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Text(
                                    'Scene Image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                _ModerationBadge(result: _currentImageCheck),
                                const SizedBox(width: 10),
                                TextButton.icon(
                                  onPressed: _isSaving ? null : _pickImage,
                                  icon: const Icon(Icons.image_rounded),
                                  label: const Text('Upload'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                height: 190,
                                width: double.infinity,
                                color: Colors.white.withOpacity(0.06),
                                child: scene.imageUrl.trim().isEmpty
                                    ? const Center(
                                  child: Text(
                                    'No scene image yet',
                                    style: TextStyle(
                                      color: Color(0xFFE9D5FF),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                                    : Image.network(
                                  scene.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (_currentImageCheck.reason.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                _currentImageCheck.reason,
                                style: const TextStyle(
                                  color: Color(0xFFFFD4EE),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Expanded(child: _FieldLabel('Scene Title')),
                                _ModerationBadge(result: _currentTitleCheck),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _GlassTextField(
                              controller: _titleController,
                              hintText: 'Enter scene title',
                              maxLines: 1,
                              onChanged: (String value) {
                                _updateSceneAt(_selectedIndex, _currentScene.copyWith(title: value));
                                _runTitleModeration(_selectedIndex, value);
                              },
                            ),
                            if (_currentTitleCheck.reason.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                _currentTitleCheck.reason,
                                style: const TextStyle(
                                  color: Color(0xFFFFD4EE),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                const Expanded(child: _FieldLabel('Narration')),
                                _ModerationBadge(result: _currentNarrationCheck),
                                const SizedBox(width: 10),
                                Text(
                                  '${SceneModel.countWords(scene.narration)}/100 words',
                                  style: const TextStyle(
                                    color: Color(0xFFE9D5FF),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _GlassTextField(
                              controller: _narrationController,
                              hintText: 'Write a short narration for this scene',
                              maxLines: 4,
                              onChanged: (String value) {
                                _updateSceneAt(
                                  _selectedIndex,
                                  _currentScene.copyWith(
                                    narration: value,
                                    caption: SceneModel.generateCaption(value),
                                    durationSeconds:
                                    SceneModel.calculateDurationSeconds(value),
                                  ),
                                );
                                _runNarrationModeration(_selectedIndex, value);
                              },
                            ),
                            if (_currentNarrationCheck.reason.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                _currentNarrationCheck.reason,
                                style: const TextStyle(
                                  color: Color(0xFFFFD4EE),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            const _FieldLabel('Built-in Sound Effect'),
                            const SizedBox(height: 8),
                            _SoundDropdown(
                              value: scene.soundEffect,
                              onChanged: (String? value) {
                                if (value == null) return;
                                _updateSceneAt(_selectedIndex, _currentScene.copyWith(soundEffect: value));
                              },
                            ),
                            const SizedBox(height: 16),
                            _AutoMetaCard(scene: scene),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving ? null : _saveDraft,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Save Draft'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
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
                            onPressed: _isSaving ? null : _previewStory,
                            icon: const Icon(Icons.visibility_rounded),
                            label: const Text('Preview'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5B21B6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submitForReview,
                        icon: const Icon(Icons.publish_rounded),
                        label: Text(_isSaving ? 'Working...' : 'Submit for Review'),
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});
  final Widget child;

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
      child: child,
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

class _MiniStatusPill extends StatelessWidget {
  const _MiniStatusPill({required this.label});
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

class _ModerationBadge extends StatelessWidget {
  const _ModerationBadge({required this.result});

  final ModerationResult result;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color background;
    final Color textColor;

    switch (result.status) {
      case 'flagged':
        label = 'Flagged';
        background = const Color(0x33FF4FD8);
        textColor = const Color(0xFFFFD4EE);
        break;
      case 'ready':
        label = 'Ready';
        background = const Color(0x3322C55E);
        textColor = const Color(0xFFBBF7D0);
        break;
      case 'validating':
        label = 'Checking';
        background = Colors.white.withOpacity(0.10);
        textColor = Colors.white;
        break;
      default:
        label = 'Draft';
        background = Colors.white.withOpacity(0.10);
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
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

class _SoundDropdown extends StatelessWidget {
  const _SoundDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
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
      items: SceneModel.availableSoundEffects
          .map((String effect) => DropdownMenuItem<String>(
        value: effect,
        child: Text(effect.toUpperCase()),
      ))
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _AutoMetaCard extends StatelessWidget {
  const _AutoMetaCard({required this.scene});
  final SceneModel scene;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Auto Preview Info',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _MetaLine(
            label: 'Caption',
            value: SceneModel.generateCaption(scene.narration).ifEmpty('Will appear here'),
          ),
          const SizedBox(height: 6),
          _MetaLine(
            label: 'Duration',
            value: '${SceneModel.calculateDurationSeconds(scene.narration)} sec',
          ),
          const SizedBox(height: 6),
          _MetaLine(
            label: 'Scene Status',
            value: scene.status,
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xFFE9D5FF),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
