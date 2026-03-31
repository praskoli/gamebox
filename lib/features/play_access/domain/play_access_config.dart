class PlayAccessConfig {
  const PlayAccessConfig({
    required this.enabled,
    required this.dailyFreeMinutes,
    required this.dailyFreeLevels,
    required this.approvalGrantMinutes,
    required this.approvalGrantLevels,
    required this.warningBeforeMinutes,
    required this.warningBeforeLevels,
    required this.maxApprovalsPerDay,
    required this.primaryParentPhone,
    required this.secondaryParentPhone,
    required this.parentEmail,
    required this.preferredApprovalChannel,
    required this.fallbackToLoginEmail,
  });

  final bool enabled;
  final int dailyFreeMinutes;
  final int dailyFreeLevels;
  final int approvalGrantMinutes;
  final int approvalGrantLevels;
  final int warningBeforeMinutes;
  final int warningBeforeLevels;
  final int maxApprovalsPerDay;
  final String primaryParentPhone;
  final String secondaryParentPhone;
  final String parentEmail;
  final String preferredApprovalChannel;
  final bool fallbackToLoginEmail;

  factory PlayAccessConfig.initial() {
    return const PlayAccessConfig(
      enabled: true,
      dailyFreeMinutes: 60,
      dailyFreeLevels: 10,
      approvalGrantMinutes: 30,
      approvalGrantLevels: 5,
      warningBeforeMinutes: 5,
      warningBeforeLevels: 1,
      maxApprovalsPerDay: 3,
      primaryParentPhone: '',
      secondaryParentPhone: '',
      parentEmail: '',
      preferredApprovalChannel: 'email',
      fallbackToLoginEmail: true,
    );
  }

  factory PlayAccessConfig.fromMap(Map<String, dynamic> map) {
    return PlayAccessConfig(
      enabled: map['enabled'] != false,
      dailyFreeMinutes: _toInt(map['dailyFreeMinutes'], 60).clamp(1, 720),
      dailyFreeLevels: _toInt(map['dailyFreeLevels'], 10).clamp(1, 500),
      approvalGrantMinutes:
      _toInt(map['approvalGrantMinutes'], 30).clamp(1, 240),
      approvalGrantLevels:
      _toInt(map['approvalGrantLevels'], 5).clamp(1, 100),
      warningBeforeMinutes:
      _toInt(map['warningBeforeMinutes'], 5).clamp(0, 120),
      warningBeforeLevels:
      _toInt(map['warningBeforeLevels'], 1).clamp(0, 50),
      maxApprovalsPerDay:
      _toInt(map['maxApprovalsPerDay'], 3).clamp(0, 20),
      primaryParentPhone: (map['primaryParentPhone'] ?? '').toString().trim(),
      secondaryParentPhone:
      (map['secondaryParentPhone'] ?? '').toString().trim(),
      parentEmail: (map['parentEmail'] ?? '').toString().trim(),
      preferredApprovalChannel:
      (map['preferredApprovalChannel'] ?? 'whatsapp')
          .toString()
          .trim()
          .toLowerCase(),
      fallbackToLoginEmail: map['fallbackToLoginEmail'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'dailyFreeMinutes': dailyFreeMinutes,
      'dailyFreeLevels': dailyFreeLevels,
      'approvalGrantMinutes': approvalGrantMinutes,
      'approvalGrantLevels': approvalGrantLevels,
      'warningBeforeMinutes': warningBeforeMinutes,
      'warningBeforeLevels': warningBeforeLevels,
      'maxApprovalsPerDay': maxApprovalsPerDay,
      'primaryParentPhone': primaryParentPhone,
      'secondaryParentPhone': secondaryParentPhone,
      'parentEmail': parentEmail,
      'preferredApprovalChannel': preferredApprovalChannel,
      'fallbackToLoginEmail': fallbackToLoginEmail,
    };
  }

  PlayAccessConfig copyWith({
    bool? enabled,
    int? dailyFreeMinutes,
    int? dailyFreeLevels,
    int? approvalGrantMinutes,
    int? approvalGrantLevels,
    int? warningBeforeMinutes,
    int? warningBeforeLevels,
    int? maxApprovalsPerDay,
    String? primaryParentPhone,
    String? secondaryParentPhone,
    String? parentEmail,
    String? preferredApprovalChannel,
    bool? fallbackToLoginEmail,
  }) {
    return PlayAccessConfig(
      enabled: enabled ?? this.enabled,
      dailyFreeMinutes: dailyFreeMinutes ?? this.dailyFreeMinutes,
      dailyFreeLevels: dailyFreeLevels ?? this.dailyFreeLevels,
      approvalGrantMinutes: approvalGrantMinutes ?? this.approvalGrantMinutes,
      approvalGrantLevels: approvalGrantLevels ?? this.approvalGrantLevels,
      warningBeforeMinutes: warningBeforeMinutes ?? this.warningBeforeMinutes,
      warningBeforeLevels: warningBeforeLevels ?? this.warningBeforeLevels,
      maxApprovalsPerDay: maxApprovalsPerDay ?? this.maxApprovalsPerDay,
      primaryParentPhone: primaryParentPhone ?? this.primaryParentPhone,
      secondaryParentPhone: secondaryParentPhone ?? this.secondaryParentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      preferredApprovalChannel:
      preferredApprovalChannel ?? this.preferredApprovalChannel,
      fallbackToLoginEmail: fallbackToLoginEmail ?? this.fallbackToLoginEmail,
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}