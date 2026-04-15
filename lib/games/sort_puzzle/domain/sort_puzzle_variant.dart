enum SortPuzzleVariant { bird, ball, color, water, sand }

extension SortPuzzleVariantX on SortPuzzleVariant {
  String get id => name;

  bool get isDiscrete => this == SortPuzzleVariant.bird || this == SortPuzzleVariant.ball || this == SortPuzzleVariant.color;
  bool get isFlow => !isDiscrete;

  String get title {
    switch (this) {
      case SortPuzzleVariant.bird:
        return 'Bird Sort';
      case SortPuzzleVariant.ball:
        return 'Ball Sort';
      case SortPuzzleVariant.color:
        return 'Color Sort';
      case SortPuzzleVariant.water:
        return 'Water Sort';
      case SortPuzzleVariant.sand:
        return 'Sand Sort';
    }
  }
}
