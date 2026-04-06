import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/story_service.dart';
import '../../../core/models/story.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_provider.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  final String? initialStoryId;
  final List<Story>? stories;
  
  const StoryViewerScreen({
    super.key, 
    this.initialStoryId,
    this.stories,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen> {
  final PageController _pageController = PageController();
  final StoryService _storyService = StoryService();
  
  List<Story> _stories = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isPaused = false;
  Set<String> _seenStories = {};
  Timer? _autoAdvanceTimer;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      
      if (widget.stories != null) {
        _stories = widget.stories!;
        _currentIndex = widget.initialStoryId != null 
            ? _stories.indexWhere((s) => s.storyId == widget.initialStoryId)
            : 0;
      } else {
        if (currentUser != null) {
          _stories = await _storyService.getFollowingUserStories(currentUser.uid);
          _currentIndex = widget.initialStoryId != null 
              ? _stories.indexWhere((s) => s.storyId == widget.initialStoryId)
              : 0;
        }
      }

      if (_currentIndex > 0 && _currentIndex < _stories.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(_currentIndex);
        });
      }

      setState(() {
        _isLoading = false;
      });

      _startViewingStory();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load stories: $e')),
        );
      }
    }
  }

  void _startViewingStory() {
    if (_stories.isEmpty || _currentIndex < 0 || _currentIndex >= _stories.length) return;

    _autoAdvanceTimer?.cancel();

    final currentStory = _stories[_currentIndex];
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null && currentStory.ownerId != currentUser.uid) {
      _markStoryAsSeen(currentStory.storyId, currentUser.uid);
    }

    if (!_isPaused) {
      _autoAdvanceTimer = Timer(const Duration(seconds: 8), () {
        if (mounted && !_isPaused) _nextStory();
      });
    }
  }

  Future<void> _markStoryAsSeen(String storyId, String userId) async {
    try {
      await _storyService.markStoryAsSeen(storyId, userId);
      setState(() {
        _seenStories.add(storyId);
      });
    } catch (e) {
      print('Failed to mark story as seen: $e');
    }
  }

  void _nextStory() {
    _autoAdvanceTimer?.cancel();
    if (_currentIndex < _stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      if (mounted) context.pop();
    }
  }

  void _prevStory() {
    _autoAdvanceTimer?.cancel();
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      // Already at first story — restart its timer
      _startViewingStory();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _startViewingStory();
  }

  void _onLongPressStart() {
    _autoAdvanceTimer?.cancel();
    setState(() => _isPaused = true);
  }

  void _onLongPressEnd() {
    setState(() => _isPaused = false);
    _startViewingStory();
  }

  void _showStoryOptions() {
    final currentStory = _stories[_currentIndex];
    final currentUser = ref.read(currentUserProvider).value;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: currentStory.ownerProfileImage.isNotEmpty
                      ? CachedNetworkImageProvider(currentStory.ownerProfileImage)
                      : null,
                  child: currentStory.ownerProfileImage.isEmpty
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentStory.ownerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatTimestamp(currentStory.createdAt),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (currentStory.caption.isNotEmpty) ...[
              Text(currentStory.caption),
              const SizedBox(height: 16),
            ],

            if (currentUser != null) ...[
              Row(
                children: [
                  const Icon(Icons.visibility_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('${currentStory.seenBy.length} views'),
                  const Spacer(),
                  if (_seenStories.contains(currentStory.storyId))
                    const Text('Seen', style: TextStyle(color: Colors.green))
                  else
                    const Text('Not seen', style: TextStyle(color: Colors.grey)),
                ],
              ),

              const SizedBox(height: 16),

              if (currentStory.ownerId == currentUser.uid) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Story'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteStory(currentStory);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report_outlined),
                  title: const Text('Report Story'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report feature coming soon')),
                    );
                  },
                ),
              ],
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStory(Story story) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      await _storyService.deleteStory(story.storyId, currentUser.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story deleted')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete story: $e')),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final storyTime = timestamp.toDate();
    final difference = now.difference(storyTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'No stories available',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onLongPressStart: (_) => _onLongPressStart(),
        onLongPressEnd: (_) => _onLongPressEnd(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _stories.length,
              itemBuilder: (context, index) {
                final story = _stories[index];
                return _StoryPage(
                  story: story,
                  isSeen: _seenStories.contains(story.storyId),
                  isPaused: _isPaused,
                );
              },
            ),

            // Left tap zone → previous story
            Positioned(
              top: 0, bottom: 0, left: 0,
              width: MediaQuery.of(context).size.width * 0.35,
              child: GestureDetector(
                onTap: _prevStory,
                behavior: HitTestBehavior.translucent,
              ),
            ),

            // Right tap zone → next story
            Positioned(
              top: 0, bottom: 0, right: 0,
              width: MediaQuery.of(context).size.width * 0.65,
              child: GestureDetector(
                onTap: _nextStory,
                behavior: HitTestBehavior.translucent,
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _StoryProgressIndicator(
                            currentIndex: _currentIndex,
                            totalStories: _stories.length,
                            seenStories: _seenStories,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showStoryOptions,
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _stories[_currentIndex].ownerProfileImage.isNotEmpty
                            ? CachedNetworkImageProvider(_stories[_currentIndex].ownerProfileImage)
                            : null,
                        child: _stories[_currentIndex].ownerProfileImage.isEmpty
                            ? const Icon(Icons.person, size: 20, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stories[_currentIndex].ownerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _formatTimestamp(_stories[_currentIndex].createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  final Story story;
  final bool isSeen;
  final bool isPaused;

  const _StoryPage({
    required this.story,
    required this.isSeen,
    required this.isPaused,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: story.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade800,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),

          if (story.caption.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  story.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),

          if (isSeen)
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Seen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          if (isPaused)
            const Center(
              child: Icon(
                Icons.pause_circle_outline,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryProgressIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalStories;
  final Set<String> seenStories;

  const _StoryProgressIndicator({
    required this.currentIndex,
    required this.totalStories,
    required this.seenStories,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        totalStories,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: index <= currentIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
