class DifficultyConfig {
  const DifficultyConfig({
    required this.friendlyWeight,
    required this.standardWeight,
    required this.trickyWeight,
    this.traySize = 3,
  });

  final int friendlyWeight;
  final int standardWeight;
  final int trickyWeight;
  final int traySize;

  const DifficultyConfig.early()
      : friendlyWeight = 70,
        standardWeight = 25,
        trickyWeight = 5,
        traySize = 3;

  const DifficultyConfig.mid()
      : friendlyWeight = 42,
        standardWeight = 40,
        trickyWeight = 18,
        traySize = 3;

  const DifficultyConfig.late()
      : friendlyWeight = 24,
        standardWeight = 42,
        trickyWeight = 34,
        traySize = 3;

  const DifficultyConfig.timeTrial()
      : friendlyWeight = 30,
        standardWeight = 45,
        trickyWeight = 25,
        traySize = 3;
}