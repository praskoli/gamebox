enum SortOfficialMode {
  classicJourney,
  moveChallenge,
  timeChallenge,
  themeWorlds,
}

extension SortOfficialModeX on SortOfficialMode {
  String get key {
    switch (this) {
      case SortOfficialMode.classicJourney:
        return 'classic_journey';
      case SortOfficialMode.moveChallenge:
        return 'move_challenge';
      case SortOfficialMode.timeChallenge:
        return 'time_challenge';
      case SortOfficialMode.themeWorlds:
        return 'theme_worlds';
    }
  }

  String get title {
    switch (this) {
      case SortOfficialMode.classicJourney:
        return 'Classic Journey';
      case SortOfficialMode.moveChallenge:
        return 'Move Challenge';
      case SortOfficialMode.timeChallenge:
        return 'Time Challenge';
      case SortOfficialMode.themeWorlds:
        return 'Theme Worlds';
    }
  }

  static SortOfficialMode fromKey(String key) {
    switch (key) {
      case 'move_challenge':
        return SortOfficialMode.moveChallenge;
      case 'time_challenge':
        return SortOfficialMode.timeChallenge;
      case 'theme_worlds':
        return SortOfficialMode.themeWorlds;
      case 'classic_journey':
      default:
        return SortOfficialMode.classicJourney;
    }
  }
}