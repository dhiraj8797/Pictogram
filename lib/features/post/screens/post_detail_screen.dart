import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../core/models/post.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/like_service.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/share_service.dart';
import '../../../core/constants/app_constants.dart';

// Providers
final postServiceProvider = Provider<PostService>((ref) => PostService());
final likeServiceProvider = Provider<LikeService>((ref) => LikeService());
final commentServiceProvider = Provider<CommentService>((ref) => CommentService());

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  Post? _post;
  bool _isLoading = true;
  String? _error;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final postService = ref.read(postServiceProvider);
      final post = await postService.getPostById(widget.postId);
      
      if (post != null) {
        final currentUser = ref.read(currentUserProvider);
        final user = currentUser.value;
        final likeService = ref.read(likeServiceProvider);

        // Track view (deduplicated per viewer)
        if (user != null) {
          ChatService().incrementPostView(widget.postId, user.uid);
        }

        final isLiked = await likeService.isPostLiked(widget.postId, user?.uid ?? '');
        final likeCount = await likeService.getPostLikesCount(widget.postId);

        setState(() {
          _post = post;
          _isLiked = isLiked;
          _likeCount = likeCount;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Post not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load post: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = ref.read(currentUserProvider);
    final user = currentUser.value;
    if (user?.uid == null) return;

    try {
      final likeService = ref.read(likeServiceProvider);
      
      if (_isLiked) {
        await likeService.unlikePost(widget.postId, user!.uid);
        setState(() {
          _isLiked = false;
          _likeCount--;
        });
      } else {
        await likeService.likePost(widget.postId, user!.uid);
        setState(() {
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle like: $e')),
      );
    }
  }

  Future<void> _sharePost() async {
    if (_post == null) return;
    try {
      await ShareService.sharePost(_post!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GlassBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadPost,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _post != null
                      ? _buildPostContent()
                      : const Center(
                          child: Text(
                            'Post not found',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Column(
      children: [
        // Top bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Spacer(),
              const Text(
                'Post',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // More options
                },
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
        ),

        // Post image
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            child: _post!.imageUrl.isNotEmpty
                ? Image.network(
                    _post!.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.withOpacity(0.3),
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey.withOpacity(0.3),
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.white54, size: 50),
                    ),
                  ),
          ),
        ),

        // Actions and info
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: _toggleLike,
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_likeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () {
                        // Navigate to comments
                        context.push('/comments/${widget.postId}');
                      },
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_post!.commentsCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _sharePost(),
                      icon: const Icon(Icons.share, color: Colors.white, size: 28),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Username and caption
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _post!.ownerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _post!.caption,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Location and tags
                if (_post!.location != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white54, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _post!.location!,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                if (_post!.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _post!.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )).toList(),
                  ),

                const Spacer(),

                // Timestamp
                Text(
                  _formatTimestamp(_post!.createdAt.toDate()),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
