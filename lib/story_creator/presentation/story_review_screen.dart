import 'package:flutter/material.dart';

import '../data/story_repository.dart';
import '../domain/scene_model.dart';
import '../domain/story_model.dart';
import 'story_player_screen.dart';

class StoryReviewScreen extends StatefulWidget {
  const StoryReviewScreen({super.key});

  @override
  State<StoryReviewScreen> createState() => _StoryReviewScreenState();
}

class _StoryReviewScreenState extends State<StoryReviewScreen>
    with SingleTickerProviderStateMixin {
  final StoryRepository _repository = StoryRepository();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<StoryBundle?> _bundleFor(StoryModel story) {
    return _repository.getStoryBundle(story.id);
  }

  Future<void> _openPreview(StoryModel story) async {
    final bundle = await _bundleFor(story);
    if (!mounted || bundle == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryPlayerScreen(
          story: bundle.story,
          scenes: bundle.scenes,
        ),
      ),
    );
  }

  Future<void> _approve(StoryModel story) async {
    await _repository.approveStory(story);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story published')),
    );
  }

  Future<void> _reject(StoryModel story) async {
    await _repository.rejectStory(story, reason: 'Rejected by admin');
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story rejected')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12062E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Story Review',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Published'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList('pending_review'),
          _buildList('published'),
          _buildList('rejected'),
        ],
      ),
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<List<StoryModel>>(
      stream: _repository.watchStoriesByStatus(status),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No stories',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final story = items[index];

            return FutureBuilder<StoryBundle?>(
              future: _bundleFor(story),
              builder: (context, bundleSnap) {
                final scenes = bundleSnap.data?.scenes ?? [];

                final flagged = scenes
                    .where((s) => s.status == 'flagged')
                    .toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (flagged.isNotEmpty)
                        Text(
                          '⚠ ${flagged.length} flagged scenes',
                          style: const TextStyle(
                            color: Colors.pinkAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _openPreview(story),
                              child: const Text('Preview'),
                            ),
                          ),

                          if (status == 'pending_review') ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _approve(story),
                                child: const Text('Approve'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _reject(story),
                                child: const Text('Reject'),
                              ),
                            ),
                          ]
                        ],
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}