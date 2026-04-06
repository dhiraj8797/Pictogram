import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/verified_badge.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../core/models/post.dart';
import '../../../core/models/story.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/story_service.dart';
import '../../../core/services/security_service.dart';
import '../../../core/services/share_service.dart';

// ── Enhanced Glassmorphism tokens ───────────────────────────────────────────
class _TC {
  // Base backgrounds
  static const bgDark     = Color(0xFF0A0010);
  static const bgMid      = Color(0xFF110018);
  static const bgTop      = Color(0xFF1A0028);
  // Accent
  static const pink       = Color(0xFFE0389A);
  static const coral      = Color(0xFFCC2299);
  // Enhanced glass surfaces — more transparent and reflective
  static const glass      = Color.fromRGBO(255, 255, 255, 0.03);
  static const glassHover = Color.fromRGBO(255, 255, 255, 0.08);
  static const card       = Color.fromRGBO(255, 255, 255, 0.04);
  static const cardBorder = Color.fromRGBO(255, 255, 255, 0.12);
  static const cardTop    = Color.fromRGBO(255, 255, 255, 0.10);
  static const cardBottom = Color.fromRGBO(255, 255, 255, 0.02);
  // Stronger glow effects
  static const pinkGlow   = Color.fromRGBO(224, 56, 154, 0.30);
  static const coralGlow  = Color.fromRGBO(204, 34, 153, 0.25);
  // Reflection overlay
  static const reflection = Color.fromRGBO(255, 255, 255, 0.15);
  // Story rings
  static const ring1      = Color(0xFFE0389A);
  static const ring2      = Color(0xFFCC2299);
}

class GlassHomeScreen extends ConsumerStatefulWidget {
  const GlassHomeScreen({super.key});

  @override
  ConsumerState<GlassHomeScreen> createState() => _GlassHomeScreenState();
}

class _GlassHomeScreenState extends ConsumerState<GlassHomeScreen> {
  final StoryService _storyService = StoryService();
  final ScrollController _scrollController = ScrollController();
  
  List<Post> _posts = [];
  List<Story> _stories = [];
  List<Story> _myStories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  StreamSubscription<List<Story>>? _myStoriesSubscription;
  String? _subscribedUserId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadFollowingStories();
    _scrollController.addListener(_onScroll);
    SecurityService().enableSecureScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to real-time story stream when user is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null && _subscribedUserId != currentUser.uid) {
        _subscribeToMyStories(currentUser.uid);
      }
    });
  }

  void _subscribeToMyStories(String userId) {
    _myStoriesSubscription?.cancel();
    _subscribedUserId = userId;
    _myStoriesSubscription = _storyService
        .getUserStoriesStream(userId)
        .listen(
      (stories) {
        if (mounted) setState(() => _myStories = stories);
      },
      onError: (Object e) {
        debugPrint('Story stream error: $e — falling back to one-time fetch');
        _storyService.getUserStories(userId).then((stories) {
          if (mounted) setState(() => _myStories = stories);
        }, onError: (Object err) {
          debugPrint('Fallback fetch error: $err');
        });
      },
    );
  }

  @override
  void dispose() {
    _myStoriesSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMorePosts();
      }
    }
  }


  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _lastDocument = null;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      final posts = snapshot.docs.map(Post.fromFirestore).toList();
      if (mounted) {
        setState(() {
          _posts = posts;
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = posts.length >= 10;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_loadPosts error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load posts: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(10)
          .get();
      final more = snapshot.docs.map(Post.fromFirestore).toList();
      if (mounted) {
        setState(() {
          _posts.addAll(more);
          _lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
          _hasMore = more.length >= 10;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('_loadMorePosts error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load more: $e')),
        );
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _loadFollowingStories() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;
      final stories = await _storyService.getFollowingUserStories(currentUser.uid);
      if (mounted) setState(() => _stories = stories);
    } catch (e) {
      debugPrint('_loadFollowingStories error: $e');
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _posts.clear();
      _hasMore = true;
      _lastDocument = null;
    });
    await Future.wait([_loadPosts(), _loadFollowingStories()]);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: _TC.bgDark,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat-test'),
        backgroundColor: _TC.pink,
        child: const Icon(Icons.bug_report, color: Colors.white),
      ),
      body: Stack(
        children: [
          // Layer 1 – dark linear base
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_TC.bgTop, _TC.bgMid, _TC.bgDark],
                stops: [0.0, 0.38, 1.0],
              ),
            ),
          ),
          // Layer 2 – pink radial glow at top
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -1.0),
                radius: 1.4,
                colors: [_TC.pinkGlow, Colors.transparent],
                stops: [0.0, 0.28],
              ),
            ),
          ),
          // Layer 3 – actual content
          SafeArea(
            child: Column(
            children: [
              _buildTopBar(currentUser),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: _TC.pink,
                  backgroundColor: _TC.card,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Stories row
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 14),
                            _StoriesRow(
                              stories: _stories,
                              currentUser: currentUser,
                              myStories: _myStories,
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),
                      // Posts
                      if (_isLoading)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _PostShimmer(),
                            childCount: 3,
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              child: _TrendPostCard(
                                post: _posts[i],
                                currentUser: currentUser,
                                onRefresh: _refresh,
                              ),
                            ),
                            childCount: _posts.length,
                          ),
                        ),
                      // Load more indicator
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            if (_isLoadingMore)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(color: _TC.pink, strokeWidth: 2),
                              ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(AppUser? currentUser) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          // Brand
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_TC.coral, _TC.pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'PictoGram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Search
          GlassIconButton(icon: Icons.search_rounded, onTap: () => context.push('/search')),
          const SizedBox(width: 8),
          // Messages
          GlassIconButton(icon: Icons.chat_bubble_outline_rounded, onTap: () => context.push('/messages')),
          const SizedBox(width: 8),
          // Notifications
          GlassIconButton(icon: Icons.notifications_none_rounded, onTap: () => context.push('/notifications')),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.07),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ─── Stories Row ─────────────────────────────────────────────────────────────
