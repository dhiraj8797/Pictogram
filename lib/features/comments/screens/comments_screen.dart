import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/models/comment.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_provider.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  final String postId;

  const CommentsScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final CommentService _commentService = CommentService();
  final ScrollController _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isPostingComment = false;
  Timestamp? _lastTimestamp;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _comments.clear();
      _lastTimestamp = null;
      _hasMore = true;
    });

    try {
      final comments = await _commentService.getCommentsForPost(
        widget.postId,
        lastTimestamp: _lastTimestamp,
      );
      
      setState(() {
        _comments = comments;
        _isLoading = false;
        _hasMore = comments.length == 20; // If we got 20, there might be more
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load comments: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final comments = await _commentService.getCommentsForPost(
        widget.postId,
        lastTimestamp: _lastTimestamp,
      );
      
      if (mounted) {
        setState(() {
          _comments.addAll(comments);
          _isLoading = false;
          _hasMore = comments.length == 20;
          
          if (comments.isNotEmpty) {
            // Store the last comment's timestamp for pagination
            _lastTimestamp = comments.last.createdAt;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more comments: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to comment')),
      );
      return;
    }

    setState(() {
      _isPostingComment = true;
    });

    try {
      final comment = await _commentService.createComment(
        postId: widget.postId,
        userId: currentUser.uid,
        username: currentUser.displayName,
        userProfileImage: currentUser.profileImage ?? '',
        text: text,
        isVerifiedComment: currentUser.isAadhaarVerified,
      );

      setState(() {
        _comments.insert(0, comment); // Add new comment at top
        _commentController.clear();
      });

      // Scroll to top to show new comment
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    try {
      await _commentService.toggleCommentLike(comment.commentId, currentUser.uid);
      
      // Update local state for immediate feedback
      setState(() {
        final index = _comments.indexWhere((c) => c.commentId == comment.commentId);
        if (index != -1) {
          final isLiked = _comments[index].likesCount > comment.likesCount;
          _comments[index] = _comments[index].copyWith(
            likesCount: isLiked ? comment.likesCount + 1 : comment.likesCount - 1,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like comment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isVerified = currentUser?.isAadhaarVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Comments List
          Expanded(
            child: _isLoading && _comments.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadComments,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _comments.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _comments.length && _hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (index >= _comments.length) {
                          return const SizedBox.shrink();
                        }

                        final comment = _comments[index];
                        return _CommentItem(
                          comment: comment,
                          onLike: () => _toggleCommentLike(comment),
                          currentUserId: currentUser?.uid,
                        );
                      },
                    ),
                  ),
          ),

          // Comment Input
          if (currentUser != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification warning
                  if (!isVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Only verified users can comment. Complete Aadhaar verification to comment.',
                              style: TextStyle(
                                color: Colors.orange.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Comment input
                  Row(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: currentUser.profileImage?.isNotEmpty == true
                            ? CachedNetworkImageProvider(currentUser.profileImage!)
                            : null,
                        child: currentUser.profileImage?.isEmpty != false
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),

                      const SizedBox(width: 12),

                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          enabled: isVerified,
                          decoration: InputDecoration(
                            hintText: isVerified ? 'Add a comment...' : 'Verify your account to comment',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(
                                color: isVerified ? Colors.grey.shade300 : Colors.grey.shade200,
                              ),
                            ),
                            filled: !isVerified,
                            fillColor: Colors.grey.shade100,
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _postComment(),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Post button
                      IconButton(
                        onPressed: isVerified && !_isPostingComment ? _postComment : null,
                        icon: _isPostingComment
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Login prompt
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.push('/login');
                      },
                      child: const Text('Login to comment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final VoidCallback onLike;
  final String? currentUserId;

  const _CommentItem({
    required this.comment,
    required this.onLike,
    this.currentUserId,
  });

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final commentTime = timestamp.toDate();
    final difference = now.difference(commentTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${commentTime.day}/${commentTime.month}/${commentTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: comment.userProfileImage.isNotEmpty
                ? CachedNetworkImageProvider(comment.userProfileImage)
                : null,
            child: comment.userProfileImage.isEmpty
                ? const Icon(Icons.person, size: 20)
                : null,
          ),

          const SizedBox(width: 12),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and time
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (comment.isVerifiedComment) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 12,
                        color: Colors.blue,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment text
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14),
                ),

                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: onLike,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite_border,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likesCount.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Reply button (placeholder)
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reply feature coming soon')),
                        );
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),

                    // Report button (only for others' comments)
                    if (currentUserId != null && comment.userId != currentUserId) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report feature coming soon')),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Text(
                          'Report',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}