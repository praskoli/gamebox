import 'package:flutter/widgets.dart';

class GameDefinition {
  final String id;
  final String title;
  final Widget Function(BuildContext context) builder;

  const GameDefinition({
    required this.id,
    required this.title,
    required this.builder,
  });
}