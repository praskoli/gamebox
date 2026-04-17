enum SortVisualFamily {
  cleanOpen,
  compactDense,
  symmetricCalm,
  asymmetricFlow,
  centerFocus,
  edgeFocus,
  alternatingRhythm,
  fragmentedRhythm,
}

extension SortVisualFamilyX on SortVisualFamily {
  String get key {
    switch (this) {
      case SortVisualFamily.cleanOpen:
        return 'clean_open';
      case SortVisualFamily.compactDense:
        return 'compact_dense';
      case SortVisualFamily.symmetricCalm:
        return 'symmetric_calm';
      case SortVisualFamily.asymmetricFlow:
        return 'asymmetric_flow';
      case SortVisualFamily.centerFocus:
        return 'center_focus';
      case SortVisualFamily.edgeFocus:
        return 'edge_focus';
      case SortVisualFamily.alternatingRhythm:
        return 'alternating_rhythm';
      case SortVisualFamily.fragmentedRhythm:
        return 'fragmented_rhythm';
    }
  }

  static SortVisualFamily? fromKey(String? key) {
    switch (key) {
      case 'clean_open':
        return SortVisualFamily.cleanOpen;
      case 'compact_dense':
        return SortVisualFamily.compactDense;
      case 'symmetric_calm':
        return SortVisualFamily.symmetricCalm;
      case 'asymmetric_flow':
        return SortVisualFamily.asymmetricFlow;
      case 'center_focus':
        return SortVisualFamily.centerFocus;
      case 'edge_focus':
        return SortVisualFamily.edgeFocus;
      case 'alternating_rhythm':
        return SortVisualFamily.alternatingRhythm;
      case 'fragmented_rhythm':
        return SortVisualFamily.fragmentedRhythm;
      default:
        return null;
    }
  }
}