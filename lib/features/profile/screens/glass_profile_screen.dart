import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/verified_badge.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../core/models/post.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/like_service.dart';
import '../../../core/services/comment_service.dart';
import '../../../core/services/security_service.dart';

// ── Exact Pictogram colour tokens — profile variant (from official design spec) ───────
class _PC {
  // Base backgrounds (profile page has slightly different gradient stops)
  static const bgDark     = Color(0xFF100712);
  static const bgMid      = Color(0xFF160812); // profile: #160812
  static const bgTop      = Color(0xFF260413); // profile: #260413
  // Accent
  static const pink       = Color(0xFFFF3D87);
  static const coral      = Color(0xFFFF6A5C);
  // Glass surfaces — exact Color.fromRGBO spec values
  static const card       = Color.fromRGBO(255, 255, 255, 0.05);
  static const cardBorder = Color.fromRGBO(255, 255, 255, 0.10);
  static const cardTop    = Color.fromRGBO(255, 255, 255, 0.08);
  static const cardBottom = Color.fromRGBO(255, 255, 255, 0.04);
  // Glow — profile uses 0.18 opacity (slightly less than homepage 0.20)
  static const pinkGlow   = Color.fromRGBO(255, 61, 135, 0.18);
}

class GlassProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const GlassProfileScreen({super.key, required this.userId});

  @override
  ConsumerState<GlassProfileScreen> createState() => _GlassProfileScreenState();
}

class _GlassProfileScreenState extends ConsumerState<GlassProfileScreen> {
  late final PostService _postService;
  late final FollowService _followService;
  
