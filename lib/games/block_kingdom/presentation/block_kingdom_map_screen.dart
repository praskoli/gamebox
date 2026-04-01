import 'package:flutter/material.dart';

import '../progression/data/block_level_catalog.dart';
import '../progression/data/block_progression_service.dart';
import '../progression/data/block_theme_catalog.dart';
import '../domain/block_mode.dart';
import 'block_kingdom_screen.dart';
import 'widgets/block_level_node.dart';

class BlockKingdomMapScreen extends StatefulWidget {
  const BlockKingdomMapScreen({super.key});

  @override
  State<BlockKingdomMapScreen> createState() => _BlockKingdomMapScreenState();
}

class _BlockKingdomMapScreenState extends State<BlockKingdomMapScreen> {
  bool _loading = true;
  int _highestUnlocked = 1;
  int _lastPlayed = 1;
  Map<String, int> _bestScores = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final progress = await BlockProgressionService.instance.getProgress();
      _highestUnlocked = progress.highestUnlockedLevel;
      _lastPlayed = progress.lastPlayedLevel;
      _bestScores = progress.bestScoresByLevel;
    } catch (_) {
      _highestUnlocked = 1;
      _lastPlayed = 1;
      _bestScores = const {};
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openLevel(int level) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlockKingdomScreen(
          mode: BlockMode.kingdom,
          initialLevelNumber: level,
        ),
      ),
    );

    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = BlockThemeCatalog.forLevel(_lastPlayed);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.screenGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFFB7185),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Kingdom Levels',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Text(
                        theme.name,
                        style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniInfoCard(
                        title: 'Current',
                        value: 'L$_lastPlayed',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniInfoCard(
                        title: 'Unlocked',
                        value: '$_highestUnlocked',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Select Level',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${BlockLevelCatalog.maxKingdomLevel} levels',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.72),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: BlockLevelCatalog.maxKingdomLevel,
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemBuilder: (context, index) {
                            final level = index + 1;
                            final unlocked = level <= _highestUnlocked;
                            final current = level == _lastPlayed;
                            final completed =
                            _bestScores.containsKey('$level');

                            return BlockLevelNode(
                              level: level,
                              isUnlocked: unlocked,
                              isCurrent: current,
                              isCompleted: completed,
                              onTap: unlocked ? () => _openLevel(level) : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.72),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}