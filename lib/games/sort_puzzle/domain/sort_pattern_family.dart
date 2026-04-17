enum SortPatternFamily {
  zigzag,
  staircase,
  mirrorBreak,
  centerHeavy,
  edgeHeavy,
  crossMix,
  spiralShift,
  clusterBreak,
  topTrap,
  bottomTrap,
  alternating,
  offsetBlocks,
  funnel,
  splitBridge,
  ladderMix,
  cornerPressure,
}

extension SortPatternFamilyX on SortPatternFamily {
  String get key {
    switch (this) {
      case SortPatternFamily.zigzag:
        return 'zigzag';
      case SortPatternFamily.staircase:
        return 'staircase';
      case SortPatternFamily.mirrorBreak:
        return 'mirror_break';
      case SortPatternFamily.centerHeavy:
        return 'center_heavy';
      case SortPatternFamily.edgeHeavy:
        return 'edge_heavy';
      case SortPatternFamily.crossMix:
        return 'cross_mix';
      case SortPatternFamily.spiralShift:
        return 'spiral_shift';
      case SortPatternFamily.clusterBreak:
        return 'cluster_break';
      case SortPatternFamily.topTrap:
        return 'top_trap';
      case SortPatternFamily.bottomTrap:
        return 'bottom_trap';
      case SortPatternFamily.alternating:
        return 'alternating';
      case SortPatternFamily.offsetBlocks:
        return 'offset_blocks';
      case SortPatternFamily.funnel:
        return 'funnel';
      case SortPatternFamily.splitBridge:
        return 'split_bridge';
      case SortPatternFamily.ladderMix:
        return 'ladder_mix';
      case SortPatternFamily.cornerPressure:
        return 'corner_pressure';
    }
  }

  static SortPatternFamily? fromKey(String? key) {
    switch (key) {
      case 'zigzag':
        return SortPatternFamily.zigzag;
      case 'staircase':
        return SortPatternFamily.staircase;
      case 'mirror_break':
        return SortPatternFamily.mirrorBreak;
      case 'center_heavy':
        return SortPatternFamily.centerHeavy;
      case 'edge_heavy':
        return SortPatternFamily.edgeHeavy;
      case 'cross_mix':
        return SortPatternFamily.crossMix;
      case 'spiral_shift':
        return SortPatternFamily.spiralShift;
      case 'cluster_break':
        return SortPatternFamily.clusterBreak;
      case 'top_trap':
        return SortPatternFamily.topTrap;
      case 'bottom_trap':
        return SortPatternFamily.bottomTrap;
      case 'alternating':
        return SortPatternFamily.alternating;
      case 'offset_blocks':
        return SortPatternFamily.offsetBlocks;
      case 'funnel':
        return SortPatternFamily.funnel;
      case 'split_bridge':
        return SortPatternFamily.splitBridge;
      case 'ladder_mix':
        return SortPatternFamily.ladderMix;
      case 'corner_pressure':
        return SortPatternFamily.cornerPressure;
      default:
        return null;
    }
  }
}