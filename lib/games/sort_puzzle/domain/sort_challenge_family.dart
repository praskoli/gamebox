enum SortChallengeFamily {
  obviousStart,
  hiddenStart,
  fakeEasy,
  topColorTrap,
  buriedColorTrap,
  competingPaths,
  recoveryBoard,
  sequencingBoard,
  symmetryBreak,
  pressureBoard,
}

extension SortChallengeFamilyX on SortChallengeFamily {
  String get key {
    switch (this) {
      case SortChallengeFamily.obviousStart:
        return 'obvious_start';
      case SortChallengeFamily.hiddenStart:
        return 'hidden_start';
      case SortChallengeFamily.fakeEasy:
        return 'fake_easy';
      case SortChallengeFamily.topColorTrap:
        return 'top_color_trap';
      case SortChallengeFamily.buriedColorTrap:
        return 'buried_color_trap';
      case SortChallengeFamily.competingPaths:
        return 'competing_paths';
      case SortChallengeFamily.recoveryBoard:
        return 'recovery_board';
      case SortChallengeFamily.sequencingBoard:
        return 'sequencing_board';
      case SortChallengeFamily.symmetryBreak:
        return 'symmetry_break';
      case SortChallengeFamily.pressureBoard:
        return 'pressure_board';
    }
  }

  static SortChallengeFamily? fromKey(String? key) {
    switch (key) {
      case 'obvious_start':
        return SortChallengeFamily.obviousStart;
      case 'hidden_start':
        return SortChallengeFamily.hiddenStart;
      case 'fake_easy':
        return SortChallengeFamily.fakeEasy;
      case 'top_color_trap':
        return SortChallengeFamily.topColorTrap;
      case 'buried_color_trap':
        return SortChallengeFamily.buriedColorTrap;
      case 'competing_paths':
        return SortChallengeFamily.competingPaths;
      case 'recovery_board':
        return SortChallengeFamily.recoveryBoard;
      case 'sequencing_board':
        return SortChallengeFamily.sequencingBoard;
      case 'symmetry_break':
        return SortChallengeFamily.symmetryBreak;
      case 'pressure_board':
        return SortChallengeFamily.pressureBoard;
      default:
        return null;
    }
  }
}