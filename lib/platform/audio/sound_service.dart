import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  final Random _random = Random();

  final List<String> _matchSounds = const [
    'sounds/winner2.mp3',
  ];

  final List<String> _failSounds = const [
    'sounds/fail1.mp3',
    'sounds/fail2.mp3',
  ];

  final List<String> _winSounds = const [
    'sounds/levelcomplete1.mp3',
  ];

  Future<void> _playRandom(
      List<String> files, {
        double volume = 0.75,
      }) async {
    final file = files[_random.nextInt(files.length)];
    final player = AudioPlayer();

    try {
      await player.play(
        AssetSource(file),
        volume: volume,
      );
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

  Future<void> _playSingle(
      String file, {
        double volume = 0.75,
      }) async {
    final player = AudioPlayer();

    try {
      await player.play(
        AssetSource(file),
        volume: volume,
      );
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

  Future<void> playMatch() => _playRandom(_matchSounds, volume: 0.72);

  Future<void> playFail() => _playRandom(_failSounds, volume: 0.55);

  Future<void> playGameOver() =>
      _playSingle('sounds/gameover3.mp3', volume: 0.82);
  Future<void> playWin() => _playRandom(_winSounds, volume: 0.85);

  Future<void> playBlockPlace() =>
      _playSingle('sounds/blockPlace.mp3', volume: 0.68);

  Future<void> playBonus() => _playSingle('sounds/bonus.mp3', volume: 0.8);

  Future<void> playGameStart() =>
      _playSingle('sounds/gameStart.mp3', volume: 0.72);

  Future<void> playLineClear() =>
      _playSingle('sounds/lineClear.mp3', volume: 0.8);

  Future<void> playLevelComplete() =>
      _playSingle('sounds/levelcomplete1.mp3', volume: 0.9);
}