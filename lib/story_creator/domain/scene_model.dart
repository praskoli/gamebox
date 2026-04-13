import 'package:cloud_firestore/cloud_firestore.dart';

class SceneModel {
  const SceneModel({
    required this.id,
    required this.storyId,
    required this.order,
    required this.title,
    required this.caption,
    required this.narration,
    required this.imagePath,
    required this.imageUrl,
    required this.durationSeconds,
    required this.status,
    required this.flagReason,
    required this.isModerated,
    required this.soundEffect,
    required this.narrationAudioUrl,
    required this.narrationAudioPath,
    required this.audioStatus,
    required this.audioDurationMs,
    required this.voiceId,
    required this.createdAt,
    required this.updatedAt,
    required this.audioUpdatedAt,
  });

  final String id;
  final String storyId;
  final int order;
  final String title;
  final String caption;
  final String narration;
  final String imagePath;
  final String imageUrl;
  final int durationSeconds;
  final String status;
  final String flagReason;
  final bool isModerated;
  final String soundEffect;

  final String narrationAudioUrl;
  final String narrationAudioPath;
  final String audioStatus;
  final int audioDurationMs;
  final String voiceId;
  final DateTime? audioUpdatedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const int maxNarrationWords = 100;

  static const List<String> availableSoundEffects = <String>[
    'none',
    'magic',
    'forest',
    'water',
    'crowd',
    'celebration',
    'suspense',
  ];

  factory SceneModel.empty({
    required String storyId,
    required int order,
  }) {
    return SceneModel(
      id: 'scene_${(order + 1).toString().padLeft(2, '0')}',
      storyId: storyId,
      order: order,
      title: '',
      caption: '',
      narration: '',
      imagePath: '',
      imageUrl: '',
      durationSeconds: 4,
      status: 'draft',
      flagReason: '',
      isModerated: false,
      soundEffect: 'none',
      narrationAudioUrl: '',
      narrationAudioPath: '',
      audioStatus: '',
      audioDurationMs: 0,
      voiceId: '',
      createdAt: null,
      updatedAt: null,
      audioUpdatedAt: null,
    );
  }

  factory SceneModel.fromMap(Map<String, dynamic> map) {
    return SceneModel(
      id: (map['id'] ?? '').toString(),
      storyId: (map['storyId'] ?? '').toString(),
      order: _readInt(map['order']),
      title: (map['title'] ?? '').toString(),
      caption: (map['caption'] ?? '').toString(),
      narration: (map['narration'] ?? '').toString(),
      imagePath: (map['imagePath'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      durationSeconds: _readInt(map['durationSeconds'], fallback: 4),
      status: (map['status'] ?? 'draft').toString(),
      flagReason: (map['flagReason'] ?? '').toString(),
      isModerated: _readBool(map['isModerated']),
      soundEffect: (map['soundEffect'] ?? 'none').toString(),
      narrationAudioUrl: (map['narrationAudioUrl'] ?? '').toString(),
      narrationAudioPath: (map['narrationAudioPath'] ?? '').toString(),
      audioStatus: (map['audioStatus'] ?? '').toString(),
      audioDurationMs: _readInt(map['audioDurationMs']),
      voiceId: (map['voiceId'] ?? '').toString(),
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
      audioUpdatedAt: _readDateTime(map['audioUpdatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'storyId': storyId,
      'order': order,
      'title': title,
      'caption': caption,
      'narration': narration,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'durationSeconds': durationSeconds,
      'status': status,
      'flagReason': flagReason,
      'isModerated': isModerated,
      'soundEffect': soundEffect,
      'narrationAudioUrl': narrationAudioUrl,
      'narrationAudioPath': narrationAudioPath,
      'audioStatus': audioStatus,
      'audioDurationMs': audioDurationMs,
      'voiceId': voiceId,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'audioUpdatedAt':
      audioUpdatedAt == null ? null : Timestamp.fromDate(audioUpdatedAt!),
    };
  }

  SceneModel copyWith({
    String? id,
    String? storyId,
    int? order,
    String? title,
    String? caption,
    String? narration,
    String? imagePath,
    String? imageUrl,
    int? durationSeconds,
    String? status,
    String? flagReason,
    bool? isModerated,
    String? soundEffect,
    String? narrationAudioUrl,
    String? narrationAudioPath,
    String? audioStatus,
    int? audioDurationMs,
    String? voiceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? audioUpdatedAt,
  }) {
    return SceneModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      order: order ?? this.order,
      title: title ?? this.title,
      caption: caption ?? this.caption,
      narration: narration ?? this.narration,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      flagReason: flagReason ?? this.flagReason,
      isModerated: isModerated ?? this.isModerated,
      soundEffect: soundEffect ?? this.soundEffect,
      narrationAudioUrl: narrationAudioUrl ?? this.narrationAudioUrl,
      narrationAudioPath: narrationAudioPath ?? this.narrationAudioPath,
      audioStatus: audioStatus ?? this.audioStatus,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
      voiceId: voiceId ?? this.voiceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      audioUpdatedAt: audioUpdatedAt ?? this.audioUpdatedAt,
    );
  }

  static String generateCaption(String narration) {
    final String clean = narration.trim();
    if (clean.isEmpty) return '';
    if (clean.length <= 90) return clean;
    return '${clean.substring(0, 87).trim()}...';
  }

  static int calculateDurationSeconds(String narration) {
    final String text = narration.trim();
    if (text.isEmpty) return 4;

    final int wordCount = countWords(text);
    final int estimated = (wordCount / 2.6).ceil();

    if (estimated < 4) return 4;
    if (estimated > 12) return 12;
    return estimated;
  }

  static int countWords(String text) {
    return text
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .length;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}