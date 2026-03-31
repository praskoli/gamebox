import '../../app/models/app_mode.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.loginEmail,
    required this.approvalEmail,
    required this.temporaryEmail,
    required this.mobileNumber,
    required this.photoUrl,
    required this.provider,
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
  final String email; // auth provider email
  final String loginEmail; // guest recovery / future login email
  final String approvalEmail; // primary parent approval email
  final String temporaryEmail; // optional override for current OTP flow
  final String mobileNumber;
  final String photoUrl;
  final String provider;
  final AppMode currentMode;
  final int coins;
  final int xp;
  final int level;
  final int streakDays;
  final int gamesPlayed;
  final DateTime? dailyRewardClaimedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasAnyApprovalEmail =>
      temporaryEmail.trim().isNotEmpty ||
          approvalEmail.trim().isNotEmpty ||
          loginEmail.trim().isNotEmpty ||
          email.trim().isNotEmpty;

  String get preferredOtpDestination {
    if (temporaryEmail.trim().isNotEmpty) return temporaryEmail.trim();
    if (approvalEmail.trim().isNotEmpty) return approvalEmail.trim();
    if (loginEmail.trim().isNotEmpty) return loginEmail.trim();
    return email.trim();
  }

  PlayerProfile copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? loginEmail,
    String? approvalEmail,
    String? temporaryEmail,
    String? mobileNumber,
    String? photoUrl,
    String? provider,
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
      loginEmail: loginEmail ?? this.loginEmail,
      approvalEmail: approvalEmail ?? this.approvalEmail,
      temporaryEmail: temporaryEmail ?? this.temporaryEmail,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
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
      'loginEmail': loginEmail,
      'approvalEmail': approvalEmail,
      'temporaryEmail': temporaryEmail,
      'mobileNumber': mobileNumber,
      'photoUrl': photoUrl,
      'provider': provider,
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
      loginEmail: (map['loginEmail'] ?? '').toString(),
      approvalEmail: (map['approvalEmail'] ?? '').toString(),
      temporaryEmail: (map['temporaryEmail'] ?? '').toString(),
      mobileNumber: (map['mobileNumber'] ?? '').toString(),
      photoUrl: (map['photoUrl'] ?? '').toString(),
      provider: (map['provider'] ?? '').toString(),
      currentMode: AppModeX.fromKey(map['currentMode']?.toString()),
      coins: (map['coins'] as num?)?.toInt() ?? 0,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 1,
      gamesPlayed: (map['gamesPlayed'] as num?)?.toInt() ?? 0,
      dailyRewardClaimedAt: map['dailyRewardClaimedAt'] == null
          ? null
          : DateTime.tryParse(map['dailyRewardClaimedAt'].toString()),
      createdAt:
      DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? DateTime.now(),
      updatedAt:
      DateTime.tryParse((map['updatedAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}