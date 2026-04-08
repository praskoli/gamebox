import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/memory_diy_catalog.dart';
import '../data/memory_diy_repository.dart';
import '../../../games/memory_match/domain/memory_diy_game_config.dart';
import '../../../games/memory_match/presentation/memory_game_screen.dart';

class MemoryDiyBuilderScreen extends StatefulWidget {
  const MemoryDiyBuilderScreen({
    super.key,
    this.initialConfig,
    this.isReviewMode = false,
  });

  final MemoryDiyGameConfig? initialConfig;
  final bool isReviewMode;

  @override
  State<MemoryDiyBuilderScreen> createState() => _MemoryDiyBuilderScreenState();
}

class _MemoryDiyBuilderScreenState extends State<MemoryDiyBuilderScreen> {
  static const int _totalSteps = 8;

  static const List<_GridPreset> _gridPresets = <_GridPreset>[
    _GridPreset(columns: 4, rows: 4, label: '4 x 4', subtitle: 'Easy start'),
    _GridPreset(
      columns: 5,
      rows: 4,
      label: '5 x 4',
      subtitle: 'Balanced challenge',
    ),
    _GridPreset(
      columns: 6,
      rows: 4,
      label: '6 x 4',
      subtitle: 'Big challenge',
    ),
  ];

  static const List<_SpeedPreset> _previewPresets = <_SpeedPreset>[
    _SpeedPreset(
      value: 1800,
      label: 'Easy Preview',
      subtitle: 'More time to memorize',
    ),
    _SpeedPreset(
      value: 1200,
      label: 'Balanced',
      subtitle: 'Good for most kids',
    ),
    _SpeedPreset(
      value: 800,
      label: 'Quick',
      subtitle: 'Fast and exciting',
    ),
    _SpeedPreset(
      value: 0,
      label: 'No Preview',
      subtitle: 'Pro mode',
    ),
  ];

