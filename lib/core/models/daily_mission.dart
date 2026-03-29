class DailyMission {
  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.progress,
    required this.rewardCoins,
    required this.rewardXp,
  });

  final String id;
  final String title;
  final String description;
  final int target;
  final int progress;
  final int rewardCoins;
  final int rewardXp;

  bool get isCompleted => progress >= target;

  double get progressValue {
    if (target <= 0) return 0;
    final value = progress / target;
    return value.clamp(0, 1);
  }

  DailyMission copyWith({
    String? id,
    String? title,
    String? description,
    int? target,
    int? progress,
    int? rewardCoins,
    int? rewardXp,
  }) {
    return DailyMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      rewardCoins: rewardCoins ?? this.rewardCoins,
      rewardXp: rewardXp ?? this.rewardXp,
    );
  }
}