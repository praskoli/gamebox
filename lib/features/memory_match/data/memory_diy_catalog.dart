import '../../../games/memory_match/domain/memory_diy_game_config.dart';

class MemoryDiyCategory {
  const MemoryDiyCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.baseWorldId,
    required this.items,
    this.isMixed = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final String baseWorldId;
  final List<String> items;
  final bool isMixed;
}

class MemoryDiyCatalog {
  MemoryDiyCatalog._();

  static const List<MemoryDiyCategory> categories = <MemoryDiyCategory>[
    MemoryDiyCategory(
      id: 'fruits',
      title: 'Fruit Memory',
      subtitle: 'Fresh fruit pairs',
      baseWorldId: 'fruits',
      items: <String>[
        '🍎', '🍌', '🍇', '🍓', '🍉', '🍍', '🥭', '🍒', '🍊', '🥝', '🍐', '🍋',
      ],
    ),
    MemoryDiyCategory(
      id: 'vehicles',
      title: 'Vehicle Memory',
      subtitle: 'Cars, trucks and travel',
      baseWorldId: 'vehicles',
      items: <String>[
        '🚗', '🚕', '🚙', '🚌', '🚓', '🚑', '🚒', '🚜', '🚛', '🛵', '🚲', '✈️',
      ],
    ),
    MemoryDiyCategory(
      id: 'ocean',
      title: 'Ocean Memory',
      subtitle: 'Sea life pairs',
      baseWorldId: 'animals',
      items: <String>[
        '🐠', '🐟', '🐡', '🐬', '🐳', '🐙', '🦀', '🦑', '🐢', '🪼', '⭐', '🦈',
      ],
    ),
    MemoryDiyCategory(
      id: 'animals',
      title: 'Animal Memory',
      subtitle: 'Animal friends and wild pairs',
      baseWorldId: 'animals',
      items: <String>[
        '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐯', '🦁', '🐸', '🐨',
      ],
    ),
    MemoryDiyCategory(
      id: 'birds',
      title: 'Bird Memory',
      subtitle: 'Flying and feathered pairs',
      baseWorldId: 'animals',
      items: <String>[
        '🐦', '🦜', '🦢', '🦆', '🦉', '🦩', '🕊️', '🐓', '🦅', '🐧', '🪶', '🥚',
      ],
    ),
    MemoryDiyCategory(
      id: 'insects',
      title: 'Insect Memory',
      subtitle: 'Bug and wing friends',
      baseWorldId: 'animals',
      items: <String>[
        '🐞', '🐌', '🦋', '🐝', '🐜', '🪲', '🕷️', '🐛', '🦗', '🪰', '🪳', '🪱',
      ],
    ),
    MemoryDiyCategory(
      id: 'food',
      title: 'Food Memory',
      subtitle: 'Tasty food pairs',
      baseWorldId: 'fruits',
      items: <String>[
        '🍔', '🌭', '🍕', '🍟', '🌮', '🍿', '🍩', '🍪', '🧁', '🍦', '🥪', '🍰',
      ],
    ),
    MemoryDiyCategory(
      id: 'kitchen',
      title: 'Kitchen Memory',
      subtitle: 'Home and kitchen items',
      baseWorldId: 'fruits',
      items: <String>[
        '🫖', '🍳', '🍽️', '🥄', '🍴', '🔪', '🫙', '🥣', '🧂', '🫗', '🥤', '☕',
      ],
    ),
    MemoryDiyCategory(
      id: 'toys',
      title: 'Toy Memory',
      subtitle: 'Play room pairs',
      baseWorldId: 'vehicles',
      items: <String>[
        '🧸', '🪀', '🚂', '🪁', '⚽', '🎈', '🛹', '🎲', '🎮', '🧩', '🪅', '🎯',
      ],
    ),
    MemoryDiyCategory(
      id: 'shapes',
      title: 'Shape Memory',
      subtitle: 'Colorful shape pairs',
      baseWorldId: 'fruits',
      items: <String>[
        '🔺', '🟪', '🔵', '🟡', '🔶', '🔷', '🟥', '🟩', '🟧', '🟦', '⚪', '⚫',
      ],
    ),
    MemoryDiyCategory(
      id: 'space',
      title: 'Space Memory',
      subtitle: 'Galaxy and planet pairs',
      baseWorldId: 'mixed_all',
      isMixed: true,
      items: <String>[
        '🚀', '🪐', '🌙', '⭐', '☄️', '🛸', '👽', '🌍', '🌞', '🛰️', '🌠', '🔭',
      ],
    ),
    MemoryDiyCategory(
      id: 'farm',
      title: 'Farm Memory',
      subtitle: 'Farm life pairs',
      baseWorldId: 'animals',
      items: <String>[
        '🐄', '🐑', '🐖', '🐓', '🐇', '🦆', '🐐', '🐎', '🐕', '🐈', '🌽', '🚜',
      ],
    ),
    MemoryDiyCategory(
      id: 'sports',
      title: 'Sports Memory',
      subtitle: 'Active play and sports gear',
      baseWorldId: 'mixed_all',
      isMixed: true,
      items: <String>[
        '⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏓', '🥊', '⛳', '🏸', '🥅', '🏆',
      ],
    ),
    MemoryDiyCategory(
      id: 'nature',
      title: 'Nature Memory',
      subtitle: 'Trees, leaves and outdoor beauty',
      baseWorldId: 'mixed_all',
      isMixed: true,
      items: <String>[
        '🌳', '🌲', '🌴', '🌵', '🍄', '🌸', '🌼', '🌻', '🍁', '🍂', '🌈', '☀️',
      ],
    ),
    MemoryDiyCategory(
      id: 'festival',
      title: 'Festival Memory',
      subtitle: 'Lights, gifts and celebration fun',
      baseWorldId: 'mixed_all',
      isMixed: true,
      items: <String>[
        '🎉', '🎊', '🎁', '🪔', '🕯️', '🎆', '🎇', '🥳', '🍬', '🎶', '🪅', '✨',
      ],
    ),
    MemoryDiyCategory(
      id: 'mixed_fun',
      title: 'Mixed Fun',
      subtitle: 'A cheerful mixed set',
      baseWorldId: 'mixed_all',
      isMixed: true,
      items: <String>[
        '🍎', '🚗', '🐠', '🧸', '🚀', '🦋', '🍔', '🔺', '☕', '⚽', '🌙', '🚂',
      ],
    ),
    MemoryDiyCategory(
      id: 'mixed_transport',
      title: 'Mixed Transport',
      subtitle: 'Land, air and fun travel',
      baseWorldId: 'mixed_all',
      isMixed: true,
      items: <String>[
        '🚗', '🚕', '🚙', '🚌', '🚜', '🚛', '🛵', '🚲', '✈️', '🚀', '🚂', '🛸',
      ],
    ),
    MemoryDiyCategory(
      id: 'mixed_world',
      title: 'Mixed World',
      subtitle: 'Best of many worlds together',
      baseWorldId: 'mixed_all',
      isMixed: true,
      items: <String>[
        '🍎', '🐶', '🚗', '🌙', '⚽', '🧸', '🍕', '🐠', '🌸', '🚀', '🎉', '☕',
      ],
    ),
  ];