class _StoriesRow extends StatelessWidget {
  final List<Story> stories;
  final AppUser? currentUser;
  final List<Story> myStories;

  const _StoriesRow({
    required this.stories,
    required this.currentUser,
    required this.myStories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _AddStoryCard(currentUser: currentUser, myStories: myStories),
            );
          }
          final story = stories[index - 1];
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: _StoryCard(story: story),
          );
        },
      ),
    );
  }
}

class _AddStoryCard extends StatefulWidget {
  final AppUser? currentUser;
  final List<Story> myStories;

  const _AddStoryCard({
    required this.currentUser, 
    required this.myStories,
  });

  @override
  State<_AddStoryCard> createState() => _AddStoryCardState();
}

class _AddStoryCardState extends State<_AddStoryCard> {
  Future<void> _pickStoryImage(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isEmpty || !context.mounted) return;

      if (pickedFiles.length == 1) {
        // Single image — go to story edit screen
        context.push('/story-edit', extra: File(pickedFiles.first.path));
      } else {
        // Multiple images — show upload-all sheet
        final images = pickedFiles.map((f) => File(f.path)).toList();
        _showMultiUploadSheet(context, images);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: $e')),
        );
      }
    }
  }

  void _showMultiUploadSheet(BuildContext context, List<File> images) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MultiStoryUploadSheet(
        images: images,
        currentUser: widget.currentUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveStory = widget.myStories.isNotEmpty;
    return GestureDetector(
      onTap: () {
        if (widget.currentUser != null) {
          if (hasActiveStory) {
            context.push('/story-viewer', extra: widget.myStories);
          } else {
            _pickStoryImage(context);
          }
        }
      },
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasActiveStory
                        ? const LinearGradient(
                            colors: [_TC.ring1, _TC.ring2, _TC.ring1],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          )
                        : null,
                    color: hasActiveStory ? null : Colors.white.withValues(alpha: 0.15),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _TC.bgMid,
                    ),
                    child: ClipOval(
                      child: widget.currentUser?.profileImage != null
                          ? CachedNetworkImage(
                              imageUrl: widget.currentUser!.profileImage!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.person, size: 28, color: Colors.white70),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickStoryImage(context),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_TC.ring1, _TC.ring2],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: _TC.bgMid, width: 2),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Your story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  final Story story;
  const _StoryCard({required this.story});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/story-viewer', extra: story),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_TC.ring1, _TC.ring2, _TC.ring1],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: _TC.bgMid),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: story.ownerProfileImage.isNotEmpty
                      ? CachedNetworkImage(imageUrl: story.ownerProfileImage, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.person, color: Colors.white70, size: 28),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              story.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trendily Post Card ────────────────────────────────────────────────────────
class _TrendPostCard extends ConsumerStatefulWidget {
  final Post post;
  final AppUser? currentUser;
  final VoidCallback? onRefresh;

  const _TrendPostCard({
    required this.post,
    required this.currentUser,
    this.onRefresh,
  });

  @override
  ConsumerState<_TrendPostCard> createState() => _TrendPostCardState();
}

