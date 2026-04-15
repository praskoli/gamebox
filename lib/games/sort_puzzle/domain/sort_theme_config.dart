class SortThemeConfig {
  const SortThemeConfig({
    required this.themeKey,
    required this.backgroundKey,
    required this.containerSkinKey,
    required this.pieceSkinKey,
    required this.soundPackKey,
    this.accentColorKey,
  });

  final String themeKey;
  final String backgroundKey;
  final String containerSkinKey;
  final String pieceSkinKey;
  final String soundPackKey;
  final String? accentColorKey;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'themeKey': themeKey,
    'backgroundKey': backgroundKey,
    'containerSkinKey': containerSkinKey,
    'pieceSkinKey': pieceSkinKey,
    'soundPackKey': soundPackKey,
    if (accentColorKey != null) 'accentColorKey': accentColorKey,
  };

  factory SortThemeConfig.fromJson(Map<String, dynamic>? json, {String fallbackThemeKey = 'default'}) {
    final Map<String, dynamic> safe = json ?? const <String, dynamic>{};

    return SortThemeConfig(
      themeKey: (safe['themeKey'] as String?) ?? fallbackThemeKey,
      backgroundKey: (safe['backgroundKey'] as String?) ?? fallbackThemeKey,
      containerSkinKey: (safe['containerSkinKey'] as String?) ?? fallbackThemeKey,
      pieceSkinKey: (safe['pieceSkinKey'] as String?) ?? fallbackThemeKey,
      soundPackKey: (safe['soundPackKey'] as String?) ?? 'default_sort',
      accentColorKey: safe['accentColorKey'] as String?,
    );
  }
}