  static const List<_SpeedPreset> _flipBackPresets = <_SpeedPreset>[
    _SpeedPreset(
      value: 900,
      label: 'Slow Flip Back',
      subtitle: 'More forgiving',
    ),
    _SpeedPreset(
      value: 650,
      label: 'Balanced',
      subtitle: 'Standard pace',
    ),
    _SpeedPreset(
      value: 450,
      label: 'Fast',
      subtitle: 'Sharp memory challenge',
    ),
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _creatorNameController;

  late String _selectedCategoryId;
  late int _gridColumns;
  late int _gridRows;
  late int _previewDurationMs;
  late int _flipBackDelayMs;
  late List<String> _selectedItems;

  String _draftId = '';
  String _ownerUid = '';

  int _currentStep = 0;
  bool _isSaving = false;
  bool _isSubmitting = false;

  bool get _isReadOnly => widget.isReviewMode;

  @override
  void initState() {
    super.initState();

    final MemoryDiyGameConfig? initial = widget.initialConfig;
    final MemoryDiyCategory firstCategory = MemoryDiyCatalog.categories.first;

    _selectedCategoryId = initial?.categoryId ?? firstCategory.id;
    _gridColumns = initial?.gridColumns ?? 4;
    _gridRows = initial?.gridRows ?? 4;
    _previewDurationMs = initial?.previewDurationMs ?? 1200;
    _flipBackDelayMs = initial?.flipBackDelayMs ?? 650;
    _selectedItems = List<String>.from(initial?.items ?? const <String>[]);
    _draftId = initial?.id ?? '';
    _ownerUid = initial?.ownerUid ?? '';

    _titleController = TextEditingController(
      text: initial?.title ?? '',
    );

    _creatorNameController = TextEditingController(
      text: initial?.creatorName ?? _defaultCreatorName(),
    );

    _reconcileSelectedItemsForCategory();
    _reconcileSelectedItemsForPairCount();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _creatorNameController.dispose();
    super.dispose();
  }

  MemoryDiyCategory get _selectedCategory =>
      MemoryDiyCatalog.byId(_selectedCategoryId);

  List<String> get _availableItems => List<String>.from(_selectedCategory.items);

  int get _pairCount => (_gridColumns * _gridRows) ~/ 2;

  int get _stepNumber => _currentStep + 1;

  bool get _isTitleValid => _titleController.text.trim().length >= 3;

  bool get _isCreatorNameValid => _creatorNameController.text.trim().length >= 2;

  bool get _isCategoryValid => _selectedCategoryId.trim().isNotEmpty;

  bool get _isCardSelectionValid => _selectedItems.length == _pairCount;

  bool get _canPlay =>
      _isTitleValid &&
          _isCreatorNameValid &&
          _isCategoryValid &&
          _isCardSelectionValid;

  double get _progressValue => (_stepNumber / _totalSteps).clamp(0, 1);

  String get _projectTitlePreview {
    final String value = _titleController.text.trim();
    return value.isEmpty ? 'My Memory Project' : value;
  }

  String get _creatorNamePreview {
    final String value = _creatorNameController.text.trim();
    return value.isEmpty ? _defaultCreatorName() : value;
  }

  String? get _playDisabledReason {
    if (!_isTitleValid) {
      return 'Add a project title with at least 3 characters.';
    }
    if (!_isCreatorNameValid) {
      return 'Add a creator display name with at least 2 characters.';
    }
    if (!_isCategoryValid) {
      return 'Choose a theme for your project.';
    }
    if (_selectedItems.length < _pairCount) {
      final int remaining = _pairCount - _selectedItems.length;
      return 'Select $remaining more card${remaining == 1 ? '' : 's'} for this board size.';
    }
    if (_selectedItems.length > _pairCount) {
      return 'Too many cards selected. Reduce to exactly $_pairCount cards.';
    }
    return null;
  }

  String _defaultCreatorName() {
    final User? user = FirebaseAuth.instance.currentUser;

    final String displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final String email = user?.email?.trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      final String prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) {
        return prefix
            .split(RegExp(r'[._\-]'))
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e[0].toUpperCase() + e.substring(1))
            .join(' ');
      }
    }

    return 'Arena Builder';
  }

  MemoryDiyGameConfig _buildConfig({
    required String ownerUid,
    String id = '',
  }) {
    return MemoryDiyGameConfig(
      id: id,
      title: _titleController.text.trim().isEmpty
          ? 'My Memory Project'
          : _titleController.text.trim(),
      creatorName: _creatorNameController.text.trim().isEmpty
          ? _defaultCreatorName()
          : _creatorNameController.text.trim(),
      categoryId: _selectedCategory.id,
      baseWorldId: _selectedCategory.baseWorldId,
      gridColumns: _gridColumns,
      gridRows: _gridRows,
      previewDurationMs: _previewDurationMs,
      flipBackDelayMs: _flipBackDelayMs,
      items: List<String>.from(_selectedItems),
      levelNumber: 1,
      ownerUid: ownerUid,
      createdAt: widget.initialConfig?.createdAt,
      updatedAt: widget.initialConfig?.updatedAt,
      isMixedCategory: _selectedCategory.isMixed,
      status: widget.initialConfig?.status ?? 'draft',
      submittedAt: widget.initialConfig?.submittedAt,
      reviewedAt: widget.initialConfig?.reviewedAt,
      reviewedBy: widget.initialConfig?.reviewedBy ?? '',
      rejectionReason: widget.initialConfig?.rejectionReason ?? '',
    );
  }

  void _reconcileSelectedItemsForCategory() {
    final Set<String> allowed = _availableItems.toSet();
    _selectedItems =
        _selectedItems.where((String item) => allowed.contains(item)).toList();
  }

  void _reconcileSelectedItemsForPairCount() {
    if (_selectedItems.length > _pairCount) {
      _selectedItems = _selectedItems.take(_pairCount).toList();
    }
  }

  void _changeCategory(MemoryDiyCategory category) {
    if (_isReadOnly) return;

    setState(() {
      _selectedCategoryId = category.id;
      _selectedItems = <String>[];
    });
  }

  void _changeGrid(_GridPreset preset) {
    if (_isReadOnly) return;

    setState(() {
      _gridColumns = preset.columns;
      _gridRows = preset.rows;
      _reconcileSelectedItemsForPairCount();
    });

    if (_selectedItems.isNotEmpty && _selectedItems.length != _pairCount) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Board size changed. Now choose exactly $_pairCount cards for the new board.',
            ),
          ),
        );
    }
  }

  void _toggleItem(String item) {
    if (_isReadOnly) return;

    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
        return;
      }

      if (_selectedItems.length >= _pairCount) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'You can choose exactly $_pairCount cards for this board.',
              ),
            ),
          );
        return;
      }

      _selectedItems.add(item);
    });
  }

  void _autoFillSelection() {
    if (_isReadOnly) return;

    final List<String> items = _availableItems.take(_pairCount).toList();
    setState(() {
      _selectedItems = items;
    });
  }

  void _clearSelection() {
    if (_isReadOnly) return;

    setState(() {
      _selectedItems = <String>[];
    });
  }

  bool _validateCurrentStep({bool showMessage = true}) {
    String? message;

    switch (_currentStep) {
      case 0:
        if (!_isTitleValid) {
          message = 'Give your project a title with at least 3 characters.';
        } else if (!_isCreatorNameValid) {
          message = 'Add a creator display name with at least 2 characters.';
        }
        break;
      case 1:
        if (!_isCategoryValid) {
          message = 'Choose one category to continue.';
        }
        break;
      case 2:
        break;
      case 3:
        if (!_isCardSelectionValid) {
          message =
          'Choose exactly $_pairCount cards to match this board size.';
        }
        break;
      case 4:
        break;
      case 5:
        break;
      case 6:
        break;
      case 7:
        if (!_canPlay) {
          message =
              _playDisabledReason ?? 'Finish your project setup before submitting.';
        }
        break;
    }

    if (message != null && showMessage) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    return message == null;
  }

  void _goNext() {
    if (!_validateCurrentStep()) return;
    if (_currentStep >= _totalSteps - 1) return;

    setState(() {
      _currentStep += 1;
    });
  }

  void _goBack() {
    if (_currentStep <= 0) return;

    setState(() {
      _currentStep -= 1;
    });
  }

  Future<void> _playGame() async {
    if (!_canPlay) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_playDisabledReason ?? 'Project is not ready yet.'),
          ),
        );
      return;
    }

    final MemoryDiyGameConfig config = _buildConfig(
      ownerUid: _ownerUid,
      id: _draftId,
    );

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemoryGameScreen(
          diyConfig: config,
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (widget.isReviewMode) return;
    if (_isSaving) return;

    if (!_isTitleValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please give your project a title before saving.'),
          ),
        );
      return;
    }

    if (!_isCreatorNameValid) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please add your creator display name before saving.'),
          ),
        );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final MemoryDiyGameConfig config = _buildConfig(
        ownerUid: _ownerUid,
        id: _draftId,
      );

      final String savedId =
      await MemoryDiyRepository.instance.saveDraft(config);

      if (!mounted) return;

      setState(() {
        _draftId = savedId;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isCardSelectionValid
                  ? 'Project saved. You can keep editing or submit now.'
                  : 'Draft saved. To submit, select exactly $_pairCount cards for this board.',
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not save draft: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitProject() async {
    if (widget.isReviewMode) return;
    if (_isSubmitting) return;

    if (!_canPlay) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_playDisabledReason ?? 'Project is not ready yet.'),
          ),
        );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final MemoryDiyGameConfig config = _buildConfig(
        ownerUid: _ownerUid,
        id: _draftId,
      );
      final bool canSubmit =
      await MemoryDiyRepository.instance.canSubmitMoreGames();

      if (!canSubmit) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Free limit reached (2 submissions).'),
            ),
          );

        setState(() => _isSubmitting = false);
        return;
      }

      await MemoryDiyRepository.instance.submitForReview(config);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Project submitted for review successfully.'),
          ),
        );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Could not submit project: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> previewItems =
    _selectedItems.take(12).toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        widget.isReviewMode ? const Color(0xFF18122B) : Colors.white,
        foregroundColor:
        widget.isReviewMode ? Colors.white : const Color(0xFF111827),
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(
              widget.isReviewMode
                  ? Icons.admin_panel_settings_rounded
                  : Icons.auto_awesome_rounded,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.isReviewMode ? 'Admin Review' : 'DIY Studio',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        actions: [
           if (!widget.isReviewMode) ...[
            TextButton.icon(
              onPressed: _isSaving ? null : _saveDraft,
              icon: _isSaving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Save Draft'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _BuilderHeader(
              title: _projectTitlePreview,
              headingText: 'DIY Game Studio',
              stepNumber: _stepNumber,
              totalSteps: _totalSteps,
              progressValue: _progressValue,
              stepLabel: _stepLabelFor(_currentStep),
              isReviewMode: widget.isReviewMode,
            ),
            if (widget.isReviewMode)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5F3FF), Color(0xFFEEF2FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8B4FE)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      color: Color(0xFF7C3AED),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Review Mode is active. You can inspect every step and play the project, but editing, saving, and submission are disabled.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: Color(0xFF4C1D95),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentStep),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (_currentStep == 0) _buildStepProjectInfo(),
                      if (_currentStep == 1) _buildStepCategory(),
                      if (_currentStep == 2) _buildStepBoardSize(),
                      if (_currentStep == 3) _buildStepChooseCards(),
                      if (_currentStep == 4) _buildStepPreviewSpeed(),
                      if (_currentStep == 5) _buildStepFlipBackSpeed(),
                      if (_currentStep == 6)
                        _buildStepPreview(previewItems: previewItems),
                      if (_currentStep == 7)
                        _buildStepYourProject(previewItems: previewItems),
                    ],
                  ),
                ),
              ),
            ),
            _BottomActionBar(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              onBack: _currentStep == 0 ? null : _goBack,
              onNext: _currentStep < _totalSteps - 1 ? _goNext : null,
              onPlay: _playGame,
              onSubmit: widget.isReviewMode ? null : _submitProject,
              playEnabled: _canPlay,
              submitEnabled:
              widget.isReviewMode ? false : (_canPlay && !_isSubmitting),
              disabledReason:
              _currentStep == _totalSteps - 1 ? _playDisabledReason : null,
              isSubmitting: _isSubmitting,
              isReviewMode: widget.isReviewMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProjectInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '🛠️',
          title: 'Name Your Project',
          subtitle: widget.isReviewMode
              ? 'Project identity is visible here for review. Editing is disabled in review mode.'
              : 'Give your memory game a fun name and choose how your creator name should appear in the community.',
        ),
        const SizedBox(height: 16),
        _StudioCard(
          dimmed: _isReadOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Project Title'),
              const SizedBox(height: 10),
              TextField(
                controller: _titleController,
                readOnly: _isReadOnly,
                enabled: !_isReadOnly,
                textCapitalization: TextCapitalization.words,
                onChanged: _isReadOnly ? null : (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Aarav\'s Ocean Quest',
                  filled: true,
                  fillColor:
                  _isReadOnly ? const Color(0xFFF3F4F6) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFF5B67F1),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const _SectionTitle('Creator Display Name'),
              const SizedBox(height: 10),
              TextField(
                controller: _creatorNameController,
                readOnly: _isReadOnly,
                enabled: !_isReadOnly,
                textCapitalization: TextCapitalization.words,
                onChanged: _isReadOnly ? null : (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Prasanth Plays',
                  helperText: widget.isReviewMode
                      ? 'Shown exactly as this project will appear in community and creator listings.'
                      : 'This name will be shown in Community, Leaderboard, and My Projects.',
                  filled: true,
                  fillColor:
                  _isReadOnly ? const Color(0xFFF3F4F6) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFF5B67F1),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _StatusInfoRow(
                icon: (_isTitleValid && _isCreatorNameValid)
                    ? Icons.check_circle_rounded
                    : Icons.edit_rounded,
                iconColor: (_isTitleValid && _isCreatorNameValid)
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF5B67F1),
                text: (_isTitleValid && _isCreatorNameValid)
                    ? 'Great! Your project and creator identity are ready.'
                    : (!_isTitleValid
                    ? 'Use at least 3 characters for the project title.'
                    : 'Use at least 2 characters for creator display name.'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '🎨',
          title: 'Choose a Theme',
          subtitle: widget.isReviewMode
              ? 'Theme selection is shown for inspection. Category switching is disabled in review mode.'
              : 'Pick the world for your project. This decides the style and item pool for your game.',
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: MemoryDiyCatalog.categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            final MemoryDiyCategory category = MemoryDiyCatalog.categories[index];
            final bool selected = category.id == _selectedCategoryId;

            return _CategoryTile(
              title: category.title,
              subtitle: category.subtitle,
              selected: selected,
              isMixed: category.isMixed,
              enabled: !_isReadOnly,
              onTap: () => _changeCategory(category),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepBoardSize() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '🧱',
          title: 'Choose Board Size',
          subtitle: widget.isReviewMode
              ? 'Board configuration is visible for review. Size changes are disabled.'
              : 'Your board size decides how many unique cards you must choose in the next step.',
        ),
        const SizedBox(height: 16),
        _StudioCard(
          dimmed: _isReadOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Board Size'),
              const SizedBox(height: 12),
              ..._gridPresets.map((preset) {
                final bool selected =
                    preset.columns == _gridColumns && preset.rows == _gridRows;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectionTile(
                    title: preset.label,
                    subtitle:
                    '${preset.subtitle} • ${preset.columns * preset.rows} cards • ${(preset.columns * preset.rows) ~/ 2} pairs',
                    selected: selected,
                    enabled: !_isReadOnly,
                    onTap: () => _changeGrid(preset),
                  ),
                );
              }),
              const SizedBox(height: 8),
              _StatusInfoRow(
                icon: Icons.info_outline_rounded,
                iconColor: const Color(0xFF5B67F1),
                text:
                'For this board, you will need exactly $_pairCount unique cards in the next step.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepChooseCards() {
    final List<String> items = _availableItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '🧩',
          title: 'Choose Your Cards',
          subtitle: widget.isReviewMode
              ? 'Card choices are visible for inspection. Card interactions are disabled.'
              : 'Now that your board size is fixed, pick exactly the right number of cards for your project.',
        ),
        const SizedBox(height: 16),
        _StudioCard(
          dimmed: _isReadOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Card Selection Progress'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _pairCount == 0
                            ? 0
                            : (_selectedItems.length / _pairCount).clamp(0, 1),
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isCardSelectionValid
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF5B67F1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedItems.length}/$_pairCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _StatusInfoRow(
                icon: _isCardSelectionValid
                    ? Icons.verified_rounded
                    : Icons.touch_app_rounded,
                iconColor: _isCardSelectionValid
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF5B67F1),
                text: _isCardSelectionValid
                    ? 'Perfect. Your project has the exact number of cards needed.'
                    : 'Choose exactly $_pairCount cards for this board.',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isReadOnly ? null : _clearSelection,
                      icon: const Icon(Icons.clear_all_rounded),
                      label: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isReadOnly ? null : _autoFillSelection,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Quick Fill'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StudioCard(
          dimmed: _isReadOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedCategory.title} Card Pack',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.isReviewMode
                    ? 'Viewing selected and available cards.'
                    : 'Tap cards to include them in your project.',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final String item = items[index];
                  final bool selected = _selectedItems.contains(item);

                  return _SelectableCardItem(
                    item: item,
                    selected: selected,
                    order: selected ? _selectedItems.indexOf(item) + 1 : null,
                    enabled: !_isReadOnly,
                    onTap: () => _toggleItem(item),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepPreviewSpeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '👀',
          title: 'Choose Preview Speed',
          subtitle: widget.isReviewMode
              ? 'Preview timing is shown for review. Changes are disabled.'
              : 'Set how long the cards stay visible at the start before the game begins.',
        ),
        const SizedBox(height: 16),
        _StudioCard(
          dimmed: _isReadOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Preview Speed'),
              const SizedBox(height: 12),
              ..._previewPresets.map((preset) {
                final bool selected = preset.value == _previewDurationMs;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectionTile(
                    title: preset.label,
                    subtitle: preset.subtitle,
                    selected: selected,
                    enabled: !_isReadOnly,
                    onTap: () {
                      if (_isReadOnly) return;
                      setState(() {
                        _previewDurationMs = preset.value;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepFlipBackSpeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '⚡',
          title: 'Choose Flip Back Speed',
          subtitle: widget.isReviewMode
              ? 'Flip-back timing is shown for review. Changes are disabled.'
              : 'Set how fast wrong pairs flip back down after a mistake.',
        ),
        const SizedBox(height: 16),
        _StudioCard(
          dimmed: _isReadOnly,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Flip Back Speed'),
              const SizedBox(height: 12),
              ..._flipBackPresets.map((preset) {
                final bool selected = preset.value == _flipBackDelayMs;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SelectionTile(
                    title: preset.label,
                    subtitle: preset.subtitle,
                    selected: selected,
                    enabled: !_isReadOnly,
                    onTap: () {
                      if (_isReadOnly) return;
                      setState(() {
                        _flipBackDelayMs = preset.value;
                      });
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepPreview({
    required List<String> previewItems,
  }) {
    final String? disabledReason = _playDisabledReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '🚀',
          title: 'Preview Your Project',
          subtitle: widget.isReviewMode
              ? 'Everything below is read-only preview data for admin inspection.'
              : 'Review your project before moving to the final submission step.',
        ),
        const SizedBox(height: 16),
        _StudioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _projectTitlePreview,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'By $_creatorNamePreview',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5B67F1),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(label: _selectedCategory.title),
                  _InfoPill(label: '${_gridColumns} x $_gridRows'),
                  _InfoPill(label: '$_pairCount pairs'),
                  _InfoPill(
                    label: _previewDurationMs == 0
                        ? 'No Preview'
                        : '${_previewDurationMs}ms preview',
                  ),
                  _InfoPill(label: '${_flipBackDelayMs}ms flip'),
                  if (widget.isReviewMode)
                    const _InfoPill(
                      label: 'Review Mode',
                      backgroundColor: Color(0xFFF5F3FF),
                      textColor: Color(0xFF7C3AED),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _StatusInfoRow(
                icon: _canPlay
                    ? Icons.celebration_rounded
                    : Icons.info_outline_rounded,
                iconColor: _canPlay
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFF59E0B),
                text: _canPlay
                    ? 'Your project looks good and can be played now.'
                    : (disabledReason ?? 'Project is not ready yet.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StudioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Selected Card Set'),
              const SizedBox(height: 12),
              if (previewItems.isEmpty)
                const Text(
                  'No cards selected yet.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: previewItems.map((item) {
                    return Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 28),
                      ),
                    );
                  }).toList(growable: false),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepYourProject({
    required List<String> previewItems,
  }) {
    final String? disabledReason = _playDisabledReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(
          emoji: '🏁',
          title: widget.isReviewMode ? 'Review Project' : 'Your Project',
          subtitle: widget.isReviewMode
              ? 'Final review screen. Play is allowed, but save and submit are intentionally disabled.'
              : 'This is your final project screen. Submit it, save it, or go back and improve it.',
        ),
        const SizedBox(height: 16),
        _StudioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _projectTitlePreview,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Creator: $_creatorNamePreview',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5B67F1),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Theme: ${_selectedCategory.title}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Board: ${_gridColumns} x $_gridRows • Cards: ${_selectedItems.length}/$_pairCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preview: ${_previewDurationMs == 0 ? 'No Preview' : '${_previewDurationMs}ms'} • Flip Back: ${_flipBackDelayMs}ms',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 14),
              _StatusInfoRow(
                icon: _canPlay
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                iconColor: _canPlay
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFF59E0B),
                text: _canPlay
                    ? (widget.isReviewMode
                    ? 'Project is playable and ready for admin review decisions.'
                    : 'Your project is ready for submission and play.')
                    : (disabledReason ?? 'Project is not ready yet.'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _StudioCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Project Card Set'),
              const SizedBox(height: 12),
              if (previewItems.isEmpty)
                const Text(
                  'No cards selected yet.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: previewItems.map((item) {
                    return Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 28),
                      ),
                    );
                  }).toList(growable: false),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _stepLabelFor(int step) {
    switch (step) {
      case 0:
        return 'Project Name';
      case 1:
        return 'Theme';
      case 2:
        return 'Board Size';
      case 3:
        return 'Choose Cards';
      case 4:
        return 'Preview Speed';
      case 5:
        return 'Flip Back Speed';
      case 6:
        return 'Preview';
      case 7:
        return 'Your Project';
      default:
        return 'Build';
    }
  }
}

class _BuilderHeader extends StatelessWidget {
  const _BuilderHeader({
    required this.title,
    required this.headingText,
    required this.stepNumber,
    required this.totalSteps,
    required this.progressValue,
    required this.stepLabel,
    required this.isReviewMode,
  });

  final String title;
  final String headingText;
  final int stepNumber;
  final int totalSteps;
  final double progressValue;
  final String stepLabel;
  final bool isReviewMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReviewMode
              ? const [Color(0xFF1E1B4B), Color(0xFF312E81)]
              : const [Color(0xFF5B67F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isReviewMode
                ? const Color(0x221E1B4B)
                : const Color(0x225B67F1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _NeonSectionHeading(text: 'DIY Game Studio'),
              ),
              if (isReviewMode) const _ReviewModeBadge(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '🎮 $title',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step $stepNumber of $totalSteps • $stepLabel',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonSectionHeading extends StatelessWidget {
  const _NeonSectionHeading({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.4,
        shadows: [
          Shadow(
            color: Color(0xFFFF4FD8),
            blurRadius: 8,
          ),
          Shadow(
            color: Color(0xFFB026FF),
            blurRadius: 18,
          ),
          Shadow(
            color: Color(0x66FFFFFF),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }
}

class _ReviewModeBadge extends StatelessWidget {
  const _ReviewModeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4FD8), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x55FFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44FF4FD8),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_red_eye_rounded,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'Review Mode',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$emoji $title',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  const _StudioCard({
    required this.child,
    this.dimmed = false,
  });

  final Widget child;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: dimmed ? 0.82 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dimmed ? const Color(0xFFFAFAFC) : const Color(0xFFFDFDFE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: dimmed
                ? const Color(0xFFD1D5DB)
                : const Color(0xFFE5E7EB),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.isMixed,
    required this.onTap,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool isMixed;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selected
                    ? const [Color(0xFFEEF2FF), Color(0xFFF5F3FF)]
                    : const [Colors.white, Color(0xFFF9FAFB)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5B67F1)
                    : const Color(0xFFE5E7EB),
                width: selected ? 1.6 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF5B67F1)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isMixed
                              ? Icons.auto_awesome_rounded
                              : Icons.category_rounded,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF5B67F1),
                        ),
                      if (!enabled)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableCardItem extends StatelessWidget {
  const _SelectableCardItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.enabled,
    this.order,
  });

  final String item;
  final bool selected;
  final int? order;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.78,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selected
                    ? const [Color(0xFFEEF2FF), Color(0xFFF5F3FF)]
                    : const [Colors.white, Color(0xFFF9FAFB)],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5B67F1)
                    : const Color(0xFFE5E7EB),
                width: selected ? 1.8 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                if (selected && order != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFF5B67F1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$order',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                if (!enabled)
                  const Positioned(
                    left: 6,
                    bottom: 6,
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onTap : null,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEEF2FF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? const Color(0xFF5B67F1)
                    : const Color(0xFFE5E7EB),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  !enabled
                      ? Icons.lock_outline_rounded
                      : (selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded),
                  color: !enabled
                      ? const Color(0xFF9CA3AF)
                      : (selected
                      ? const Color(0xFF5B67F1)
                      : const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  const _StatusInfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    this.backgroundColor = const Color(0xFFF3F4F6),
    this.textColor = const Color(0xFF374151),
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onNext,
    required this.onPlay,
    required this.onSubmit,
    required this.playEnabled,
    required this.submitEnabled,
    required this.isSubmitting,
    required this.isReviewMode,
    this.disabledReason,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onPlay;
  final VoidCallback? onSubmit;
  final bool playEnabled;
  final bool submitEnabled;
  final String? disabledReason;
  final bool isSubmitting;
  final bool isReviewMode;

  @override
  Widget build(BuildContext context) {
    final bool isFinalStep = currentStep == totalSteps - 1;
    final bool showDisabled = isFinalStep && !playEnabled;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDisabled && disabledReason != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      disabledReason ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!isFinalStep)
            Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back'),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next Step'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (isReviewMode)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: playEnabled ? onPlay : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play Project'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: playEnabled ? onPlay : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play My Project'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: submitEnabled ? onSubmit : null,
                    icon: Icon(
                      isSubmitting
                          ? Icons.hourglass_top_rounded
                          : Icons.task_alt_rounded,
                    ),
                    label: Text(
                      isSubmitting ? 'Submitting...' : 'Submit Project',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
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
  }
}

class _GridPreset {
  const _GridPreset({
    required this.columns,
    required this.rows,
    required this.label,
    required this.subtitle,
  });

  final int columns;
  final int rows;
  final String label;
  final String subtitle;
}

class _SpeedPreset {
  const _SpeedPreset({
    required this.value,
    required this.label,
    required this.subtitle,
  });

  final int value;
  final String label;
  final String subtitle;
}