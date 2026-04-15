import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:gamebox/games/sort_puzzle/data/sort_puzzle_repository.dart';
import '../../domain/sort_piece.dart';
import '../../domain/sort_puzzle_variant.dart';
import '../../presentation/screens/sort_puzzle_game_screen.dart';
import '../models/sort_puzzle_creator_draft.dart';

class SortPuzzleCreatorScreen extends StatefulWidget {
  const SortPuzzleCreatorScreen({
    super.key,
    required this.variant,
    this.initialDraft,
    this.isReviewMode = false,
  });

  final SortPuzzleVariant variant;
  final SortPuzzleCreatorDraft? initialDraft;
  final bool isReviewMode;

  @override
  State<SortPuzzleCreatorScreen> createState() => _SortPuzzleCreatorScreenState();
}

class _SortPuzzleCreatorScreenState extends State<SortPuzzleCreatorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _creatorNameController;

  final List<String> _allGroups = const <String>[
    'red',
    'blue',
    'green',
    'yellow',
    'purple',
    'orange',
  ];

  late Set<String> _activeGroups;
  String _selectedGroup = 'red';
  int _capacity = 4;
  late List<List<SortPiece>> _containers;

  String _draftId = '';
  int _currentStep = 0;

  bool _isSaving = false;
  bool _isSubmitting = false;
  bool _rulesDialogShown = false;

  bool get _isReadOnly => widget.isReviewMode;
  bool get _isReviewMode => widget.isReviewMode;

  @override
  void initState() {
    super.initState();

    final SortPuzzleCreatorDraft? initial = widget.initialDraft;

    _titleController = TextEditingController(
      text: initial?.title.isNotEmpty == true ? initial!.title : 'My Sort Puzzle',
    );
    _creatorNameController = TextEditingController(
      text: initial?.creatorName.isNotEmpty == true
          ? initial!.creatorName
          : _defaultCreatorName(),
    );

    _draftId = initial?.id ?? '';
    _capacity = initial?.capacity ?? 4;

    if (initial != null && initial.containers.isNotEmpty) {
      _containers = initial.containers
          .map((e) => List<SortPiece>.from(e.pieces))
          .toList(growable: true);

      final Set<String> restoredGroups = <String>{};
      for (final container in initial.containers) {
        for (final piece in container.pieces) {
          restoredGroups.add(piece.groupKey);
        }
      }
      _activeGroups = restoredGroups.isEmpty
          ? <String>{'red', 'blue', 'green', 'yellow'}
          : restoredGroups;
    } else {
      _containers = List<List<SortPiece>>.generate(6, (_) => <SortPiece>[]);
      _activeGroups = <String>{'red', 'blue', 'green', 'yellow'};
    }

    if (!_activeGroups.contains(_selectedGroup)) {
      _selectedGroup = _activeGroups.first;
    }

    if (!_isReviewMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowRulesDialog();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _creatorNameController.dispose();
    super.dispose();
  }

  String _defaultCreatorName() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;

    final email = user?.email?.trim() ?? '';
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Arena Builder';
  }

  String _variantLabel(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return 'Bird Sort';
      case SortPuzzleVariant.ball:
        return 'Ball Sort';
      case SortPuzzleVariant.color:
        return 'Color Sort';
      case SortPuzzleVariant.water:
        return 'Water Sort';
      case SortPuzzleVariant.sand:
        return 'Sand Sort';
    }
  }

  bool get _isTitleValid => _titleController.text.trim().length >= 3;
  bool get _isCreatorNameValid => _creatorNameController.text.trim().length >= 2;
  bool get _hasMinimumContainers => _containers.length >= 3;
  bool get _hasAtLeastTwoGroups => _activeGroups.length >= 2;
  bool get _hasAtLeastOneEmptyContainer =>
      _containers.any((pieces) => pieces.isEmpty);
  bool get _hasAnyPieces => _containers.any((pieces) => pieces.isNotEmpty);

  int _totalPiecesForGroup(String group) {
    int total = 0;
    for (final container in _containers) {
      for (final piece in container) {
        if (piece.groupKey == group) {
          total += piece.amount;
        }
      }
    }
    return total;
  }

  int get _mixedContainerCount {
    int count = 0;
    for (final container in _containers) {
      final groups = container.map((e) => e.groupKey).toSet();
      if (groups.length >= 2) count++;
    }
    return count;
  }

  int get _solvedContainerCount {
    int count = 0;
    for (final container in _containers) {
      if (container.isEmpty) continue;
      final int total = container.fold<int>(0, (sum, item) => sum + item.amount);
      final Set<String> groups = container.map((e) => e.groupKey).toSet();
      if (total == _capacity && groups.length == 1) {
        count++;
      }
    }
    return count;
  }

  bool get _hasTooManySolvedContainersAtStart => _solvedContainerCount > 1;

  bool get _allActiveGroupsExactlyCapacity {
    for (final group in _activeGroups) {
      if (_totalPiecesForGroup(group) != _capacity) {
        return false;
      }
    }
    return true;
  }

  bool get _hasNoInactiveGroupPieces {
    for (final container in _containers) {
      for (final piece in container) {
        if (!_activeGroups.contains(piece.groupKey)) {
          return false;
        }
      }
    }
    return true;
  }

  bool get _containerCountSupportsGroups {
    return _containers.length >= _activeGroups.length + 1;
  }

  List<String> get _groupValidationMessages {
    final List<String> messages = <String>[];

    final List<String> orderedGroups = _activeGroups.toList()..sort();
    for (final group in orderedGroups) {
      final int total = _totalPiecesForGroup(group);
      if (total < _capacity) {
        final int missing = _capacity - total;
        messages.add(
          '${_prettyGroup(group)} needs $missing more piece${missing == 1 ? '' : 's'} ($total/$_capacity).',
        );
      } else if (total > _capacity) {
        final int extra = total - _capacity;
        messages.add(
          '${_prettyGroup(group)} has $extra extra piece${extra == 1 ? '' : 's'} ($total/$_capacity).',
        );
      } else {
        messages.add('${_prettyGroup(group)} is complete ($_capacity/$_capacity).');
      }
    }

    if (!_hasAtLeastOneEmptyContainer) {
      messages.add('Keep at least one empty container so the player has room to move.');
    }

    if (_mixedContainerCount < 1) {
      messages.add('Create at least one mixed container so the puzzle starts unsolved.');
    }

    if (_hasTooManySolvedContainersAtStart) {
      messages.add('Too many containers are already solved. Mix the colors more.');
    }

    if (!_containerCountSupportsGroups) {
      messages.add('Keep at least one more container than active groups.');
    }

    return messages;
  }

  bool get _isReadyForPreview =>
      _isTitleValid &&
          _isCreatorNameValid &&
          _hasAtLeastTwoGroups &&
          _hasMinimumContainers &&
          _containerCountSupportsGroups &&
          _hasAtLeastOneEmptyContainer &&
          _hasAnyPieces &&
          _allActiveGroupsExactlyCapacity &&
          _hasNoInactiveGroupPieces &&
          _mixedContainerCount >= 1 &&
          !_hasTooManySolvedContainersAtStart;

  String? get _previewBlockReason {
    if (!_isTitleValid) {
      return 'Add a puzzle title with at least 3 characters.';
    }
    if (!_isCreatorNameValid) {
      return 'Add a creator name with at least 2 characters.';
    }
    if (!_hasAtLeastTwoGroups) {
      return 'Select at least 2 active groups.';
    }
    if (!_hasMinimumContainers) {
      return 'Use at least 3 containers.';
    }
    if (!_containerCountSupportsGroups) {
      return 'Keep at least one more container than active groups so the player has room to move.';
    }
    if (!_hasAnyPieces) {
      return 'Add pieces to the containers before previewing.';
    }
    if (!_hasAtLeastOneEmptyContainer) {
      return 'Keep at least one empty container.';
    }
    if (!_hasNoInactiveGroupPieces) {
      return 'Remove pieces that belong to inactive groups.';
    }

    for (final group in _activeGroups) {
      final int total = _totalPiecesForGroup(group);
      if (total < _capacity) {
        return '${_prettyGroup(group)} must appear exactly $_capacity times. Add ${_capacity - total} more.';
      }
      if (total > _capacity) {
        return '${_prettyGroup(group)} must appear exactly $_capacity times. Remove ${total - _capacity} extra.';
      }
    }

    if (_mixedContainerCount < 1) {
      return 'Create at least one mixed container so the puzzle starts unsolved.';
    }

    if (_hasTooManySolvedContainersAtStart) {
      return 'Too many containers are already solved at the start. Mix the colors more so the puzzle feels meaningful.';
    }

    return null;
  }

  bool _canGoNext() {
    switch (_currentStep) {
      case 0:
        return _isTitleValid && _isCreatorNameValid;
      case 1:
        return _hasAtLeastTwoGroups &&
            _hasMinimumContainers &&
            _containerCountSupportsGroups;
      case 2:
        return _isReadyForPreview;
      case 3:
        return true;
      case 4:
        return false;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep >= 4) return;
    final String? reason = _stepBlockReason();
    if (reason != null) {
      _showSnack(reason);
      return;
    }
    setState(() => _currentStep += 1);
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep -= 1);
  }

  String? _stepBlockReason() {
    switch (_currentStep) {
      case 0:
        if (!_isTitleValid) return 'Add a valid puzzle title.';
        if (!_isCreatorNameValid) return 'Add a valid creator name.';
        return null;
      case 1:
        if (!_hasAtLeastTwoGroups) return 'Select at least 2 active groups.';
        if (!_hasMinimumContainers) return 'Use at least 3 containers.';
        if (!_containerCountSupportsGroups) {
          return 'Need at least one empty container beyond the active groups.';
        }
        return null;
      case 2:
        return _previewBlockReason;
      case 3:
        return null;
      default:
        return null;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _maybeShowRulesDialog() async {
    if (_rulesDialogShown || !mounted) return;
    _rulesDialogShown = true;
    await _showRulesDialog();
  }

  Future<void> _showRulesDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'How to create a valid puzzle',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RuleLine('Choose at least 2 active colors.'),
              _RuleLine('Every selected color must appear exactly the same as capacity.'),
              _RuleLine('Keep at least 1 empty container.'),
              _RuleLine('Create at least 1 mixed container.'),
              _RuleLine('Do not leave inactive-color pieces in the board.'),
              _RuleLine('Do not start with too many solved containers.'),
              _RuleLine('Preview and submit are allowed only after all rules pass.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _toggleActiveGroup(String group) {
    if (_isReadOnly) return;

    setState(() {
      if (_activeGroups.contains(group)) {
        if (_activeGroups.length > 2) {
          _activeGroups.remove(group);
          for (int i = 0; i < _containers.length; i++) {
            _containers[i] = _containers[i]
                .where((piece) => piece.groupKey != group)
                .toList(growable: true);
          }
        } else {
          _showSnack('Keep at least 2 active groups.');
        }
      } else {
        _activeGroups.add(group);
      }

      if (!_activeGroups.contains(_selectedGroup)) {
        _selectedGroup = _activeGroups.first;
      }
    });
  }

  void _addContainer() {
    if (_isReadOnly) return;
    setState(() {
      _containers.add(<SortPiece>[]);
    });
  }

  void _removeContainer() {
    if (_isReadOnly) return;
    if (_containers.length <= 3) {
      _showSnack('Use at least 3 containers.');
      return;
    }
    setState(() {
      _containers.removeLast();
    });
  }

  void _changeCapacity(int value) {
    if (_isReadOnly) return;

    setState(() {
      _capacity = value;
      _containers = _containers.map((items) {
        final List<SortPiece> next = <SortPiece>[];
        int filled = 0;

        for (final piece in items) {
          if (filled >= _capacity) break;

          if (filled + piece.amount <= _capacity) {
            next.add(piece);
            filled += piece.amount;
          } else {
            next.add(piece.copyWith(amount: _capacity - filled));
            filled = _capacity;
          }
        }
        return next;
      }).toList(growable: true);
    });

    _showSnack('Capacity changed to $_capacity. Recheck your color totals.');
  }

  void _onContainerTapped(int containerIndex) {
    if (_isReadOnly) return;

    final int totalForSelected = _totalPiecesForGroup(_selectedGroup);
    if (totalForSelected >= _capacity) {
      _showSnack(
        '${_prettyGroup(_selectedGroup)} is already complete ($_capacity/$_capacity). Choose another color or remove one first.',
      );
      return;
    }

    setState(() {
      final List<SortPiece> pieces = _containers[containerIndex];
      final int used = pieces.fold<int>(0, (sum, item) => sum + item.amount);

      if (used >= _capacity) {
        if (pieces.isNotEmpty) {
          final SortPiece removed = pieces.removeLast();
          if (removed.amount > 1) {
            pieces.add(removed.copyWith(amount: removed.amount - 1));
          }
        }
        return;
      }

      if (widget.variant.isFlow &&
          pieces.isNotEmpty &&
          pieces.last.groupKey == _selectedGroup) {
        final SortPiece last = pieces.removeLast();
        pieces.add(last.copyWith(amount: last.amount + 1));
      } else {
        pieces.add(
          SortPiece(
            groupKey: _selectedGroup,
            amount: 1,
          ),
        );
      }
    });

    final int updatedTotal = _totalPiecesForGroup(_selectedGroup);
    if (updatedTotal == _capacity) {
      _showSnack(
        '${_prettyGroup(_selectedGroup)} is now complete ($_capacity/$_capacity).',
      );
    }
  }

  SortPuzzleCreatorDraft _buildDraft({
    required String id,
  }) {
    final List<CreatorContainerDraft> creatorContainers =
    List<CreatorContainerDraft>.generate(
      _containers.length,
          (index) => CreatorContainerDraft(
        id: 'c${index + 1}',
        capacity: _capacity,
        pieces: List<SortPiece>.from(_containers[index]),
      ),
      growable: false,
    );

    return SortPuzzleCreatorDraft(
      id: id,
      title: _titleController.text.trim().isEmpty
          ? 'My Sort Puzzle'
          : _titleController.text.trim(),
      creatorName: _creatorNameController.text.trim().isEmpty
          ? _defaultCreatorName()
          : _creatorNameController.text.trim(),
      variant: widget.variant,
      capacity: _capacity,
      containers: creatorContainers,
      themeKey: widget.variant.name,
      difficulty: 'easy',
      star3Target: 12,
      star2Target: 18,
      star1Target: 26,
      backgroundKey: widget.variant.name,
      containerSkinKey: widget.variant.name,
      pieceSkinKey: widget.variant.name,
      soundPackKey: 'default_sort',
    );
  }

  Future<void> _testPlay() async {
    if (!_isReadyForPreview) {
      _showSnack(_previewBlockReason ?? 'Puzzle is not ready yet.');
      return;
    }

    final SortPuzzleCreatorDraft draft = _buildDraft(
      id: _draftId.isNotEmpty
          ? _draftId
          : 'creator_${DateTime.now().millisecondsSinceEpoch}',
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SortPuzzleGameScreen(
          level: draft.toLevel(levelNumber: 1),
        ),
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_isReadOnly || _isSaving) return;

    if (!_isTitleValid) {
      _showSnack('Please give your puzzle a title before saving.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final String draftIdSeed = _draftId.isNotEmpty
          ? _draftId
          : '${uid.isEmpty ? 'local' : uid}|${DateTime.now().millisecondsSinceEpoch}';

      final SortPuzzleCreatorDraft draft = _buildDraft(id: draftIdSeed);
      final String savedId = await SortPuzzleRepository.instance.saveDraft(draft);

      if (!mounted) return;

      setState(() {
        _draftId = savedId;
      });

      _showSnack(
        _isReadyForPreview
            ? 'Draft saved. Your puzzle is ready for preview and submission.'
            : 'Draft saved. Continue completing the steps.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not save draft: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _submitProject() async {
    if (_isReadOnly || _isSubmitting) return;

    if (!_isReadyForPreview) {
      _showSnack(_previewBlockReason ?? 'Puzzle is not ready yet.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bool canSubmit = await SortPuzzleRepository.instance.canSubmitMoreGames();
      if (!canSubmit) {
        if (!mounted) return;
        _showSnack('Free limit reached (2 submissions).');
        setState(() => _isSubmitting = false);
        return;
      }

      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final String draftIdSeed = _draftId.isNotEmpty
          ? _draftId
          : '${uid.isEmpty ? 'local' : uid}|${DateTime.now().millisecondsSinceEpoch}';

      final SortPuzzleCreatorDraft draft = _buildDraft(id: draftIdSeed);
      await SortPuzzleRepository.instance.submitForReview(draft);

      if (!mounted) return;

      _showSnack('Sort Puzzle submitted for review successfully.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not submit project: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _prettyGroup(String key) {
    return key[0].toUpperCase() + key.substring(1);
  }

  Color _groupColor(String key) {
    switch (key) {
      case 'red':
        return const Color(0xFFFF5A5F);
      case 'blue':
        return const Color(0xFF4A8CFF);
      case 'green':
        return const Color(0xFF37C978);
      case 'yellow':
        return const Color(0xFFF4C84B);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'orange':
        return const Color(0xFFFF9E2C);
      default:
        return const Color(0xFF5B67F1);
    }
  }

  Color _accentFor(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return const Color(0xFF17A8FF);
      case SortPuzzleVariant.ball:
        return const Color(0xFF5B67F1);
      case SortPuzzleVariant.color:
        return const Color(0xFFFF9E2C);
      case SortPuzzleVariant.water:
        return const Color(0xFF17A8FF);
      case SortPuzzleVariant.sand:
        return const Color(0xFFE39B2E);
    }
  }

  Color _accent2For(SortPuzzleVariant variant) {
    switch (variant) {
      case SortPuzzleVariant.bird:
        return const Color(0xFF4FD26B);
      case SortPuzzleVariant.ball:
        return const Color(0xFF8B5CF6);
      case SortPuzzleVariant.color:
        return const Color(0xFFFF5F6D);
      case SortPuzzleVariant.water:
        return const Color(0xFF5B67F1);
      case SortPuzzleVariant.sand:
        return const Color(0xFFFFC94A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentFor(widget.variant);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _isReviewMode ? const Color(0xFF18122B) : Colors.white,
        foregroundColor: _isReviewMode ? Colors.white : const Color(0xFF111827),
        title: Text(
          _isReviewMode
              ? '${_variantLabel(widget.variant)} Review'
              : '${_variantLabel(widget.variant)} Creator',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Rules',
            onPressed: _showRulesDialog,
            icon: const Icon(Icons.rule_folder_outlined),
          ),
          if (!_isReviewMode)
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
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentFor(widget.variant), _accent2For(widget.variant)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isReviewMode ? 'Review Mode' : 'DIY Sort Puzzle Studio',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isReviewMode
                        ? 'Inspect the puzzle step by step and play it in review mode.'
                        : 'Build your puzzle in guided steps, preview it cleanly, then submit for review.',
                    style: const TextStyle(
                      color: Colors.white,
                      height: 1.35,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _StepHeader(
              currentStep: _currentStep,
              accent: accent,
              isReviewMode: _isReviewMode,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: IndexedStack(
                index: _currentStep,
                children: [
                  _StepScaffold(
                    child: _StepOneTitleCreator(
                      titleController: _titleController,
                      creatorController: _creatorNameController,
                      accent: accent,
                      isReadOnly: _isReadOnly,
                      titleValid: _isTitleValid,
                      creatorValid: _isCreatorNameValid,
                    ),
                  ),
                  _StepScaffold(
                    child: _StepTwoSetup(
                      allGroups: _allGroups,
                      activeGroups: _activeGroups,
                      selectedGroup: _selectedGroup,
                      capacity: _capacity,
                      containerCount: _containers.length,
                      isReadOnly: _isReadOnly,
                      groupColor: _groupColor,
                      onToggleGroup: _toggleActiveGroup,
                      onSelectGroup: (value) {
                        if (_isReadOnly) return;
                        setState(() => _selectedGroup = value);
                      },
                      onAddContainer: _addContainer,
                      onRemoveContainer: _removeContainer,
                      onChangeCapacity: _changeCapacity,
                    ),
                  ),
                  _StepScaffold(
                    child: _StepThreeContainers(
                      containers: _containers,
                      capacity: _capacity,
                      selectedGroup: _selectedGroup,
                      activeGroups: _activeGroups.toList(growable: false),
                      isReadOnly: _isReadOnly,
                      variant: widget.variant,
                      groupColor: _groupColor,
                      validationMessages: _groupValidationMessages,
                      solvedContainerCount: _solvedContainerCount,
                      onSelectGroup: (value) {
                        if (_isReadOnly) return;
                        setState(() => _selectedGroup = value);
                      },
                      onContainerTap: _onContainerTapped,
                    ),
                  ),
                  _StepScaffold(
                    child: _StepFourPreview(
                      title: _titleController.text.trim(),
                      creatorName: _creatorNameController.text.trim(),
                      variantLabel: _variantLabel(widget.variant),
                      containers: _containers,
                      capacity: _capacity,
                      activeGroups: _activeGroups.toList(growable: false),
                      variant: widget.variant,
                      groupColor: _groupColor,
                      ready: _isReadyForPreview,
                      reason: _previewBlockReason,
                      onTestPlay: _testPlay,
                      isReviewMode: _isReviewMode,
                    ),
                  ),
                  _StepScaffold(
                    child: _StepFiveSubmit(
                      draftReady: _isReadyForPreview,
                      reason: _previewBlockReason,
                      isSubmitting: _isSubmitting,
                      isReviewMode: _isReviewMode,
                      onSubmit: _submitProject,
                    ),
                  ),
                ],
              ),
            ),
            _WizardBottomBar(
              currentStep: _currentStep,
              canGoNext: _canGoNext(),
              isReviewMode: _isReviewMode,
              onBack: _previousStep,
              onNext: _nextStep,
              onSave: _isReviewMode ? null : _saveDraft,
              isSaving: _isSaving,
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '• $text',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          height: 1.35,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.currentStep,
    required this.accent,
    required this.isReviewMode,
  });

  final int currentStep;
  final Color accent;
  final bool isReviewMode;

  static const List<String> _labels = <String>[
    'Title',
    'Setup',
    'Build',
    'Preview',
    'Submit',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, index) {
          final bool active = index == currentStep;
          final bool done = index < currentStep;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: active
                  ? accent
                  : done
                  ? accent.withOpacity(0.14)
                  : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active ? accent : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: active ? Colors.white : const Color(0xFFF3F4F6),
                  child: Icon(
                    done ? Icons.check_rounded : Icons.circle,
                    size: 12,
                    color: active ? accent : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _labels[index],
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _labels.length,
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [child],
    );
  }
}

class _StepOneTitleCreator extends StatelessWidget {
  const _StepOneTitleCreator({
    required this.titleController,
    required this.creatorController,
    required this.accent,
    required this.isReadOnly,
    required this.titleValid,
    required this.creatorValid,
  });

  final TextEditingController titleController;
  final TextEditingController creatorController;
  final Color accent;
  final bool isReadOnly;
  final bool titleValid;
  final bool creatorValid;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      dimmed: isReadOnly,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Step 1 • Puzzle Title & Creator'),
          const SizedBox(height: 12),
          TextField(
            controller: titleController,
            readOnly: isReadOnly,
            decoration: _inputDecoration('Puzzle title', accent),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: creatorController,
            readOnly: isReadOnly,
            decoration: _inputDecoration('Creator name', accent),
          ),
          const SizedBox(height: 16),
          _StatusInfoRow(
            icon: titleValid && creatorValid
                ? Icons.check_circle_rounded
                : Icons.info_outline_rounded,
            iconColor: titleValid && creatorValid
                ? const Color(0xFF16A34A)
                : accent,
            text: titleValid && creatorValid
                ? 'Good start. Move to setup.'
                : 'Title needs 3+ characters and creator name needs 2+ characters.',
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color accent) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: accent, width: 1.4),
      ),
    );
  }
}

class _StepTwoSetup extends StatelessWidget {
  const _StepTwoSetup({
    required this.allGroups,
    required this.activeGroups,
    required this.selectedGroup,
    required this.capacity,
    required this.containerCount,
    required this.isReadOnly,
    required this.groupColor,
    required this.onToggleGroup,
    required this.onSelectGroup,
    required this.onAddContainer,
    required this.onRemoveContainer,
    required this.onChangeCapacity,
  });

  final List<String> allGroups;
  final Set<String> activeGroups;
  final String selectedGroup;
  final int capacity;
  final int containerCount;
  final bool isReadOnly;
  final Color Function(String) groupColor;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<String> onSelectGroup;
  final VoidCallback onAddContainer;
  final VoidCallback onRemoveContainer;
  final ValueChanged<int> onChangeCapacity;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      dimmed: isReadOnly,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Step 2 • Groups, Capacity & Containers'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allGroups.map((group) {
              final bool active = activeGroups.contains(group);
              return FilterChip(
                label: Text(group),
                selected: active,
                onSelected: isReadOnly ? null : (_) => onToggleGroup(group),
                selectedColor: groupColor(group).withOpacity(0.18),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: active ? groupColor(group) : const Color(0xFF374151),
                ),
                side: BorderSide(
                  color: active ? groupColor(group) : const Color(0xFFD1D5DB),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: isReadOnly ? null : onRemoveContainer,
                icon: const Icon(Icons.remove),
                label: const Text('Container'),
              ),
              OutlinedButton.icon(
                onPressed: isReadOnly ? null : onAddContainer,
                icon: const Icon(Icons.add),
                label: const Text('Container'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: capacity,
                    items: const <int>[4, 5]
                        .map(
                          (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('Capacity $value'),
                      ),
                    )
                        .toList(growable: false),
                    onChanged: isReadOnly
                        ? null
                        : (value) {
                      if (value != null) onChangeCapacity(value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _StatusInfoRow(
            icon: Icons.tune_rounded,
            iconColor: const Color(0xFF5B67F1),
            text:
            'Active groups: ${activeGroups.length} • Containers: $containerCount • Capacity: $capacity',
          ),
        ],
      ),
    );
  }
}

class _StepThreeContainers extends StatelessWidget {
  const _StepThreeContainers({
    required this.containers,
    required this.capacity,
    required this.selectedGroup,
    required this.activeGroups,
    required this.isReadOnly,
    required this.variant,
    required this.groupColor,
    required this.validationMessages,
    required this.solvedContainerCount,
    required this.onSelectGroup,
    required this.onContainerTap,
  });

  final List<List<SortPiece>> containers;
  final int capacity;
  final String selectedGroup;
  final List<String> activeGroups;
  final bool isReadOnly;
  final SortPuzzleVariant variant;
  final Color Function(String) groupColor;
  final List<String> validationMessages;
  final int solvedContainerCount;
  final ValueChanged<String> onSelectGroup;
  final ValueChanged<int> onContainerTap;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      dimmed: isReadOnly,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Step 3 • Build the Containers'),
          const SizedBox(height: 10),
          Text(
            isReadOnly
                ? 'Review mode. Container editing is disabled.'
                : 'Pick a group, then tap a container to place it. Tap a full container to remove the last placed piece.',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeGroups.map((group) {
              final bool active = group == selectedGroup;
              return ChoiceChip(
                label: Text(group),
                selected: active,
                onSelected: isReadOnly ? null : (_) => onSelectGroup(group),
                selectedColor: groupColor(group).withOpacity(0.18),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: active ? groupColor(group) : const Color(0xFF374151),
                ),
                side: BorderSide(
                  color: active ? groupColor(group) : const Color(0xFFD1D5DB),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live rule check',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                ...validationMessages.map(
                      (message) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '• $message',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                Text(
                  solvedContainerCount > 1
                      ? '• Too many containers are already solved at start.'
                      : '• Solved-at-start containers: $solvedContainerCount',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: solvedContainerCount > 1
                        ? const Color(0xFFB45309)
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: containers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (_, index) {
              return _CreatorContainerCard(
                pieces: containers[index],
                capacity: capacity,
                variant: variant,
                selectedColor: groupColor(selectedGroup),
                onTap: () => onContainerTap(index),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepFourPreview extends StatelessWidget {
  const _StepFourPreview({
    required this.title,
    required this.creatorName,
    required this.variantLabel,
    required this.containers,
    required this.capacity,
    required this.activeGroups,
    required this.variant,
    required this.groupColor,
    required this.ready,
    required this.reason,
    required this.onTestPlay,
    required this.isReviewMode,
  });

  final String title;
  final String creatorName;
  final String variantLabel;
  final List<List<SortPiece>> containers;
  final int capacity;
  final List<String> activeGroups;
  final SortPuzzleVariant variant;
  final Color Function(String) groupColor;
  final bool ready;
  final String? reason;
  final VoidCallback onTestPlay;
  final bool isReviewMode;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Step 4 • Preview & Test'),
          const SizedBox(height: 12),
          _StatusInfoRow(
            icon: ready ? Icons.verified_rounded : Icons.info_outline_rounded,
            iconColor:
            ready ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
            text: ready
                ? 'Puzzle is valid: every active color is complete, at least one tube is empty, and the board starts unsolved.'
                : (reason ?? 'Puzzle is not ready yet.'),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: title.isEmpty ? 'Untitled' : title),
              _InfoPill(label: creatorName.isEmpty ? 'Arena Builder' : creatorName),
              _InfoPill(label: variantLabel),
              _InfoPill(label: 'Groups ${activeGroups.length}'),
              _InfoPill(label: 'Containers ${containers.length}'),
              _InfoPill(label: 'Capacity $capacity'),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: containers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
            ),
            itemBuilder: (_, index) {
              return _CreatorContainerCard(
                pieces: containers[index],
                capacity: capacity,
                variant: variant,
                selectedColor: groupColor(activeGroups.first),
                onTap: () {},
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: ready ? onTestPlay : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(isReviewMode ? 'Play Project' : 'Test Play'),
          ),
        ],
      ),
    );
  }
}

class _StepFiveSubmit extends StatelessWidget {
  const _StepFiveSubmit({
    required this.draftReady,
    required this.reason,
    required this.isSubmitting,
    required this.isReviewMode,
    required this.onSubmit,
  });

  final bool draftReady;
  final String? reason;
  final bool isSubmitting;
  final bool isReviewMode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _StudioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Step 5 • Submit for Review'),
          const SizedBox(height: 12),
          _StatusInfoRow(
            icon: draftReady ? Icons.task_alt_rounded : Icons.warning_amber_rounded,
            iconColor:
            draftReady ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
            text: draftReady
                ? 'Everything looks good. You can submit this puzzle.'
                : (reason ?? 'Complete the previous steps first.'),
          ),
          const SizedBox(height: 16),
          if (!isReviewMode)
            ElevatedButton.icon(
              onPressed: draftReady && !isSubmitting ? onSubmit : null,
              icon: Icon(
                isSubmitting ? Icons.hourglass_top_rounded : Icons.send_rounded,
              ),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit Project'),
            ),
        ],
      ),
    );
  }
}

class _WizardBottomBar extends StatelessWidget {
  const _WizardBottomBar({
    required this.currentStep,
    required this.canGoNext,
    required this.isReviewMode,
    required this.onBack,
    required this.onNext,
    required this.onSave,
    required this.isSaving,
  });

  final int currentStep;
  final bool canGoNext;
  final bool isReviewMode;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: currentStep == 0 ? null : onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
          ),
          const SizedBox(width: 10),
          if (!isReviewMode)
            OutlinedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save_rounded),
              label: Text(isSaving ? 'Saving...' : 'Save Draft'),
            ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: currentStep >= 4 || !canGoNext ? null : onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
          ),
        ],
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
            color: dimmed ? const Color(0xFFD1D5DB) : const Color(0xFFE5E7EB),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _CreatorContainerCard extends StatelessWidget {
  const _CreatorContainerCard({
    required this.pieces,
    required this.capacity,
    required this.variant,
    required this.selectedColor,
    required this.onTap,
  });

  final List<SortPiece> pieces;
  final int capacity;
  final SortPuzzleVariant variant;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final List<SortPiece?> slots = _expandPiecesToSlots(pieces, capacity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFD1D5DB),
                        width: 2,
                      ),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List<Widget>.generate(capacity, (index) {
                          final SortPiece? piece = slots[index];
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                bottom: index == capacity - 1 ? 0 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: piece == null
                                    ? const Color(0xFFF0ECF6)
                                    : _pieceColor(piece.groupKey),
                                borderRadius: BorderRadius.circular(
                                  variant == SortPuzzleVariant.ball ? 999 : 14,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<SortPiece?> _expandPiecesToSlots(List<SortPiece> pieces, int capacity) {
    final List<SortPiece?> slots = <SortPiece?>[];
    for (final SortPiece piece in pieces) {
      for (int i = 0; i < piece.amount; i++) {
        if (slots.length < capacity) {
          slots.add(piece.copyWith(amount: 1));
        }
      }
    }
    while (slots.length < capacity) {
      slots.add(null);
    }
    return slots.reversed.toList(growable: false);
  }

  Color _pieceColor(String key) {
    switch (key) {
      case 'red':
        return const Color(0xFFFF5A5F);
      case 'blue':
        return const Color(0xFF4A8CFF);
      case 'green':
        return const Color(0xFF37C978);
      case 'yellow':
        return const Color(0xFFF4C84B);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'orange':
        return const Color(0xFFFF9E2C);
      default:
        return selectedColor;
    }
  }
}