import 'package:flutter/material.dart';

class GameDefinition {
  final String id;
  final String title;
  final WidgetBuilder builder;

  final IconData icon;
  final Color color;

  const GameDefinition({
    required this.id,
    required this.title,
    required this.builder,
    required this.icon,
    required this.color,
  });
}