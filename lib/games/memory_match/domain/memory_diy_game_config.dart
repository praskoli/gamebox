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

  int get totalCells => gridColumns * gridRows;
  int get totalPairs => totalCells ~/ 2;

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
      'status': 'draft',
    };
  }

  factory MemoryDiyGameConfig.fromMap(Map<String, dynamic> map) {
    DateTime? _readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return MemoryDiyGameConfig(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? 'My Memory Game') as String,
      categoryId: (map['categoryId'] ?? 'fruits') as String,
      baseWorldId: (map['baseWorldId'] ?? 'fruits') as String,
      gridColumns: (map['gridColumns'] ?? 4) as int,
      gridRows: (map['gridRows'] ?? 4) as int,
      previewDurationMs: (map['previewDurationMs'] ?? 1200) as int,
      flipBackDelayMs: (map['flipBackDelayMs'] ?? 650) as int,
      items: List<String>.from(map['items'] ?? const <String>[]),
      levelNumber: (map['levelNumber'] ?? 1) as int,
      ownerUid: (map['ownerUid'] ?? '') as String,
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
      isMixedCategory: (map['isMixedCategory'] ?? false) as bool,
    );
  }
}