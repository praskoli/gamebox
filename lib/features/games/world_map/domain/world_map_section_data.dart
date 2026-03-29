import 'world_map_section_theme.dart';

class WorldMapSectionData {
  const WorldMapSectionData({
    required this.sectionIndex,
    required this.startLevel,
    required this.endLevel,
    required this.top,
    required this.height,
    required this.theme,
  });

  final int sectionIndex;
  final int startLevel;
  final int endLevel;
  final double top;
  final double height;
  final WorldMapSectionTheme theme;
}