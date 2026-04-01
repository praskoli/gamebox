enum BlockMode {
  kingdom,
  endless,
  timeTrial,
}

extension BlockModeX on BlockMode {
  String get title {
    switch (this) {
      case BlockMode.kingdom:
        return 'Kingdom';
      case BlockMode.endless:
        return 'Endless';
      case BlockMode.timeTrial:
        return 'Time Trial';
    }
  }

  String get subtitle {
    switch (this) {
      case BlockMode.kingdom:
        return 'Progression';
      case BlockMode.endless:
        return 'Classic';
      case BlockMode.timeTrial:
        return 'Timer Challenge';
    }
  }

  bool get isTimed => this == BlockMode.timeTrial;
}