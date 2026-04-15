class SortAssetCatalog {
  const SortAssetCatalog._();

  static const Map<String, String> backgrounds = <String, String>{
    'color_classic': 'assets/images/sort_puzzle/backgrounds/color_classic.png',
    'ball_neon': 'assets/images/sort_puzzle/backgrounds/ball_neon.png',
    'water_lab': 'assets/images/sort_puzzle/backgrounds/water_lab.png',
    'sand_desert': 'assets/images/sort_puzzle/backgrounds/sand_desert.png',
    'bird_forest': 'assets/images/sort_puzzle/backgrounds/bird_forest.png',
  };

  static const Map<String, String> containerSkins = <String, String>{
    'tube_glass': 'assets/images/sort_puzzle/containers/tube_glass.png',
    'tube_neon': 'assets/images/sort_puzzle/containers/tube_neon.png',
    'bottle_water': 'assets/images/sort_puzzle/containers/bottle_water.png',
    'bottle_sand': 'assets/images/sort_puzzle/containers/bottle_sand.png',
    'branch_classic': 'assets/images/sort_puzzle/containers/branch_classic.png',
  };

  static const Map<String, String> pieceSkins = <String, String>{
    'color_flat': 'assets/images/sort_puzzle/pieces/color_flat/',
    'ball_glossy': 'assets/images/sort_puzzle/pieces/ball_glossy/',
    'water_liquid': 'assets/images/sort_puzzle/pieces/water_liquid/',
    'sand_texture': 'assets/images/sort_puzzle/pieces/sand_texture/',
    'bird_cartoon': 'assets/images/sort_puzzle/pieces/bird_cartoon/',
  };

  static const Map<String, Map<String, String>> soundPacks = <String, Map<String, String>>{
    'default_sort': <String, String>{
      'start': 'assets/sounds/gameStart.mp3',
      'success': 'assets/sounds/blockPlace.mp3',
      'error': 'assets/sounds/error.mp3',
    },
  };
}