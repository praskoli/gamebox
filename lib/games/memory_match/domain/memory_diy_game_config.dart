import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryDiyGameConfig {
  const MemoryDiyGameConfig({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.baseWorldId,
    required this.gridColumns,
    required this.gridRows,
    required this.previewDurationMs,
    required this.flipBackDelayMs,
    required this.items,
    required this.levelNumber,
    required this.ownerUid,
    required this.createdAt,
    required this.updatedAt,
    required this.isMixedCategory,
    required this.status,
    required this.submittedAt,
    required this.reviewedAt,
    required this.reviewedBy,
    required this.rejectionReason,
  });

  final String id;
  final String title;
  final String categoryId;
  final String baseWorldId;
  final int gridColumns;
  final int gridRows;
  final int previewDurationMs;
  final int flipBackDelayMs;
  final List<String> items;
  final int levelNumber;
  final String ownerUid;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isMixedCategory;

  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String reviewedBy;
  final String rejectionReason;

  int get totalCells => gridColumns * gridRows;
  int get totalPairs => totalCells ~/ 2;

  bool get isDraft => status == 'draft';
  bool get isPendingReview => status == 'pending_review';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  MemoryDiyGameConfig copyWith({
    String? id,
    String? title,
    String? categoryId,
    String? baseWorldId,
    int? gridColumns,
    int? gridRows,
    int? previewDurationMs,
    int? flipBackDelayMs,
    List<String>? items,
    int? levelNumber,
    String? ownerUid,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isMixedCategory,
    String? status,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return MemoryDiyGameConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      baseWorldId: baseWorldId ?? this.baseWorldId,
      gridColumns: gridColumns ?? this.gridColumns,
      gridRows: gridRows ?? this.gridRows,
      previewDurationMs: previewDurationMs ?? this.previewDurationMs,
      flipBackDelayMs: flipBackDelayMs ?? this.flipBackDelayMs,
      items: items ?? this.items,
      levelNumber: levelNumber ?? this.levelNumber,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isMixedCategory: isMixedCategory ?? this.isMixedCategory,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'categoryId': categoryId,
      'baseWorldId': baseWorldId,
      'gridColumns': gridColumns,
      'gridRows': gridRows,
      'previewDurationMs': previewDurationMs,
      'flipBackDelayMs': flipBackDelayMs,
      'items': items,
      'levelNumber': levelNumber,
      'ownerUid': ownerUid,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'isMixedCategory': isMixedCategory,
      'gameType': 'memory',
      'status': status,
      'submittedAt':
      submittedAt == null ? null : Timestamp.fromDate(submittedAt!),
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory MemoryDiyGameConfig.fromMap(Map<String, dynamic> map) {
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    int readInt(dynamic value, int fallback) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return fallback;
    }

    bool readBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      return fallback;
    }

    String readString(dynamic value, String fallback) {
      if (value is String && value.trim().isNotEmpty) return value;
      return fallback;
    }

    return MemoryDiyGameConfig(
      id: readString(map['id'], ''),
      title: readString(map['title'], 'My Memory Game'),
      categoryId: readString(map['categoryId'], 'fruits'),
      baseWorldId: readString(map['baseWorldId'], 'fruits'),
      gridColumns: readInt(map['gridColumns'], 4),
      gridRows: readInt(map['gridRows'], 4),
      previewDurationMs: readInt(map['previewDurationMs'], 1200),
      flipBackDelayMs: readInt(map['flipBackDelayMs'], 650),
      items: List<String>.from(map['items'] ?? const <String>[]),
      levelNumber: readInt(map['levelNumber'], 1),
      ownerUid: readString(map['ownerUid'], ''),
      createdAt: readDate(map['createdAt']),
      updatedAt: readDate(map['updatedAt']),
      isMixedCategory: readBool(map['isMixedCategory'], false),
      status: readString(map['status'], 'draft'),
      submittedAt: readDate(map['submittedAt']),
      reviewedAt: readDate(map['reviewedAt']),
      reviewedBy: readString(map['reviewedBy'], ''),
      rejectionReason: readString(map['rejectionReason'], ''),
    );
  }
}