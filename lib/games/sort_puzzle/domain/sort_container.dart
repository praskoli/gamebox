import 'sort_container_rules.dart';
import 'sort_piece.dart';

class SortContainer {
  const SortContainer({
    required this.id,
    required this.capacity,
    required this.pieces,
    this.rules = const SortContainerRules(),
  });

  final String id;
  final int capacity;
  final List<SortPiece> pieces;
  final SortContainerRules rules;

  bool get isEmpty => pieces.isEmpty;
  int get usedSlots => pieces.fold<int>(0, (sum, item) => sum + item.amount);
  int get freeSlots => effectiveCapacity - usedSlots;
  SortPiece? get topPiece => pieces.isEmpty ? null : pieces.last;
  bool get isFull => freeSlots == 0;

  int get effectiveCapacity => rules.customCapacity ?? capacity;
  bool get isLocked => rules.locked;
  bool get isOneWayOut => rules.oneWayOut;
  bool get isOneWayIn => rules.oneWayIn;
  bool get hasAcceptedColors => rules.acceptedColors.isNotEmpty;

  bool acceptsColor(String groupKey) {
    if (!hasAcceptedColors) {
      return true;
    }
    return rules.acceptedColors.contains(groupKey);
  }

  SortContainer copyWith({
    String? id,
    int? capacity,
    List<SortPiece>? pieces,
    SortContainerRules? rules,
  }) {
    return SortContainer(
      id: id ?? this.id,
      capacity: capacity ?? this.capacity,
      pieces: pieces ?? this.pieces,
      rules: rules ?? this.rules,
    );
  }

  bool isUniform() {
    if (pieces.isEmpty) {
      return true;
    }
    final String group = pieces.first.groupKey;
    return pieces.every((SortPiece piece) => piece.groupKey == group);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'capacity': capacity,
    'pieces': pieces.map((e) => e.toJson()).toList(growable: false),
    'rules': rules.toJson(),
  };

  factory SortContainer.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPieces = json['pieces'] as List<dynamic>? ?? const <dynamic>[];
    return SortContainer(
      id: json['id'] as String,
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      pieces: rawPieces
          .map((dynamic item) => SortPiece.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      rules: SortContainerRules.fromJson(
        json['rules'] as Map<String, dynamic>?,
      ),
    );
  }
}