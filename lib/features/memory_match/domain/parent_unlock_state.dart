class ParentUnlockState {
  const ParentUnlockState({
    required this.tokensRemaining,
    required this.sessionActive,
    required this.sessionEndEpochMs,
  });

  final int tokensRemaining;
  final bool sessionActive;
  final int sessionEndEpochMs;

  factory ParentUnlockState.initial() {
    return const ParentUnlockState(
      tokensRemaining: 0,
      sessionActive: false,
      sessionEndEpochMs: 0,
    );
  }

  factory ParentUnlockState.fromMap(Map<String, dynamic> map) {
    return ParentUnlockState(
      tokensRemaining: _toInt(map['tokensRemaining'], 0).clamp(0, 9999),
      sessionActive: map['sessionActive'] == true,
      sessionEndEpochMs: _toInt(map['sessionEndEpochMs'], 0),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tokensRemaining': tokensRemaining,
      'sessionActive': sessionActive,
      'sessionEndEpochMs': sessionEndEpochMs,
    };
  }

  ParentUnlockState copyWith({
    int? tokensRemaining,
    bool? sessionActive,
    int? sessionEndEpochMs,
  }) {
    return ParentUnlockState(
      tokensRemaining: tokensRemaining ?? this.tokensRemaining,
      sessionActive: sessionActive ?? this.sessionActive,
      sessionEndEpochMs: sessionEndEpochMs ?? this.sessionEndEpochMs,
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}