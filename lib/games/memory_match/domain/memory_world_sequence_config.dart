class MemoryWorldSequenceSection {
  const MemoryWorldSequenceSection({
    required this.startLevel,
    required this.endLevel,
    required this.worldId,
  });

  final int startLevel;
  final int endLevel;
  final String worldId;

  bool contains(int levelNumber) {
    return levelNumber >= startLevel && levelNumber <= endLevel;
  }

  factory MemoryWorldSequenceSection.fromMap(Map<String, dynamic> map) {
    return MemoryWorldSequenceSection(
      startLevel: _toInt(map['startLevel'], fallback: 1),
      endLevel: _toInt(map['endLevel'], fallback: 1),
      worldId: (map['worldId'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'startLevel': startLevel,
      'endLevel': endLevel,
      'worldId': worldId,
    };
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class MemoryWorldSequenceConfig {
  const MemoryWorldSequenceConfig({
    required this.initialSections,
    required this.rotationStartLevel,
    required this.rotationWorldIds,
    required this.levelsPerWorldSection,
    required this.fallbackWorldId,
  });

  final List<MemoryWorldSequenceSection> initialSections;
  final int rotationStartLevel;
  final List<String> rotationWorldIds;
  final int levelsPerWorldSection;
  final String fallbackWorldId;

  factory MemoryWorldSequenceConfig.fromMap(Map<String, dynamic> map) {
    final List<MemoryWorldSequenceSection> sections =
    ((map['initialSections'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => MemoryWorldSequenceSection.fromMap(
      Map<String, dynamic>.from(e as Map),
    ))
        .toList(growable: false);

    final sortedSections = List<MemoryWorldSequenceSection>.from(sections)
      ..sort((a, b) => a.startLevel.compareTo(b.startLevel));

    return MemoryWorldSequenceConfig(
      initialSections: sortedSections,
      rotationStartLevel: _toInt(map['rotationStartLevel'], fallback: 31),
      rotationWorldIds: ((map['rotationWorldIds'] as List?) ?? const <dynamic>[])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
      levelsPerWorldSection:
      _toInt(map['levelsPerWorldSection'], fallback: 10).clamp(1, 1000),
      fallbackWorldId: (map['fallbackWorldId'] ?? 'fruits').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'initialSections': initialSections.map((e) => e.toMap()).toList(),
      'rotationStartLevel': rotationStartLevel,
      'rotationWorldIds': rotationWorldIds,
      'levelsPerWorldSection': levelsPerWorldSection,
      'fallbackWorldId': fallbackWorldId,
    };
  }

  String worldIdForGlobalLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;

    for (final section in initialSections) {
      if (section.contains(safeLevel) && section.worldId.isNotEmpty) {
        return section.worldId;
      }
    }

    if (rotationWorldIds.isEmpty) {
      return fallbackWorldId;
    }

    final int safeRotationStart =
    rotationStartLevel < 1 ? 1 : rotationStartLevel;

    if (safeLevel < safeRotationStart) {
      if (initialSections.isNotEmpty) {
        return initialSections.last.worldId;
      }
      return fallbackWorldId;
    }

    final int offset = safeLevel - safeRotationStart;
    final int sectionIndex = offset ~/ levelsPerWorldSection;
    return rotationWorldIds[sectionIndex % rotationWorldIds.length];
  }

  int sectionIndexForGlobalLevel(int levelNumber) {
    final int safeLevel = levelNumber < 1 ? 1 : levelNumber;

    for (int index = 0; index < initialSections.length; index++) {
      if (initialSections[index].contains(safeLevel)) {
        return index;
      }
    }

    final int safeRotationStart =
    rotationStartLevel < 1 ? 1 : rotationStartLevel;

    if (safeLevel < safeRotationStart) {
      return initialSections.isEmpty ? 0 : (initialSections.length - 1);
    }

    final int offset = safeLevel - safeRotationStart;
    return initialSections.length + (offset ~/ levelsPerWorldSection);
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}