import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_mode.dart';
import '../../platform/rewards/models/daily_mission.dart';
import '../../game_engine/catalog/models/game_tile_model.dart';
import '../../platform/player/player_profile.dart';
import '../../platform/rewards/services/home_gamification_service.dart';
import '../../platform/profile/services/profile_service.dart';
import '../../game_engine/catalog/game_routes.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel();

  bool _isLoading = true;
  bool _isClaimingReward = false;
  String? _errorMessage;
  PlayerProfile? _profile;
  List<DailyMission> _missions = const [];

  bool get isLoading => _isLoading;
  bool get isClaimingReward => _isClaimingReward;
  String? get errorMessage => _errorMessage;
  PlayerProfile? get profile => _profile;
  List<DailyMission> get missions => _missions;

  bool get canClaimDailyReward {
    final current = _profile;
    if (current == null) return false;
    return HomeGamificationService.canClaimDailyReward(current);
  }

  double get xpProgress {
    final current = _profile;
    if (current == null) return 0;
    return HomeGamificationService.xpProgressToNextLevel(current);
  }

  AppMode get currentMode => _profile?.currentMode ?? AppMode.normal;

  List<GameTileModel> get games => [
    GameTileModel(
      id: 'memory_match_world',
      title: 'Memory Match',
      subtitle: 'Fruit Valley world map',
      icon: Icons.map_rounded,
      color: const Color(0xFF5B67F1),
      isLocked: false,
      routeName: GameRoutes.memoryWorldMap,
    ),
    const GameTileModel(
      id: 'color_sort',
      title: 'Color Sort',
      subtitle: 'Coming soon',
      icon: Icons.palette_rounded,
      color: Color(0xFF14B8A6),
      isLocked: true,
      routeName: '',
    ),
    const GameTileModel(
      id: 'block_dash',
      title: 'Block Dash',
      subtitle: 'Coming soon',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFF59E0B),
      isLocked: true,
      routeName: '',
    ),
  ];

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await ProfileService.instance.ensureProfile();
      _profile = profile;
      _missions = HomeGamificationService.buildMissions(profile);
    } catch (e) {
      _errorMessage = 'Failed to load home data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      final profile = await ProfileService.instance.getProfile();
      _profile = profile;
      _missions = HomeGamificationService.buildMissions(profile);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to refresh data: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> claimDailyReward() async {
    if (_isClaimingReward || !canClaimDailyReward) return;

    _isClaimingReward = true;
    notifyListeners();

    try {
      final updated = await ProfileService.instance.claimDailyReward(
        coins: 25,
        xp: 15,
      );
      _profile = updated;
      _missions = HomeGamificationService.buildMissions(updated);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to claim daily reward: $e';
    } finally {
      _isClaimingReward = false;
      notifyListeners();
    }
  }

  Future<void> keepNormalMode() async {
    try {
      await ProfileService.instance.updateMode(AppMode.normal);
      await refresh();
    } catch (e) {
      _errorMessage = 'Failed to update mode: $e';
      notifyListeners();
    }
  }
}