class GamePlayerStats {
  final String gameId;
  final int gamesPlayed;
  final int totalXp;
  final int totalCoins;
  final int highestLevel;
  final int bestScore;
  final DateTime? lastPlayedAt;

  const GamePlayerStats({
    required this.gameId,
    required this.gamesPlayed,
    required this.totalXp,
    required this.totalCoins,
    required this.highestLevel,
    required this.bestScore,
    required this.lastPlayedAt,
  });

  factory GamePlayerStats.empty(String gameId) {
    return GamePlayerStats(
      gameId: gameId,
      gamesPlayed: 0,
      totalXp: 0,
      totalCoins: 0,
      highestLevel: 0,
      bestScore: 0,
      lastPlayedAt: null,
    );
  }

  GamePlayerStats copyWith({
    String? gameId,
    int? gamesPlayed,
    int? totalXp,
    int? totalCoins,
    int? highestLevel,
    int? bestScore,
    DateTime? lastPlayedAt,
  }) {
    return GamePlayerStats(
      gameId: gameId ?? this.gameId,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalXp: totalXp ?? this.totalXp,
      totalCoins: totalCoins ?? this.totalCoins,
      highestLevel: highestLevel ?? this.highestLevel,
      bestScore: bestScore ?? this.bestScore,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameId': gameId,
      'gamesPlayed': gamesPlayed,
      'totalXp': totalXp,
      'totalCoins': totalCoins,
      'highestLevel': highestLevel,
      'bestScore': bestScore,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
    };
  }

  factory GamePlayerStats.fromMap(String gameId, Map<String, dynamic>? map) {
    if (map == null) return GamePlayerStats.empty(gameId);

    return GamePlayerStats(
      gameId: (map['gameId'] ?? gameId).toString(),
      gamesPlayed: (map['gamesPlayed'] as num?)?.toInt() ?? 0,
      totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
      totalCoins: (map['totalCoins'] as num?)?.toInt() ?? 0,
      highestLevel: (map['highestLevel'] as num?)?.toInt() ?? 0,
      bestScore: (map['bestScore'] as num?)?.toInt() ?? 0,
      lastPlayedAt: map['lastPlayedAt'] == null
          ? null
          : DateTime.tryParse(map['lastPlayedAt'].toString()),
    );
  }
}