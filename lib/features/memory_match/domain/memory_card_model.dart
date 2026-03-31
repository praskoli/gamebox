// lib/features/memory_match/domain/memory_card_model.dart
class MemoryCardModel {
  const MemoryCardModel({
    required this.id,
    required this.value,
    required this.themeId,
    this.isFaceUp = false,
    this.isMatched = false,
    this.isLocked = false,
  });

  final String id;
  final String value;
  final String themeId;
  final bool isFaceUp;
  final bool isMatched;
  final bool isLocked;

  MemoryCardModel copyWith({
    String? id,
    String? value,
    String? themeId,
    bool? isFaceUp,
    bool? isMatched,
    bool? isLocked,
  }) {
    return MemoryCardModel(
      id: id ?? this.id,
      value: value ?? this.value,
      themeId: themeId ?? this.themeId,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}