  AppUser? _user;
  List<Post> _posts = [];
  bool _isLoading = true;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _postService = PostService();
    _followService = FollowService();
    _loadProfileData();
    SecurityService().enableSecureScreen();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists) {
        _user = AppUser.fromFirestore(userDoc);
      } else {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser != null && currentUser.uid == widget.userId) {
          _user = currentUser;
        } else {
          throw Exception('User not found');
        }
      }

      final postsCount = await _postService.getUserPostsCount(widget.userId);
      final supportersCount = await _followService.getSupportersCount(widget.userId);
      final circlesCount = await _followService.getCirclesCount(widget.userId);

      _user = _user!.copyWith(
        postsCount: postsCount,
        supportersCount: supportersCount,
        circlesCount: circlesCount,
      );

      final posts = await _postService.getUserPosts(
        widget.userId,
        limit: AppConstants.profilePostsLimit,
      );

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isOwnProfile = currentUser?.uid == widget.userId;

    return Scaffold(
      backgroundColor: _PC.bgDark,
      body: Stack(
        children: [
          // Layer 1 – dark linear base (profile-specific stops)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_PC.bgTop, _PC.bgMid, _PC.bgDark],
                stops: [0.0, 0.38, 1.0],
              ),
            ),
          ),
          // Layer 2 – radial pink glow (18% opacity per profile spec)
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -1.0),
                radius: 1.4,
                colors: [_PC.pinkGlow, Colors.transparent],
                stops: [0.0, 0.25],
              ),
            ),
          ),
          // Layer 3 – content
          SafeArea(
            child: _isLoading
                ? const _ProfileLoading()
                : _user == null
                    ? const _ProfileError()
                    : RefreshIndicator(
                        onRefresh: _loadProfileData,
                        color: _PC.pink,
                        backgroundColor: _PC.card,
                        child: CustomScrollView(
                          slivers: [
                            // ── App bar ────────────────────────────────────
                            SliverAppBar(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              pinned: false,
                              floating: true,
                              leading: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: () => context.pop(),
                              ),
                              title: Text(
                                _user!.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              centerTitle: true,
                              actions: [
                                IconButton(
                                  icon: const Icon(Icons.more_horiz_rounded,
                                      color: Colors.white, size: 24),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                            // ── Header card ────────────────────────────────
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: _TrendProfileHeader(
                                  user: _user!,
                                  isOwnProfile: isOwnProfile,
                                  profileUserId: widget.userId,
                                ),
                              ),
                            ),
                            // ── Post grid ──────────────────────────────────
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                                child: _TrendProfileGrid(
                                  posts: _posts,
                                  currentTabIndex: _currentTabIndex,
                                  onTabChanged: (i) =>
                                      setState(() => _currentTabIndex = i),
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 80)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Error states
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _PC.pink,
        strokeWidth: 2,
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile not found',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trendily Profile Header  (avatar + stats + bio + action buttons)
// ─────────────────────────────────────────────────────────────────────────────
class _TrendProfileHeader extends ConsumerStatefulWidget {
  final AppUser user;
  final bool isOwnProfile;
  final String profileUserId;

  const _TrendProfileHeader({
    required this.user,
    required this.isOwnProfile,
    required this.profileUserId,
  });

  @override
  ConsumerState<_TrendProfileHeader> createState() =>
      _TrendProfileHeaderState();
}

class _TrendProfileHeaderState extends ConsumerState<_TrendProfileHeader> {
  late Future<bool> _followingFuture;
  late Future<bool> _theyFollowMeFuture;

  @override
  void initState() {
    super.initState();
    final me = ref.read(currentUserProvider).value;
    final myUid = me?.uid ?? '';
    final theirUid = widget.user.uid;
    _followingFuture = FollowService().isFollowing(myUid, theirUid);
    _theyFollowMeFuture = FollowService().isFollowing(theirUid, myUid);
  }

  Future<void> _refreshFollowing() async {
    final me = ref.read(currentUserProvider).value;
    final myUid = me?.uid ?? '';
    final theirUid = widget.user.uid;
    setState(() {
      _followingFuture = FollowService().isFollowing(myUid, theirUid);
      _theyFollowMeFuture = FollowService().isFollowing(theirUid, myUid);
    });
  }

  String _fmt(int n) =>
      n >= 1000000 ? '${(n / 1000000).toStringAsFixed(1)}M'
      : n >= 1000  ? '${(n / 1000).toStringAsFixed(1)}K'
      : '$n';

  Future<bool> _checkFollowing(String? currentUid) async {
    if (currentUid == null || currentUid == widget.profileUserId) return false;
    try {
      return await FollowService().isFollowing(
          currentUid, widget.profileUserId);
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleFollow(
    BuildContext context,
    String? currentUid,
    bool isFollowing,
  ) async {
    if (currentUid == null) return;

    if (isFollowing) {
      final ok = await _confirmUnfollow(context, widget.user.displayName);
      if (!ok) return;
    }

    try {
      final followService = FollowService();
      final currentUser = ref.read(currentUserProvider).value;
      final profileDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(widget.profileUserId)
          .get();
      final profileUser = AppUser.fromFirestore(profileDoc);

      if (isFollowing) {
        await followService.unfollowUser(
            followerId: currentUid, followingId: widget.profileUserId);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppConstants.unfollowSuccess)),
        );
      } else {
        await followService.followUser(
          followerId: currentUid,
          followingId: widget.profileUserId,
          followerName: currentUser?.displayName ?? '',
          followerProfileImage: currentUser?.profileImage ?? '',
          followingName: profileUser.displayName,
          followingProfileImage: profileUser.profileImage ?? '',
        );
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppConstants.followSuccess)),
        );
      }
      if (context.mounted) {
        context.pushReplacement('/profile/${widget.profileUserId}');
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  Future<bool> _confirmUnfollow(BuildContext context, String name) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C0828),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Unfollow',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            content: Text('Unfollow $name?',
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Unfollow', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_PC.cardTop, _PC.cardBottom],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _PC.cardBorder),
          ),
          child: Column(
            children: [
              // ── Avatar row ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with pink ring
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [_PC.pink, _PC.coral],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _PC.bgMid,
                        ),
                        child: ClipOval(
                          child: widget.user.profileImage != null
                              ? CachedNetworkImage(
                                  imageUrl: widget.user.profileImage!,
                                  fit: BoxFit.cover)
                              : Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.person,
                                      size: 36, color: Colors.white70),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatPill(_fmt(widget.user.postsCount), 'Posts'),
                            _StatPill(_fmt(widget.user.supportersCount),
                                widget.user.followersText),
                            _StatPill(_fmt(widget.user.circlesCount),
                                AppConstants.followingName),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // ── Name + badge ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (widget.user.uid == AppConstants.officialUserId ||
                      widget.user.displayName
                          .toLowerCase()
                          .contains(AppConstants.officialUserKeyword)) ...[
                    const SizedBox(width: 6),
                    const VerifiedBadge(isOfficial: true, size: 20),
                  ] else if (widget.user.verificationBadge) ...[
                    const SizedBox(width: 6),
                    const VerifiedBadge(isOfficial: false, size: 20),
                  ],
                ],
              ),
              if (widget.user.formattedLocation.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.user.formattedLocation,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
              if (widget.user.formattedBio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  widget.user.formattedBio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              // ── Action buttons ─────────────────────────────────────────
              FutureBuilder<List<bool>>(
                future: Future.wait([_followingFuture, _theyFollowMeFuture]),
                builder: (context, snap) {
                  final isFollowing = snap.data?[0] ?? false;
                  final theyFollowMe = snap.data?[1] ?? false;
                  final isMutual = isFollowing && theyFollowMe;
                  if (widget.isOwnProfile) {
                    return _actionRow(
                      context,
                      primary: _PinkBtn(
                        label: 'Edit Profile',
                        onTap: () => context.push(AppConstants.editProfileRoute),
                        outlined: true,
                      ),
                      secondary: _circleBtn(
                        Icons.settings_outlined,
                        () => context.push('/settings'),
                      ),
                    );
                  } else {
                    return _actionRow(
                      context,
                      primary: _PinkBtn(
                        label: isFollowing ? 'Following' : 'Follow',
                        onTap: () => _handleFollow(
                            context, currentUser?.uid, isFollowing),
                        outlined: isFollowing,
                      ),
                      secondary: isMutual
                          ? _circleBtn(
                              Icons.message_rounded,
                              () => _openChat(context, ref, currentUser),
                            )
                          : const SizedBox.shrink(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionRow(BuildContext context,
      {required Widget primary, required Widget secondary}) {
    return Row(
      children: [
        Expanded(child: primary),
        const SizedBox(width: 10),
        secondary,
      ],
    );
  }

  Future<void> _openChat(
      BuildContext context, WidgetRef ref, dynamic currentUser) async {
    if (currentUser == null) return;
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profileUserId)
          .get();
      if (!profileDoc.exists) return;
      final other = AppUser.fromFirestore(profileDoc);
      final chatId = await ChatService().getOrCreateChat(
        myUid: currentUser.uid,
        myName: currentUser.displayName ?? '',
        myPhoto: currentUser.profileImage ?? '',
        otherUid: widget.profileUserId,
        otherName: other.displayName,
        otherPhoto: other.profileImage ?? '',
      );
      if (context.mounted) {
        context.push('/chat/$chatId', extra: {
          'otherName': other.displayName,
          'otherPhoto': other.profileImage ?? '',
          'otherUid': widget.profileUserId,
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _circleBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_PC.cardTop, _PC.cardBottom],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _PC.cardBorder),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }
}

class _PinkBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;

  const _PinkBtn({required this.label, this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: outlined
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_PC.cardTop, _PC.cardBottom],
                    )
                  : const LinearGradient(
                      colors: [_PC.pink, _PC.coral],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              borderRadius: BorderRadius.circular(14),
              border: outlined ? Border.all(color: _PC.cardBorder) : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                color: outlined ? Colors.white70 : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trendily Profile Grid  (pill tabs + post thumbnails)
// ─────────────────────────────────────────────────────────────────────────────
class _TrendProfileGrid extends StatelessWidget {
  final List<Post> posts;
  final int currentTabIndex;
  final Function(int) onTabChanged;

  const _TrendProfileGrid({
    required this.posts,
    required this.currentTabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['Posts', 'Saved', 'Tagged'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pill tab row ──────────────────────────────────────────────────
        Row(
          children: [
            // Tab pills
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_PC.cardTop, _PC.cardBottom],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: _PC.cardBorder),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: List.generate(tabs.length, (i) {
                        final active = currentTabIndex == i;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => onTabChanged(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              alignment: Alignment.center,
                              height: 36,
                              decoration: BoxDecoration(
                                color: active ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                tabs[i],
                                style: TextStyle(
                                  color: active ? Colors.black : Colors.white70,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Item count badge
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [_PC.cardTop, _PC.cardBottom],
                    ),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: _PC.cardBorder),
                  ),
                  child: Text(
                    '${currentTabIndex == 0 ? posts.length : 0} items',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Grid content ─────────────────────────────────────────────────
        if (currentTabIndex == 0)
          posts.isEmpty
              ? _emptyState('No posts yet', 'Your photos will appear here.')
              : _MagazineGrid(posts: posts)
        else
          _emptyState('No content yet',
              'Your database results will appear here automatically.'),
      ],
    );
  }

  Widget _emptyState(String title, String sub) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_PC.cardTop, _PC.cardBottom],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _PC.cardBorder),
          ),
          child: Column(
            children: [
              const Icon(Icons.photo_library_outlined,
                  color: Colors.white24, size: 44),
              const SizedBox(height: 14),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Magazine Grid
// Pattern A (group 0,2,4…): [large left | small top-right + small bot-right]
// Pattern B (group 1,3,5…): [small top-left + small bot-left | large right]
// ─────────────────────────────────────────────────────────────────────────────
class _MagazineGrid extends StatelessWidget {
  final List<Post> posts;
  const _MagazineGrid({required this.posts});

  @override
  Widget build(BuildContext context) {
    const double gap = 4;
    final double fullW =
        MediaQuery.of(context).size.width - 32; // 16px padding each side
    final double cellW = (fullW - gap) / 2;
    final double smallH = cellW * 0.72; // small cell height
    final double largeH = smallH * 2 + gap; // large spans both small rows

    final List<Widget> rows = [];

    for (int i = 0; i < posts.length; i += 3) {
      final bool patternA = (i ~/ 3) % 2 == 0;
      final Post? p1 = i < posts.length ? posts[i] : null;
      final Post? p2 = i + 1 < posts.length ? posts[i + 1] : null;
      final Post? p3 = i + 2 < posts.length ? posts[i + 2] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: gap),
          child: patternA
              // ── Pattern A: large LEFT, two small RIGHT ───────────────────
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p1 != null)
                      SizedBox(
                        width: cellW,
                        height: largeH,
                        child: _PostThumb(post: p1, isLarge: true),
                      ),
                    const SizedBox(width: gap),
                    SizedBox(
                      width: cellW,
                      child: Column(
                        children: [
                          if (p2 != null)
                            SizedBox(
                                height: smallH,
                                child: _PostThumb(post: p2)),
                          const SizedBox(height: gap),
                          SizedBox(
                              height: smallH,
                              child: p3 != null
                                  ? _PostThumb(post: p3)
                                  : const SizedBox()),
                        ],
                      ),
                    ),
                  ],
                )
              // ── Pattern B: two small LEFT, large RIGHT ───────────────────
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: cellW,
                      child: Column(
                        children: [
                          if (p1 != null)
                            SizedBox(
                                height: smallH,
                                child: _PostThumb(post: p1)),
                          const SizedBox(height: gap),
                          SizedBox(
                              height: smallH,
                              child: p2 != null
                                  ? _PostThumb(post: p2)
                                  : const SizedBox()),
                        ],
                      ),
                    ),
                    const SizedBox(width: gap),
                    if (p3 != null)
                      SizedBox(
                        width: cellW,
                        height: largeH,
                        child: _PostThumb(post: p3, isLarge: true),
                      ),
                  ],
                ),
        ),
      );
    }

    return Column(children: rows);
  }
}

class _PostThumb extends StatelessWidget {
  final Post post;
  final bool isLarge;
  const _PostThumb({required this.post, this.isLarge = false});

  static String _fmtViews(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/post/${post.postId}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            post.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: post.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: _PC.card,
                      child: const Center(
                        child: CircularProgressIndicator(
                            color: _PC.pink, strokeWidth: 1.5),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: _PC.card,
                      child: const Icon(Icons.broken_image,
                          color: Colors.white24, size: 26),
                    ),
                  )
                : Container(
                    color: _PC.card,
                    child:
                        const Icon(Icons.image, color: Colors.white24, size: 26),
                  ),
            // View count badge (bottom left)
            Positioned(
              bottom: 6,
              left: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye_rounded,
                        color: Colors.white70, size: 10),
                    const SizedBox(width: 3),
                    Text(
                      _fmtViews(post.viewsCount),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            // Pin badge on large cells
            if (isLarge)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18), width: 0.6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.push_pin_rounded,
                          color: _PC.pink, size: 11),
                      SizedBox(width: 3),
                      Text('Pinned',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
