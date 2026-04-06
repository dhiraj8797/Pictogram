import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/story_service.dart';
import '../../../core/models/post.dart';
import '../../../core/models/story.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PostService _postService = PostService();
  final StoryService _storyService = StoryService();
  final ScrollController _scrollController = ScrollController();
  
  List<Post> _posts = [];
  List<Story> _stories = [];
  bool _isLoading = true; // Keep initial loading state
  bool _isLoadingMore = false;
  bool _isLoadingStories = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  StreamSubscription<QuerySnapshot>? _postsSubscription;

  @override
  void initState() {
    super.initState();
    _loadStories();
    // Don't call _loadPosts() here - let real-time listener handle initial load
    _setupRealtimeListener();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListener() {
    // Listen for posts and their updates in real-time
    _postsSubscription = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = snapshot.docs.length >= 10;
          _isLoading = false; // Set loading to false when we get data
        });
        print('Posts updated: ${_posts.length} posts loaded');
      }
    }, onError: (error) {
      print('Real-time posts listener error: $error');
      if (mounted) {
        setState(() {
          _isLoading = false; // Also set loading to false on error
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePosts();
      }
    }
  }

  Future<void> _loadStories() async {
    setState(() {
      _isLoadingStories = true;
    });

    try {
      // For demo, get stories from all users
      final stories = await _storyService.getActiveStoriesForUsers([]);
      setState(() {
        _stories = stories;
      });
    } catch (e) {
      print('Failed to load stories: $e');
    } finally {
      setState(() {
        _isLoadingStories = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Initial load - real-time listener will handle updates
      final posts = await _postService.getFeedPosts(limit: 10);
      setState(() {
        _posts = posts;
        _hasMore = posts.length >= 10;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Load more posts with pagination
      final morePosts = await _postService.getFeedPosts(
        limit: 10,
        lastDocument: _lastDocument,
      );
      
      setState(() {
        _posts.addAll(morePosts);
        _lastDocument = morePosts.isNotEmpty ? morePosts.last.documentSnapshot : null;
        _hasMore = morePosts.length >= 10;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more posts: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    // For refresh, we'll restart the real-time listener
    _postsSubscription?.cancel();
    setState(() {
      _posts.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _setupRealtimeListener();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PictoGram'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              context.go('/notifications');
            },
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // Stories Section
            _buildStoriesSection(currentUser),
            
            // Posts Section
            Expanded(
              child: _isLoading && _posts.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _posts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to share a moment!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _posts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              return _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : const SizedBox();
                            }

                            final post = _posts[index];
                            return _PostCard(
                              post: post,
                              currentUser: currentUser,
                              onLike: () async {
                                try {
                                  await _postService.toggleLike(post.postId, currentUser?.uid ?? '');
                                  // Don't manually refresh - let real-time listener handle updates
                                  print('Like toggled successfully for post: ${post.postId}');
                                } catch (e) {
                                  print('Failed to like post: $e');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to like post: $e')),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoriesSection(AppUser? currentUser) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _stories.length + 1, // +1 for "Add Story"
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Add Story button
                  return _AddStoryCard(currentUser: currentUser);
                }
                
                final story = _stories[index - 1];
                return _StoryCard(story: story);
              },
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final Post post;
  final AppUser? currentUser;
  final VoidCallback onLike;

  const _PostCard({
    required this.post,
    this.currentUser,
    required this.onLike,
  });

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    if (widget.currentUser == null) {
      print('DEBUG: No current user, skipping like status check');
      return;
    }
    
    try {
      final postService = PostService();
      final isLiked = await postService.isPostLiked(widget.post.postId, widget.currentUser!.uid);
      print('DEBUG: Like status for post ${widget.post.postId}: $isLiked');
      
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      print('DEBUG: Error checking like status: $e');
    }
  }

  Future<void> _handleLike() async {
    if (widget.currentUser == null || _isLoading) return;
    
    print('DEBUG: Starting like operation for post: ${widget.post.postId}, user: ${widget.currentUser!.uid}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onLike();
      print('DEBUG: Like operation completed successfully');
      
      // Recheck like status after a short delay to allow Firebase to update
      await Future.delayed(const Duration(milliseconds: 500));
      await _checkLikeStatus();
    } catch (e) {
      print('DEBUG: Error in like operation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

    String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final postTime = timestamp.toDate();
    final difference = now.difference(postTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _editPost() {
    context.push('/edit-post/${widget.post.postId}', extra: widget.post);
  }

  void _deletePost() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    try {
      // TODO: Implement delete post functionality
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delete feature coming soon'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and options
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: CircleAvatar(
              backgroundImage: widget.post.ownerProfileImage.isNotEmpty
                  ? CachedNetworkImageProvider(widget.post.ownerProfileImage)
                  : null,
              child: widget.post.ownerProfileImage.isEmpty
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              widget.post.ownerName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(_formatTimestamp(widget.post.createdAt)),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                if (value == 'edit') {
                  _editPost();
                } else if (value == 'delete') {
                  _deletePost();
                }
              },
              itemBuilder: (context) {
                final currentUser = ref.read(currentUserProvider).value;
                final isOwner = currentUser?.uid == widget.post.ownerId;
                
                if (isOwner) {
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 8),
                          Text('Edit Post'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Post', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                } else {
                  return [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined),
                          SizedBox(width: 8),
                          Text('Report Post'),
                        ],
                      ),
                    ),
                  ];
                }
              },
            ),
          ),

          // Image with square aspect ratio
          AspectRatio(
            aspectRatio: 1.0, // Square shape
            child: CachedNetworkImage(
              imageUrl: widget.post.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _handleLike,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : null,
                        ),
                ),
                IconButton(
                  onPressed: () {
                    context.push('/comments/${widget.post.postId}');
                  },
                  icon: const Icon(Icons.mode_comment_outlined),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_outlined),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                ),
              ],
            ),
          ),

          // Caption and likes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.post.likesCount} likes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${widget.post.ownerName} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: widget.post.caption),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (widget.post.commentsCount > 0)
                  InkWell(
                    onTap: () {
                      context.push('/comments/${widget.post.postId}');
                    },
                    child: Text(
                      'View all ${widget.post.commentsCount} comments',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(widget.post.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Story story;

  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          // Story Circle
          GestureDetector(
            onTap: () {
              context.push('/story/${story.storyId}');
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.purple,
                    Colors.pink,
                    Colors.orange,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: story.imageUrl,
                      fit: BoxFit.cover,
                      width: 56,
                      height: 56,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Name
          SizedBox(
            width: 70,
            child: Text(
              story.ownerName,
              style: const TextStyle(
                fontSize: 12,
                overflow: TextOverflow.ellipsis,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStoryCard extends StatelessWidget {
  final AppUser? currentUser;

  const _AddStoryCard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          // Add Story Circle
          GestureDetector(
            onTap: () {
              if (currentUser != null) {
                context.push('/create-story');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to add a story')),
                );
              }
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.blue,
                  width: 2,
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade100,
                    Colors.purple.shade100,
                  ],
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 30,
                color: Colors.blue,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Add Story Text
          const SizedBox(
            width: 70,
            child: Text(
              'Your story',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}