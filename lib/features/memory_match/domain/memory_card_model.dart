class MemoryCardModel {
  const MemoryCardModel({
    required this.id,
    required this.value,
    required this.isFaceUp,
    required this.isMatched,
  });

  final String id;
  final String value;
  final bool isFaceUp;
  final bool isMatched;

  MemoryCardModel copyWith({
    String? id,
    String? value,
    bool? isFaceUp,
    bool? isMatched,
  }) {
    return MemoryCardModel(
      id: id ?? this.id,
      value: value ?? this.value,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}