import 'dart:collection';

class MemoryWorldConfig {
  const MemoryWorldConfig({
    required this.id,
    required this.title,
    required this.worldTitle,
    required this.emoji,
    required this.worldGradientHex,
    required this.tileGradientHex,
    required this.tileAccentHex,
    required this.glowColorHex,
    required this.itemPool,
    required this.mixedSourceWorldIds,
    required this.maxUniqueItems,
    required this.enabled,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String worldTitle;
  final String emoji;
  final List<String> worldGradientHex;
  final List<String> tileGradientHex;
  final String tileAccentHex;
  final String glowColorHex;
  final List<String> itemPool;
  final List<String> mixedSourceWorldIds;
  final int maxUniqueItems;
  final bool enabled;
  final int sortOrder;

  bool get isMixed => mixedSourceWorldIds.isNotEmpty;

  factory MemoryWorldConfig.fromMap(Map<String, dynamic> map) {
    return MemoryWorldConfig(
      id: (map['id'] ?? '').toString().trim(),
      title: (map['title'] ?? '').toString().trim(),
      worldTitle: (map['worldTitle'] ?? '').toString().trim(),
      emoji: (map['emoji'] ?? '🧠').toString(),
      worldGradientHex: _stringList(map['worldGradientHex']),
      tileGradientHex: _stringList(map['tileGradientHex']),
      tileAccentHex: (map['tileAccentHex'] ?? '#1976D2').toString(),
      glowColorHex: (map['glowColorHex'] ?? '#661976D2').toString(),
      itemPool: _stringList(map['itemPool']),
      mixedSourceWorldIds: _stringList(map['mixedSourceWorldIds']),
      maxUniqueItems: _toInt(map['maxUniqueItems'], fallback: 64),
      enabled: _toBool(map['enabled'], fallback: true),
      sortOrder: _toInt(map['sortOrder'], fallback: 999),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'worldTitle': worldTitle,
      'emoji': emoji,
      'worldGradientHex': worldGradientHex,
      'tileGradientHex': tileGradientHex,
      'tileAccentHex': tileAccentHex,
      'glowColorHex': glowColorHex,
      'itemPool': itemPool,
      'mixedSourceWorldIds': mixedSourceWorldIds,
      'maxUniqueItems': maxUniqueItems,
      'enabled': enabled,
      'sortOrder': sortOrder,
    };
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _toBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    final lower = value?.toString().toLowerCase().trim();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
    return fallback;
  }

  List<String> resolveCombinedItemPool(Map<String, MemoryWorldConfig> worldById) {
    final LinkedHashSet<String> combined = LinkedHashSet<String>();

    for (final item in itemPool) {
      if (item.trim().isNotEmpty) {
        combined.add(item.trim());
      }
    }

    for (final sourceWorldId in mixedSourceWorldIds) {
      final source = worldById[sourceWorldId];
      if (source == null) continue;
      for (final item in source.itemPool) {
        if (item.trim().isNotEmpty) {
          combined.add(item.trim());
        }
      }
    }

    final List<String> resolved = combined.toList(growable: false);
    final int safeLimit = maxUniqueItems <= 0 ? resolved.length : maxUniqueItems;
    return resolved.take(safeLimit).toList(growable: false);
  }
}