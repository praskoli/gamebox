enum AppMode {
  normal,
  guided,
  parentPremium,
}

extension AppModeX on AppMode {
  String get title {
    switch (this) {
      case AppMode.normal:
        return 'Normal Mode';
      case AppMode.guided:
        return 'Guided Mode';
      case AppMode.parentPremium:
        return 'Premium Parent Mode';
    }
  }

  String get subtitle {
    switch (this) {
      case AppMode.normal:
        return 'Play freely with light healthy reminders.';
      case AppMode.guided:
        return 'Play with rewards for better habits.';
      case AppMode.parentPremium:
        return 'Advanced family controls and reports.';
    }
  }

  String get key {
    switch (this) {
      case AppMode.normal:
        return 'normal';
      case AppMode.guided:
        return 'guided';
      case AppMode.parentPremium:
        return 'parentPremium';
    }
  }

  static AppMode fromKey(String? value) {
    switch (value) {
      case 'guided':
        return AppMode.guided;
      case 'parentPremium':
        return AppMode.parentPremium;
      case 'normal':
      default:
        return AppMode.normal;
    }
  }
}