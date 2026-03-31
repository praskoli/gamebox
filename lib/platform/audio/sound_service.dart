import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final Random _random = Random();

  final List<String> _matchSounds = const [
    'sounds/achievement2.mp3',
    'sounds/bonus1.mp3',
    'sounds/freesound_community-game-creature-90736.mp3',
  ];

  final List<String> _failSounds = const [
    'sounds/fail1.mp3',
    'sounds/fail2.mp3',
  ];

  final List<String> _winSounds = const [
    'sounds/levelcomplete1.mp3',
    'sounds/levelcomplete2.mp3',
    'sounds/winner1.mp3',
  ];

  Future<void> _playRandom(List<String> files) async {
    final file = files[_random.nextInt(files.length)];
    final player = AudioPlayer();

    try {
      await player.play(AssetSource(file));
    } catch (_) {
      // Never break gameplay because of sound issues.
    } finally {
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await player.dispose();
        } catch (_) {}
      });
    }
  }

  Future<void> playMatch() => _playRandom(_matchSounds);

  Future<void> playFail() => _playRandom(_failSounds);

  Future<void> playWin() => _playRandom(_winSounds);
}