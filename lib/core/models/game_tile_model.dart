import 'package:flutter/material.dart';

class GameTileModel {
  const GameTileModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isLocked,
    required this.routeName,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLocked;
  final String routeName;
}