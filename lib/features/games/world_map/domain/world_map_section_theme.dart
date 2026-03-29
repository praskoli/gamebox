import 'package:flutter/material.dart';

enum WorldMapLandmarkType {
  fruitCart,
  woodenBridge,
  juiceWaterfall,
  trainCrossingGate,
  picnicGround,
  candyTunnel,
  balloonArch,
  marketStall,
  orchardFence,
  windmill,
  fountain,
  toyTrainTrackCrossing,
  crystalCavern,
  dreamMeadow,
  bubbleForest,
  toyWorkshop,
}

class WorldMapSectionTheme {
  const WorldMapSectionTheme({
    required this.id,
    required this.title,
    required this.backgroundAsset,
    required this.topColor,
    required this.bottomColor,
    required this.pathColor,
    required this.nodeAccentColor,
    required this.landmarkType,
    required this.decorations,
    this.showParallaxClouds = false,
    this.showSparkles = false,
    this.showBubbles = false,
    this.showLightRays = false,
  });

  final String id;
  final String title;
  final String backgroundAsset;
  final Color topColor;
  final Color bottomColor;
  final Color pathColor;
  final Color nodeAccentColor;
  final WorldMapLandmarkType landmarkType;
  final List<String> decorations;

  final bool showParallaxClouds;
  final bool showSparkles;
  final bool showBubbles;
  final bool showLightRays;
}