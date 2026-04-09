import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  const StoryModel({
    required this.id,
    required this.ownerUid,
    required this.ownerEmail,
    required this.creatorName,
    required this.title,
    required this.theme,
    required this.language,
    required this.totalScenes,
    required this.coverImagePath,
    required this.coverImageUrl,
    required this.status,
    required this.contentType,
    required this.sourceType,
    required this.isModerated,
    required this.communityVisible,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy = '',
    this.rejectionReason = '',
    this.previewReadyAt,
  });

  static const int maxScenes = 15;

  static List<String> get predefinedThemes => const <String>[
    'Jungle Adventure',
    'Space Journey',
    'Magic Kingdom',
    'Ocean Discovery',
    'Animal Friends',
    'Festival Fun',
    'Dinosaur Quest',
    'Superhero Mission',
  ];

  static List<String> get predefinedLanguages => const <String>[
    'English',
    'Telugu',
    'Hindi',
  ];

  final String id;
  final String ownerUid;
  final String ownerEmail;
  final String creatorName;
  final String title;
  final String theme;
  final String language;
  final int totalScenes;
  final String coverImagePath;
  final String coverImageUrl;
  final String status;
  final String contentType;
  final String sourceType;
  final bool isModerated;
  final bool communityVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? previewReadyAt;
  final String reviewedBy;
  final String rejectionReason;

  StoryModel copyWith({
    String? id,
    String? ownerUid,
    String? ownerEmail,
    String? creatorName,
    String? title,
    String? theme,
    String? language,
    int? totalScenes,
    String? coverImagePath,
    String? coverImageUrl,
    String? status,
    String? contentType,
    String? sourceType,
    bool? isModerated,
    bool? communityVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    DateTime? previewReadyAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return StoryModel(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      creatorName: creatorName ?? this.creatorName,
      title: title ?? this.title,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      totalScenes: totalScenes ?? this.totalScenes,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      status: status ?? this.status,
      contentType: contentType ?? this.contentType,
      sourceType: sourceType ?? this.sourceType,
      isModerated: isModerated ?? this.isModerated,
      communityVisible: communityVisible ?? this.communityVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      previewReadyAt: previewReadyAt ?? this.previewReadyAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ownerUid': ownerUid,
      'ownerEmail': ownerEmail,
      'creatorName': creatorName,
      'title': title,
      'theme': theme,
      'language': language,
      'totalScenes': totalScenes,
      'coverImagePath': coverImagePath,
      'coverImageUrl': coverImageUrl,
      'status': status,
      'contentType': contentType,
      'sourceType': sourceType,
      'isModerated': isModerated,
      'communityVisible': communityVisible,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'submittedAt': submittedAt == null ? null : Timestamp.fromDate(submittedAt!),
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'previewReadyAt':
      previewReadyAt == null ? null : Timestamp.fromDate(previewReadyAt!),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      id: (map['id'] ?? '').toString(),
      ownerUid: (map['ownerUid'] ?? '').toString(),
      ownerEmail: (map['ownerEmail'] ?? '').toString(),
      creatorName: (map['creatorName'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      theme: (map['theme'] ?? predefinedThemes.first).toString(),
      language: (map['language'] ?? predefinedLanguages.first).toString(),
      totalScenes: (map['totalScenes'] as num?)?.toInt() ?? 1,
      coverImagePath: (map['coverImagePath'] ?? '').toString(),
      coverImageUrl: (map['coverImageUrl'] ?? '').toString(),
      status: (map['status'] ?? 'draft').toString(),
      contentType: (map['contentType'] ?? 'story').toString(),
      sourceType: (map['sourceType'] ?? 'diy').toString(),
      isModerated: map['isModerated'] == true,
      communityVisible: map['communityVisible'] == true,
      createdAt: _timestampToDate(map['createdAt']),
      updatedAt: _timestampToDate(map['updatedAt']),
      submittedAt: _timestampToDate(map['submittedAt']),
      reviewedAt: _timestampToDate(map['reviewedAt']),
      previewReadyAt: _timestampToDate(map['previewReadyAt']),
      reviewedBy: (map['reviewedBy'] ?? '').toString(),
      rejectionReason: (map['rejectionReason'] ?? '').toString(),
    );
  }

  factory StoryModel.empty() {
    return StoryModel(
      id: '',
      ownerUid: '',
      ownerEmail: '',
      creatorName: '',
      title: '',
      theme: predefinedThemes.first,
      language: predefinedLanguages.first,
      totalScenes: 5,
      coverImagePath: '',
      coverImageUrl: '',
      status: 'draft',
      contentType: 'story',
      sourceType: 'diy',
      isModerated: false,
      communityVisible: false,
      createdAt: null,
      updatedAt: null,
    );
  }

  bool get isDraftLike => status == 'draft' || status == 'rejected';

  bool get isPreviewReady => status == 'preview_ready';

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
