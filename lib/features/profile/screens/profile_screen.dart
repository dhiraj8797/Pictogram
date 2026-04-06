import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/services/post_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user.dart';
import '../../../core/models/post.dart';
import '../../../core/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final PostService _postService = PostService();
  final FollowService _followService = FollowService();
  final AuthService _authService = AuthService();

  AppUser? _profileUser;
  List<Post> _userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFollowLoading = false;
  StreamSubscription<QuerySnapshot>? _postsSubscription;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _postsPerPage = 30;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Skeleton loader widget
  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(1),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.0,
        ),
        itemCount: 9, // Show 9 skeleton items
        itemBuilder: (context, index) {
          return Container(
            color: Colors.white,
          );
        },
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState() {
    return Column(
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
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start sharing moments with the world',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => context.push('/upload'),
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Create First Post'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = ref.read(currentUserProvider).value;
      final targetUserId = widget.userId ?? currentUser?.uid;

      if (targetUserId == null) {
        throw Exception('No user ID available');
      }

      // Cancel existing subscription
      await _postsSubscription?.cancel();

      // Load user data
      final userData = await _authService.getUserData(targetUserId);
      if (userData != null) {
        _profileUser = userData;
      }

      // Check follow status for other profiles
      if (currentUser != null && currentUser.uid != targetUserId) {
        _isFollowing = await _followService.isFollowing(currentUser.uid, targetUserId);
      }

      // Set up real-time posts listener
      _postsSubscription = FirebaseFirestore.instance
          .collection('posts')
          .where('ownerId', isEqualTo: targetUserId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _userPosts = snapshot.docs
                .map((doc) => Post.fromFirestore(doc))
                .toList();
            _isLoading = false;
          });
        }
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null || _profileUser == null) return;

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(
          followerId: currentUser.uid,
          followingId: _profileUser!.uid,
        );
      } else {
        await _followService.followUser(
          followerId: currentUser.uid,
          followingId: _profileUser!.uid,
          followerName: currentUser.displayName,
          followerProfileImage: currentUser.profileImage ?? '',
          followingName: _profileUser!.displayName,
          followingProfileImage: _profileUser!.profileImage ?? '',
        );
      }

      setState(() {
        _isFollowing = !_isFollowing;
        
        // Update counts locally for immediate UI feedback
        if (_isFollowing) {
          _profileUser = _profileUser!.copyWith(
            supportersCount: _profileUser!.supportersCount + 1,
          );
        } else {
          _profileUser = _profileUser!.copyWith(
            supportersCount: _profileUser!.supportersCount - 1,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isFollowing ? 'unfollow' : 'follow'}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isOwnProfile = widget.userId == null || widget.userId == currentUser?.uid;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_profileUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('User not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'Your Profile' : _profileUser!.displayName),
        centerTitle: true,
        actions: isOwnProfile
            ? [
                IconButton(
                  onPressed: () {
                    context.push('/settings');
                  },
                  icon: const Icon(Icons.settings),
                )
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Profile Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: isOwnProfile ? () async {
                        final result = await context.push('/edit-profile');
                        // If profile was updated, refresh the profile data
                        if (result == true) {
                          await _loadProfileData();
                        }
                      } : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: _profileUser!.profileImage?.isNotEmpty == true
                                ? CachedNetworkImageProvider(_profileUser!.profileImage!)
                                : null,
                            child: _profileUser!.profileImage?.isEmpty != false
                                ? const Icon(Icons.person, size: 40)
                                : null,
                          ),
                          if (isOwnProfile)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Stats
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            count: _profileUser!.postsCount.toString(),
                            label: 'Posts',
                            onTap: () {
                              // Scroll to posts section
                            },
                          ),
                          _StatItem(
                            count: _profileUser!.supportersCount.toString(),
                            label: 'Supporters',
                            onTap: () {
                              context.push('/followers/${_profileUser!.uid}');
                            },
                          ),
                          _StatItem(
                            count: _profileUser!.circlesCount.toString(),
                            label: 'Circles',
                            onTap: () {
                              context.push('/following/${_profileUser!.uid}');
                            },
                          ),
                        ],
                      ),
                  ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // User Info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and verification badge
                    Row(
                      children: [
                        Text(
                          _profileUser!.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_profileUser!.verificationBadge) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),

                    // Display Name
                    if (_profileUser!.displayName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _profileUser!.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    // Bio
                    if (_profileUser!.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_profileUser!.bio),
                    ],

                    const SizedBox(height: 16),

                    // Action Buttons
                    if (isOwnProfile) ...[
                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result = await context.push('/edit-profile');
                            // If profile was updated, refresh the profile data
                            if (result == true) {
                              await _loadProfileData();
                            }
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                    ] else ...[
                      // Follow/Unfollow Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isFollowLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.grey : Colors.blue,
                            foregroundColor: _isFollowing ? Colors.black : Colors.white,
                          ),
                          child: _isFollowLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isFollowing ? 'Unfollow' : 'Follow'),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Message Button (placeholder)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Messaging coming soon')),
                            );
                          },
                          icon: const Icon(Icons.message_outlined),
                          label: const Text('Message'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Posts Grid
              if (_isLoading) ...[
                // Show skeleton loader while loading
                _buildSkeletonLoader(),
              ] else if (_userPosts.isNotEmpty) ...[
                // Posts Tab Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_on,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_userPosts.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Posts Grid with better performance
                GridView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(1),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                    childAspectRatio: 1.0, // Square aspect ratio
                  ),
                  itemCount: _userPosts.length,
                  itemBuilder: (context, index) {
                    final post = _userPosts[index];
                    return GestureDetector(
                      onTap: () {
                        context.push('/post/${post.postId}');
                      },
                      child: Hero(
                        tag: 'post_${post.postId}',
                        child: AspectRatio(
                          aspectRatio: 1.0, // Ensure square shape
                          child: CachedNetworkImage(
                            imageUrl: post.imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 300, // Optimize cache size
                            memCacheHeight: 300,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey.shade400,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Load more indicator
                if (_isLoadingMore)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                // Empty state
                _buildEmptyState(),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.count,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}