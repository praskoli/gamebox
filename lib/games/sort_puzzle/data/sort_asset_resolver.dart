import 'sort_asset_catalog.dart';

class SortAssetResolver {
  const SortAssetResolver();

  String? resolveBackground(String key) {
    return SortAssetCatalog.backgrounds[key];
  }

  String? resolveContainerSkin(String key) {
    return SortAssetCatalog.containerSkins[key];
  }

  String? resolvePieceSkin(String key) {
    return SortAssetCatalog.pieceSkins[key];
  }

  Map<String, String> resolveSoundPack(String key) {
    return SortAssetCatalog.soundPacks[key] ?? SortAssetCatalog.soundPacks['default_sort']!;
  }
}