class _TrendPostCardState extends ConsumerState<_TrendPostCard> {
  bool _isLiked = false;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    if (widget.currentUser == null) return;
    try {
      final isLiked = await PostService().isPostLiked(
        widget.post.postId, widget.currentUser!.uid);
      if (mounted) setState(() => _isLiked = isLiked);
    } catch (_) {}
  }

  Future<void> _handleLike() async {
    if (widget.currentUser == null || _isLikeLoading) return;
    setState(() { _isLiked = !_isLiked; _isLikeLoading = true; });
    try {
      await PostService().toggleLike(widget.post.postId, widget.currentUser!.uid);
      widget.onRefresh?.call();
    } catch (_) {
      if (mounted) setState(() => _isLiked = !_isLiked);
    } finally {
      if (mounted) setState(() => _isLikeLoading = false);
    }
  }

  String _ts(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${t.day}/${t.month}/${t.year}';
  }

  Future<void> _sharePost() async {
    try {
      await ShareService.sharePost(widget.post);
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_TC.cardTop, _TC.cardBottom],
        ),
        border: Border.all(color: _TC.cardBorder, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + overlay ────────────────────────────────────────────────
          Stack(
            children: [
              // Post image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: widget.post.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.post.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.white.withValues(alpha: 0.04),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: _TC.pink, strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.white.withValues(alpha: 0.04),
                            child: const Icon(Icons.broken_image,
                                color: Colors.white24, size: 44),
                          ),
                        )
                      : Container(color: Colors.white.withValues(alpha: 0.04)),
                ),
              ),
              // Top gradient overlay
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // User info row over image
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.push('/profile/${widget.post.ownerId}'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _TC.pink, width: 2),
                          ),
                          child: ClipOval(
                            child: widget.post.ownerProfileImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.post.ownerProfileImage,
                                    fit: BoxFit.cover)
                                : Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.person,
                                        color: Colors.white70, size: 22),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/profile/${widget.post.ownerId}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.post.displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        shadows: [
                                          Shadow(color: Colors.black54, blurRadius: 4)
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.post.ownerId == 'pictogram_official' ||
                                      widget.post.displayName
                                          .toLowerCase()
                                          .contains('pictogram')) ...[
                                    const SizedBox(width: 4),
                                    const VerifiedBadge(isOfficial: true, size: 14),
                                  ],
                                ],
                              ),
                              if (widget.post.location != null)
                                Text(
                                  widget.post.location!,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                    shadows: [
                                      Shadow(color: Colors.black54, blurRadius: 4)
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        _ts(widget.post.createdAt.toDate()),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                      if (widget.currentUser?.uid == widget.post.ownerId)
                        _buildMenu(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Actions + caption ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _likeButton(),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.post.likesCount}',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () => context.push('/comments/${widget.post.postId}'),
                      child: const Icon(Icons.mode_comment_outlined,
                          color: Colors.white60, size: 24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.post.commentsCount}',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                    const SizedBox(width: 18),
                    GestureDetector(
                      onTap: () => _sharePost(),
                      child: const Icon(Icons.send_outlined, color: Colors.white60, size: 22),
                    ),
                    const Spacer(),
                    const Icon(Icons.bookmark_border_rounded,
                        color: Colors.white60, size: 24),
                  ],
                ),
                if (widget.post.caption.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                        text: '${widget.post.displayName} ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(
                        text: widget.post.caption,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (widget.post.commentsCount > 0) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => context.push('/comments/${widget.post.postId}'),
                    child: Text(
                      'View all ${widget.post.commentsCount} comments',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _likeButton() {
    return GestureDetector(
      onTap: _isLikeLoading ? null : _handleLike,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: _isLiked
            ? const Icon(Icons.favorite_rounded,
                color: _TC.pink, size: 26, key: ValueKey(true))
            : const Icon(Icons.favorite_border_rounded,
                color: Colors.white60, size: 26, key: ValueKey(false)),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white60, size: 20),
      color: const Color(0xFF2A0040),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: const BoxConstraints(minWidth: 210),
      onSelected: (v) async {
        if (v == 'edit_caption') {
          await _showQuickEditDialog(context, widget.post, 'caption', widget.onRefresh);
        } else if (v == 'edit_location') {
          await _showQuickEditDialog(context, widget.post, 'location', widget.onRefresh);
        } else if (v == 'edit_full') {
          final result = await context.push('/edit-post', extra: widget.post);
          if (result == true) widget.onRefresh?.call();
        } else if (v == 'add_collaborator') {
          _showCollaboratorDialog(context, widget.post);
        } else if (v == 'delete') {
          _showDeleteDialog(context, widget.post, widget.onRefresh);
        }
      },
      itemBuilder: (_) => [
        _mi('edit_caption',    Icons.edit_rounded,       'Edit Caption'),
        _mi('edit_location',   Icons.location_on_rounded,'Edit Location'),
        _mi('edit_full',       Icons.edit_note_rounded,  'Edit All'),
        _mi('add_collaborator',Icons.person_add_rounded, 'Add Collaborator'),
        _miRed('delete',       Icons.delete_rounded,     'Delete Post'),
      ],
    );
  }

  PopupMenuItem<String> _mi(String v, IconData i, String l) => PopupMenuItem(
    value: v,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    child: Row(children: [
      Icon(i, color: Colors.white70, size: 19),
      const SizedBox(width: 12),
      Text(l, style: const TextStyle(color: Colors.white, fontSize: 14)),
    ]),
  );

  PopupMenuItem<String> _miRed(String v, IconData i, String l) => PopupMenuItem(
    value: v,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    child: Row(children: [
      Icon(i, color: Colors.redAccent, size: 19),
      const SizedBox(width: 12),
      Text(l, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
    ]),
  );

  Future<void> _showQuickEditDialog(
      BuildContext context, Post post, String type, VoidCallback? onRefresh) async {
    final ctrl = TextEditingController(
        text: type == 'caption' ? post.caption : (post.location ?? ''));
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C0828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          type == 'caption' ? 'Edit Caption' : 'Edit Location',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: type == 'caption' ? 3 : 1,
          decoration: InputDecoration(
            hintText:
                type == 'caption' ? 'Enter caption...' : 'Enter location...',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _TC.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _TC.pink),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              final value = ctrl.text.trim();
              Navigator.pop(context);
              try {
                if (type == 'caption') {
                  await PostService()
                      .updatePost(postId: post.postId, caption: value);
                } else {
                  await PostService().updatePost(
                    postId: post.postId,
                    location: value.isEmpty ? null : value,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Updated!'),
                      backgroundColor: Colors.green));
                  onRefresh?.call();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text('Save',
                style: TextStyle(
                    color: _TC.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  void _showDeleteDialog(
      BuildContext context, Post post, VoidCallback? onRefresh) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C0828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await PostService().deletePost(post.postId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Post deleted!'),
                      backgroundColor: Colors.green));
                  onRefresh?.call();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCollaboratorDialog(BuildContext context, Post post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C0828),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Collaborator',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
            'Search for a user to invite as a collaborator on this post.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/search-users', extra: {'postId': post.postId});
            },
            child: const Text('Search Users',
                style: TextStyle(
                    color: _TC.pink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Post Shimmer ──────────────────────────────────────────────────────────────
class _PostShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_TC.cardTop, _TC.cardBottom],
          ),
          border: Border.all(color: _TC.cardBorder, width: 0.8),
        ),
        child: Column(
          children: [
            // Fake image area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Container(
                height: 320,
                color: Colors.white.withValues(alpha: 0.06),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                              width: 100, height: 12,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6))),
                          const SizedBox(height: 4),
                          Container(
                              width: 70, height: 10,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(6))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Fake action row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10))),
                  const SizedBox(width: 14),
                  Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _MultiStoryUploadSheet extends ConsumerStatefulWidget {
  final List<File> images;
  final AppUser? currentUser;

  const _MultiStoryUploadSheet({required this.images, required this.currentUser});

  @override
  ConsumerState<_MultiStoryUploadSheet> createState() => _MultiStoryUploadSheetState();
}