  static MemoryDiyCategory byId(String id) {
    return categories.firstWhere(
          (MemoryDiyCategory e) => e.id == id,
      orElse: () => categories.first,
    );
  }

  static List<String> itemsForCategory({
    required String categoryId,
    required int pairCount,
  }) {
    final MemoryDiyCategory category = byId(categoryId);
    final List<String> source = List<String>.from(category.items);

    if (pairCount <= source.length) {
      return source.take(pairCount).toList(growable: false);
    }

    final List<String> expanded = <String>[];
    while (expanded.length < pairCount) {
      expanded.addAll(source);
    }
    return expanded.take(pairCount).toList(growable: false);
  }

  static MemoryDiyGameConfig createDefaultConfig({
    required String ownerUid,
  }) {
    final MemoryDiyCategory category = categories.first;
    return MemoryDiyGameConfig(
      id: '',
      title: category.title,
      categoryId: category.id,
      baseWorldId: category.baseWorldId,
      gridColumns: 4,
      gridRows: 4,
      previewDurationMs: 1200,
      flipBackDelayMs: 650,
      items: itemsForCategory(
        categoryId: category.id,
        pairCount: 8,
      ),
      levelNumber: 1,
      ownerUid: ownerUid,
      createdAt: null,
      updatedAt: null,
      isMixedCategory: category.isMixed,
      status: 'draft',
      submittedAt: null,
      reviewedAt: null,
      reviewedBy: '',
      rejectionReason: '',
    );
  }
}