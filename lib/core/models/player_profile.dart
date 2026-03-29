import '../enums/app_mode.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.currentMode,
    required this.coins,
    required this.xp,
    required this.level,
    required this.streakDays,
    required this.gamesPlayed,
    required this.dailyRewardClaimedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final AppMode currentMode;
  final int coins;
  final int xp;
  final int level;
  final int streakDays;
  final int gamesPlayed;
  final DateTime? dailyRewardClaimedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlayerProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    AppMode? currentMode,
    int? coins,
    int? xp,
    int? level,
    int? streakDays,
    int? gamesPlayed,
    DateTime? dailyRewardClaimedAt,
    bool clearDailyRewardClaimedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerProfile(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      currentMode: currentMode ?? this.currentMode,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streakDays: streakDays ?? this.streakDays,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      dailyRewardClaimedAt: clearDailyRewardClaimedAt
          ? null
          : dailyRewardClaimedAt ?? this.dailyRewardClaimedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'currentMode': currentMode.key,
      'coins': coins,
      'xp': xp,
      'level': level,
      'streakDays': streakDays,
      'gamesPlayed': gamesPlayed,
      'dailyRewardClaimedAt': dailyRewardClaimedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlayerProfile.fromMap(Map<String, dynamic> map) {
    return PlayerProfile(
      uid: (map['uid'] ?? '').toString(),
      displayName: (map['displayName'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      photoUrl: (map['photoUrl'] ?? '').toString(),
      currentMode: AppModeX.fromKey(map['currentMode']?.toString()),
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 1,
      gamesPlayed: (map['gamesPlayed'] as num?)?.toInt() ?? 0,
      dailyRewardClaimedAt: map['dailyRewardClaimedAt'] == null
          ? null
          : DateTime.tryParse(map['dailyRewardClaimedAt'].toString()),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}