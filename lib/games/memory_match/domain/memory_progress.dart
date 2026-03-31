class MemoryProgress {
  const MemoryProgress({
    required this.worldId,
    required this.unlockedLevel,
    required this.bestScores,
    required this.starsByLevel,
    required this.completedLevels,
  });

  final String worldId;
  final int unlockedLevel;
  final Map<int, int> bestScores;
  final Map<int, int> starsByLevel;
  final List<int> completedLevels;

  MemoryProgress copyWith({
    String? worldId,
    int? unlockedLevel,
    Map<int, int>? bestScores,
    Map<int, int>? starsByLevel,
    List<int>? completedLevels,
  }) {
    return MemoryProgress(
      worldId: worldId ?? this.worldId,
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      bestScores: bestScores ?? this.bestScores,
      starsByLevel: starsByLevel ?? this.starsByLevel,
      completedLevels: completedLevels ?? this.completedLevels,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'worldId': worldId,
      'unlockedLevel': unlockedLevel,
      'bestScores': bestScores.map((k, v) => MapEntry(k.toString(), v)),
      'starsByLevel': starsByLevel.map((k, v) => MapEntry(k.toString(), v)),
      'completedLevels': completedLevels,
    };
  }

  factory MemoryProgress.fromMap(Map<String, dynamic> map) {
    Map<int, int> parseIntMap(dynamic raw) {
      if (raw is! Map) return const <int, int>{};

      final result = <int, int>{};
      for (final entry in raw.entries) {
        final key = int.tryParse(entry.key.toString());
        final value = (entry.value as num?)?.toInt();
        if (key != null && value != null) {
          result[key] = value;
        }
      }
      return result;
    }

    List<int> parseCompletedLevels(dynamic raw) {
      if (raw is! List) return const <int>[];

      final values = <int>[];
      for (final item in raw) {
        final value = (item as num?)?.toInt();
        if (value != null) {
          values.add(value);
        }
      }

      final uniqueSorted = values.toSet().toList()..sort();
      return uniqueSorted;
    }

    return MemoryProgress(
      worldId: (map['worldId'] ?? '').toString(),
      unlockedLevel: (map['unlockedLevel'] as num?)?.toInt() ?? 1,
      bestScores: parseIntMap(map['bestScores']),
      starsByLevel: parseIntMap(map['starsByLevel']),
      completedLevels: parseCompletedLevels(map['completedLevels']),
    );
  }

  factory MemoryProgress.initial(String worldId) {
    return MemoryProgress(
      worldId: worldId,
      unlockedLevel: 1,
      bestScores: const <int, int>{},
      starsByLevel: const <int, int>{},
      completedLevels: const <int>[],
    );
  }
}