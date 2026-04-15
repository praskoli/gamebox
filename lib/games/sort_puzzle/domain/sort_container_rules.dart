class SortContainerRules {
  const SortContainerRules({
    this.locked = false,
    this.oneWayOut = false,
    this.oneWayIn = false,
    this.acceptedColors = const <String>[],
    this.customCapacity,
    this.label,
  });

  final bool locked;
  final bool oneWayOut;
  final bool oneWayIn;
  final List<String> acceptedColors;
  final int? customCapacity;
  final String? label;

  bool get hasRestrictions =>
      locked || oneWayOut || oneWayIn || acceptedColors.isNotEmpty || customCapacity != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'locked': locked,
    'oneWayOut': oneWayOut,
    'oneWayIn': oneWayIn,
    'acceptedColors': acceptedColors,
    if (customCapacity != null) 'customCapacity': customCapacity,
    if (label != null) 'label': label,
  };

  factory SortContainerRules.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SortContainerRules();
    }

    return SortContainerRules(
      locked: json['locked'] as bool? ?? false,
      oneWayOut: json['oneWayOut'] as bool? ?? false,
      oneWayIn: json['oneWayIn'] as bool? ?? false,
      acceptedColors: (json['acceptedColors'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(growable: false),
      customCapacity: (json['customCapacity'] as num?)?.toInt(),
      label: json['label'] as String?,
    );
  }

  SortContainerRules copyWith({
    bool? locked,
    bool? oneWayOut,
    bool? oneWayIn,
    List<String>? acceptedColors,
    int? customCapacity,
    String? label,
  }) {
    return SortContainerRules(
      locked: locked ?? this.locked,
      oneWayOut: oneWayOut ?? this.oneWayOut,
      oneWayIn: oneWayIn ?? this.oneWayIn,
      acceptedColors: acceptedColors ?? this.acceptedColors,
      customCapacity: customCapacity ?? this.customCapacity,
      label: label ?? this.label,
    );
  }
}