class _MultiStoryUploadSheetState extends ConsumerState<_MultiStoryUploadSheet> {
  final StoryService _storyService = StoryService();
  bool _isUploading = false;
  int _uploadedCount = 0;

  Future<void> _uploadAll() async {
    final currentUser = widget.currentUser;
    if (currentUser == null) return;

    setState(() { _isUploading = true; _uploadedCount = 0; });

    int success = 0;
    for (final image in widget.images) {
      try {
        await _storyService.createStory(
          userId: currentUser.uid,
          displayName: currentUser.displayName,
          userProfileImage: currentUser.profileImage ?? '',
          imageFile: image,
        );
        success++;
        if (mounted) setState(() => _uploadedCount = success);
      } catch (e) {
        debugPrint('Failed to upload story: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$success/${widget.images.length} stories uploaded!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _TC.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Upload Stories',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${widget.images.length} selected',
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isDone = _isUploading && index < _uploadedCount;
                final isUploading = _isUploading && index == _uploadedCount;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(widget.images[index],
                          width: 75, height: 100, fit: BoxFit.cover),
                    ),
                    if (isDone)
                      Container(
                        width: 75, height: 100,
                        decoration: BoxDecoration(
                            color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
                      ),
                    if (isUploading)
                      Container(
                        width: 75, height: 100,
                        decoration: BoxDecoration(
                            color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                          child: SizedBox(width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (_isUploading)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadedCount / widget.images.length,
                    backgroundColor: Colors.white12,
                    color: _TC.pink,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Uploading $_uploadedCount of ${widget.images.length}...',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _uploadAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _TC.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Upload All ${widget.images.length} Stories',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
