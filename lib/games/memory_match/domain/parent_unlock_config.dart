class ParentUnlockConfig {
  const ParentUnlockConfig({
    required this.enabled,
    required this.mode,
    required this.parentPin,
    required this.tokensPerApproval,
    required this.pinRequiredForParentActions,
  });

  final bool enabled;
  final String mode;
  final String parentPin;
  final int tokensPerApproval;
  final bool pinRequiredForParentActions;

  factory ParentUnlockConfig.initial() {
    return const ParentUnlockConfig(
      enabled: false,
      mode: 'token',
      parentPin: '1234',
      tokensPerApproval: 1,
      pinRequiredForParentActions: true,
    );
  }

  factory ParentUnlockConfig.fromMap(Map<String, dynamic> map) {
    return ParentUnlockConfig(
      enabled: map['enabled'] == true,
      mode: (map['mode'] ?? 'token').toString(),
      parentPin: (map['parentPin'] ?? '1234').toString(),
      tokensPerApproval: _toInt(map['tokensPerApproval'], 1).clamp(1, 20),
      pinRequiredForParentActions: map['pinRequiredForParentActions'] != false,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enabled': enabled,
      'mode': mode,
      'parentPin': parentPin,
      'tokensPerApproval': tokensPerApproval,
      'pinRequiredForParentActions': pinRequiredForParentActions,
    };
  }

  ParentUnlockConfig copyWith({
    bool? enabled,
    String? mode,
    String? parentPin,
    int? tokensPerApproval,
    bool? pinRequiredForParentActions,
  }) {
    return ParentUnlockConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      parentPin: parentPin ?? this.parentPin,
      tokensPerApproval: tokensPerApproval ?? this.tokensPerApproval,
      pinRequiredForParentActions:
      pinRequiredForParentActions ?? this.pinRequiredForParentActions,
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}