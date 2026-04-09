import 'dart:io';

class ModerationResult {
  const ModerationResult({
    required this.isAllowed,
    required this.status,
    this.reason = '',
    this.shouldBlockSubmit = false,
    this.matchedTerms = const <String>[],
  });

  final bool isAllowed;
  final String status; // draft | validating | ready | flagged
  final String reason;
  final bool shouldBlockSubmit;
  final List<String> matchedTerms;

  bool get isFlagged => status == 'flagged';

  static const ModerationResult ready = ModerationResult(
    isAllowed: true,
    status: 'ready',
  );
}

class StoryModerationService {
  const StoryModerationService();

  static const Set<String> _exactBadWords = <String>{
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'bastard',
    'slut',
    'whore',
    'dick',
    'cock',
    'chutiya',
    'madarchod',
    'bhenchod',
    'randi',
    'lavda',
    'lund',
    'gaand',
    'lanja',
    'lanjaa',
    'lanjakodaka',
    'puku',
    'pooka',
    'modda',
    'madda',
    'pooku',
    'sex',
    'nude',
    'naked',
    'drugs',
    'kill',
    'murder',
    'blood',
    'weapon',
    'gun',
    'knife',
    'violence',
  };

  static const List<String> _wildcardRoots = <String>[
    'lanja',
    'modda',
    'pooka',
    'chuti',
    'fuck',
  ];

  static const Set<String> _unsafeImageKeywords = <String>{
    'nude',
    'nudity',
    'naked',
    'bikini',
    'lingerie',
    'underwear',
    'bra',
    'panties',
    'gun',
    'knife',
    'weapon',
    'blood',
    'violence',
    'gore',
  };

  Future<ModerationResult> moderateStoryTitle(String input) async {
    return _moderateText(
      input,
      fieldName: 'story title',
      blockOnFlag: true,
    );
  }

  Future<ModerationResult> moderateSceneTitle(String input) async {
    return _moderateText(
      input,
      fieldName: 'scene title',
      blockOnFlag: true,
    );
  }

  Future<ModerationResult> moderateNarration(String input) async {
    return _moderateText(
      input,
      fieldName: 'narration',
      blockOnFlag: true,
    );
  }

  Future<ModerationResult> moderateImage(File file) async {
    if (!await file.exists()) {
      return const ModerationResult(
        isAllowed: false,
        status: 'flagged',
        reason: 'Selected image could not be found.',
        shouldBlockSubmit: true,
      );
    }

    final int bytes = await file.length();
    if (bytes <= 0) {
      return const ModerationResult(
        isAllowed: false,
        status: 'flagged',
        reason: 'Selected image is empty.',
        shouldBlockSubmit: true,
      );
    }

    final String name = file.path.toLowerCase();
    final bool hasValidExtension = name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.webp');

    if (!hasValidExtension) {
      return const ModerationResult(
        isAllowed: false,
        status: 'flagged',
        reason: 'Please choose a PNG, JPG, JPEG, or WEBP image.',
        shouldBlockSubmit: true,
      );
    }

    if (bytes > 8 * 1024 * 1024) {
      return const ModerationResult(
        isAllowed: false,
        status: 'flagged',
        reason: 'Please choose an image under 8 MB.',
        shouldBlockSubmit: true,
      );
    }

    final List<String> matched = _unsafeImageKeywords
        .where((String keyword) => name.contains(keyword))
        .toList(growable: false);

    if (matched.isNotEmpty) {
      return ModerationResult(
        isAllowed: true,
        status: 'flagged',
        reason: 'Image was auto-flagged for admin review.',
        shouldBlockSubmit: false,
        matchedTerms: matched,
      );
    }

    return const ModerationResult(
      isAllowed: true,
      status: 'ready',
    );
  }

  Future<ModerationResult> _moderateText(
      String input, {
        required String fieldName,
        required bool blockOnFlag,
      }) async {
    final String normalized = _normalize(input);
    if (normalized.isEmpty) {
      return const ModerationResult(
        isAllowed: true,
        status: 'draft',
      );
    }

    final Set<String> matched = <String>{};

    for (final String word in _exactBadWords) {
      if (normalized.contains(word)) {
        matched.add(word);
      }
    }

    for (final String root in _wildcardRoots) {
      final RegExp regex = RegExp('\\b${RegExp.escape(root)}[a-z]*\\b');
      if (regex.hasMatch(normalized)) {
        matched.add('$root*');
      }
    }

    if (matched.isEmpty) {
      return const ModerationResult(
        isAllowed: true,
        status: 'ready',
      );
    }

    return ModerationResult(
      isAllowed: !blockOnFlag,
      status: 'flagged',
      reason: 'The $fieldName contains inappropriate language.',
      shouldBlockSubmit: blockOnFlag,
      matchedTerms: matched.toList(growable: false),
    );
  }

  String _normalize(String input) {
    final String lower = input.trim().toLowerCase();
    if (lower.isEmpty) return '';
    final String cleaned = lower.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final String collapsed = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return collapsed.replaceAllMapped(
      RegExp(r'(.)\1{2,}'),
          (Match match) => '${match.group(1)}${match.group(1)}',
    );
  }
}
