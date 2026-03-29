import '../models/daily_mission.dart';
import '../models/player_profile.dart';

class HomeGamificationService {
  const HomeGamificationService._();

  static List<DailyMission> buildMissions(PlayerProfile profile) {
    final gamesMission = DailyMission(
      id: 'play_2_games',
      title: 'Play 2 games today',
      description: 'Complete game sessions to earn bonus rewards.',
      target: 2,
      progress: profile.gamesPlayed.clamp(0, 2),
      rewardCoins: 30,
      rewardXp: 20,
    );

    final coinsMission = DailyMission(
      id: 'earn_150_xp',
      title: 'Reach 150 XP',
      description: 'Keep playing to level up faster.',
      target: 150,
      progress: profile.xp.clamp(0, 150),
      rewardCoins: 40,
      rewardXp: 30,
    );

    final streakMission = DailyMission(
      id: 'keep_streak',
      title: 'Keep your streak going',
      description: 'Come back tomorrow to extend your streak.',
      target: 7,
      progress: profile.streakDays.clamp(0, 7),
      rewardCoins: 25,
      rewardXp: 15,
    );

    return [gamesMission, coinsMission, streakMission];
  }

  static bool canClaimDailyReward(PlayerProfile profile) {
    final claimedAt = profile.dailyRewardClaimedAt;
    if (claimedAt == null) return true;

    final now = DateTime.now();
    return now.year != claimedAt.year ||
        now.month != claimedAt.month ||
        now.day != claimedAt.day;
  }

  static double xpProgressToNextLevel(PlayerProfile profile) {
    final currentLevelBaseXp = (profile.level - 1) * 100;
    final nextLevelXp = profile.level * 100;
    final currentLevelProgress = profile.xp - currentLevelBaseXp;
    final levelWindow = nextLevelXp - currentLevelBaseXp;
    if (levelWindow <= 0) return 0;
    return (currentLevelProgress / levelWindow).clamp(0, 1);
  }
}