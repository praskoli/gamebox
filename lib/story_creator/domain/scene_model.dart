import 'package:cloud_firestore/cloud_firestore.dart';

class SceneModel {
  const SceneModel({
    required this.id,
    required this.storyId,
    required this.order,
    required this.title,
    required this.narration,
    required this.caption,
    required this.durationSeconds,
    required this.soundEffect,
    required this.imagePath,
    required this.imageUrl,
    required this.status,
    required this.isModerated,
    required this.createdAt,
    required this.updatedAt,
    this.flagReason = '',
  });

  static const int maxNarrationWords = 100;

  final String id;
  final String storyId;
  final int order;
  final String title;
  final String narration;
  final String caption;
  final int durationSeconds;
  final String soundEffect;
  final String imagePath;
  final String imageUrl;
  final String status;
  final bool isModerated;
  final String flagReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static List<String> get availableSoundEffects => const <String>[
    'none',
    'jungle',
    'magic',
    'ocean',
    'rain',
    'wind',
  ];

  SceneModel copyWith({
    String? id,
    String? storyId,
    int? order,
    String? title,
    String? narration,
    String? caption,
    int? durationSeconds,
    String? soundEffect,
    String? imagePath,
    String? imageUrl,
    String? status,
    bool? isModerated,
    String? flagReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SceneModel(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      order: order ?? this.order,
      title: title ?? this.title,
      narration: narration ?? this.narration,
      caption: caption ?? this.caption,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      soundEffect: soundEffect ?? this.soundEffect,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      isModerated: isModerated ?? this.isModerated,
      flagReason: flagReason ?? this.flagReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'storyId': storyId,
      'order': order,
      'title': title,
      'narration': narration,
      'caption': caption,
      'durationSeconds': durationSeconds,
      'soundEffect': soundEffect,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
      'status': status,
      'isModerated': isModerated,
      'flagReason': flagReason,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  factory SceneModel.fromMap(Map<String, dynamic> map) {
    return SceneModel(
      id: (map['id'] ?? '').toString(),
      storyId: (map['storyId'] ?? '').toString(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      title: (map['title'] ?? '').toString(),
      narration: (map['narration'] ?? '').toString(),
      caption: (map['caption'] ?? '').toString(),
      durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 3,
      soundEffect: (map['soundEffect'] ?? 'none').toString(),
      imagePath: (map['imagePath'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      status: (map['status'] ?? 'draft').toString(),
      isModerated: map['isModerated'] == true,
      flagReason: (map['flagReason'] ?? '').toString(),
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
    );
  }

  factory SceneModel.empty({
    required String storyId,
    required int order,
  }) {
    final String id = 'scene_${(order + 1).toString().padLeft(2, '0')}';
    return SceneModel(
      id: id,
      storyId: storyId,
      order: order,
      title: '',
      narration: '',
      caption: '',
      durationSeconds: 3,
      soundEffect: 'none',
      imagePath: '',
      imageUrl: '',
      status: 'draft',
      isModerated: false,
      createdAt: null,
      updatedAt: null,
    );
  }

  bool get hasImage => imageUrl.trim().isNotEmpty;

  bool get isReadyForPreview =>
      title.trim().isNotEmpty && narration.trim().isNotEmpty && hasImage;

  static String generateCaption(String narration) {
    final List<String> words = narration
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .split(' ')
        .where((String word) => word.trim().isNotEmpty)
        .toList(growable: false);

    if (words.isEmpty) {
      return '';
    }

    final int take = words.length <= 12 ? words.length : 12;
    final String caption = words.take(take).join(' ').trim();
    return caption.endsWith('.') ? caption : '$caption...';
  }

  static int calculateDurationSeconds(String narration) {
    final int words = narration
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.trim().isNotEmpty)
        .length;
    if (words <= 0) return 3;
    final int seconds = (words / 2.6).ceil();
    return seconds.clamp(3, 30);
  }

  static int countWords(String input) {
    return input
        .trim()
        .split(RegExp(r'\s+'))
        .where((String word) => word.trim().isNotEmpty)
        .length;
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
