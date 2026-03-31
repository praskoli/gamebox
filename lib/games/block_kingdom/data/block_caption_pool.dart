import 'dart:math';

class BlockCaptionPool {
  static final _messages = [
    "Nice Move!",
    "Kingdom Growing!",
    "Combo Blast!",
    "Perfect Fit!",
    "Brilliant!",
  ];

  static String random() {
    return _messages[Random().nextInt(_messages.length)];
  }
}