class SortPiece {
  const SortPiece({
    required this.groupKey,
    this.amount = 1,
    this.assetKey,
  });

  final String groupKey;
  final int amount;
  final String? assetKey;

  SortPiece copyWith({
    String? groupKey,
    int? amount,
    String? assetKey,
  }) {
    return SortPiece(
      groupKey: groupKey ?? this.groupKey,
      amount: amount ?? this.amount,
      assetKey: assetKey ?? this.assetKey,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'groupKey': groupKey,
        'amount': amount,
        if (assetKey != null) 'assetKey': assetKey,
      };

  factory SortPiece.fromJson(Map<String, dynamic> json) {
    return SortPiece(
      groupKey: json['groupKey'] as String,
      amount: (json['amount'] as num?)?.toInt() ?? 1,
      assetKey: json['assetKey'] as String?,
    );
  }
}
