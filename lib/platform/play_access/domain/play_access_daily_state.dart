class PlayAccessDailyState {
  const PlayAccessDailyState({
    required this.dateKey,
    required this.activePlaySeconds,
    required this.completedLevels,
    required this.extraMinutesGranted,
    required this.extraLevelsGranted,
    required this.approvalsUsed,
    required this.lastUpdatedEpochMs,
  });

  final String dateKey;
  final int activePlaySeconds;
  final int completedLevels;
  final int extraMinutesGranted;
  final int extraLevelsGranted;
  final int approvalsUsed;
  final int lastUpdatedEpochMs;

  factory PlayAccessDailyState.initial({required String dateKey}) {
    return PlayAccessDailyState(
      dateKey: dateKey,
      activePlaySeconds: 0,
      completedLevels: 0,
      extraMinutesGranted: 0,
      extraLevelsGranted: 0,
      approvalsUsed: 0,
      lastUpdatedEpochMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory PlayAccessDailyState.fromMap(Map<String, dynamic> map) {
    return PlayAccessDailyState(
      dateKey: (map['dateKey'] ?? '').toString().trim(),
      activePlaySeconds: _toInt(map['activePlaySeconds'], 0).clamp(0, 86400),
      completedLevels: _toInt(map['completedLevels'], 0).clamp(0, 5000),
      extraMinutesGranted:
      _toInt(map['extraMinutesGranted'], 0).clamp(0, 1440),
      extraLevelsGranted: _toInt(map['extraLevelsGranted'], 0).clamp(0, 500),
      approvalsUsed: _toInt(map['approvalsUsed'], 0).clamp(0, 100),
      lastUpdatedEpochMs: _toInt(
        map['lastUpdatedEpochMs'],
        DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dateKey': dateKey,
      'activePlaySeconds': activePlaySeconds,
      'completedLevels': completedLevels,
      'extraMinutesGranted': extraMinutesGranted,
      'extraLevelsGranted': extraLevelsGranted,
      'approvalsUsed': approvalsUsed,
      'lastUpdatedEpochMs': lastUpdatedEpochMs,
    };
  }

  PlayAccessDailyState copyWith({
    String? dateKey,
    int? activePlaySeconds,
    int? completedLevels,
    int? extraMinutesGranted,
    int? extraLevelsGranted,
    int? approvalsUsed,
    int? lastUpdatedEpochMs,
  }) {
    return PlayAccessDailyState(
      dateKey: dateKey ?? this.dateKey,
      activePlaySeconds: activePlaySeconds ?? this.activePlaySeconds,
      completedLevels: completedLevels ?? this.completedLevels,
      extraMinutesGranted: extraMinutesGranted ?? this.extraMinutesGranted,
      extraLevelsGranted: extraLevelsGranted ?? this.extraLevelsGranted,
      approvalsUsed: approvalsUsed ?? this.approvalsUsed,
      lastUpdatedEpochMs: lastUpdatedEpochMs ?? this.lastUpdatedEpochMs,
    );
  }

  int totalAllowedSeconds(int freeMinutes) {
    return (freeMinutes + extraMinutesGranted) * 60;
  }

  int totalAllowedLevels(int freeLevels) {
    return freeLevels + extraLevelsGranted;
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}