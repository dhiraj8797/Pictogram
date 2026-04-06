import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/post.dart';
import '../models/user.dart';

class ScalabilityService {
  static final ScalabilityService _instance = ScalabilityService._internal();
  factory ScalabilityService() => _instance;
  ScalabilityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Optimized feed loading with multiple strategies
  Future<List<Post>> getOptimizedFeed({
    required String userId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
    FeedStrategy strategy = FeedStrategy.hybrid,
  }) async {
    try {
      switch (strategy) {
        case FeedStrategy.followingOnly:
          return await _getFollowingFeed(userId, limit, lastDocument);
        case FeedStrategy.trendingOnly:
          return await _getTrendingFeed(limit, lastDocument);
        case FeedStrategy.recommendedOnly:
          return await _getRecommendedFeed(userId, limit, lastDocument);
        case FeedStrategy.hybrid:
          return await _getHybridFeed(userId, limit, lastDocument);
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      // Fallback to simple feed
      return await _getSimpleFeed(limit, lastDocument);
    }
  }

  // Following-only feed (most efficient)
  Future<List<Post>> _getFollowingFeed(String userId, int limit, DocumentSnapshot? lastDocument) async {
    try {
      // Get users that current user follows
      final followsQuery = _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .limit(100); // Limit to prevent too many follows
      
      final followsSnapshot = await followsQuery.get();
      final followingIds = followsSnapshot.docs
          .map((doc) => doc['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) {
        return [];
      }

      // Get posts from followed users
      Query postsQuery = _firestore
          .collection('posts')
          .where('ownerId', whereIn: followingIds)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        postsQuery = postsQuery.startAfterDocument(lastDocument);
      }

      final postsSnapshot = await postsQuery.get();
      
      return postsSnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((post) => !post.isExpired)
          .toList();
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return [];
    }
  }

  // Trending feed (algorithm-based)
  Future<List<Post>> _getTrendingFeed(int limit, DocumentSnapshot? lastDocument) async {
    try {
      // Get posts from last 24 hours with high engagement
      final twentyFourHoursAgo = Timestamp.now().toDate().subtract(const Duration(hours: 24));
      
      Query postsQuery = _firestore
          .collection('posts')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
          .orderBy('likesCount', descending: true)
          .orderBy('commentsCount', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        postsQuery = postsQuery.startAfterDocument(lastDocument);
      }

      final postsSnapshot = await postsQuery.get();
      
      return postsSnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((post) => !post.isExpired)
          .toList();
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return [];
    }
  }

  // Recommended feed (ML-based, simplified)
  Future<List<Post>> _getRecommendedFeed(String userId, int limit, DocumentSnapshot? lastDocument) async {
    try {
      // Simplified recommendation: posts from users with similar interests
      // In production, this would use a proper ML model
      
      // Get user's interests (simplified - based on who they follow)
      final followsQuery = _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .limit(50);
      
      final followsSnapshot = await followsQuery.get();
      final followingIds = followsSnapshot.docs
          .map((doc) => doc['followingId'] as String)
          .toList();

      // Get posts from users that followed users also follow (2nd degree connections)
      final recommendedPosts = <Post>[];
      
      for (final followingId in followingIds.take(10)) { // Limit to prevent too many queries
        try {
          final secondDegreeFollows = await _firestore
              .collection('follows')
              .where('followerId', isEqualTo: followingId)
              .limit(20)
              .get();
          
          final secondDegreeIds = secondDegreeFollows.docs
              .map((doc) => doc['followingId'] as String)
              .where((id) => !followingIds.contains(id) && id != userId)
              .toList();

          if (secondDegreeIds.isNotEmpty) {
            final postsQuery = _firestore
                .collection('posts')
                .where('ownerId', whereIn: secondDegreeIds)
                .orderBy('createdAt', descending: true)
                .limit(5); // Limit per user
            
            final postsSnapshot = await postsQuery.get();
            recommendedPosts.addAll(
              postsSnapshot.docs
                  .map((doc) => Post.fromFirestore(doc))
                  .where((post) => !post.isExpired)
            );
          }
        } catch (e) {
          continue; // Skip if one user fails
        }
      }

      // Sort by engagement and limit
      recommendedPosts.sort((a, b) => (b.likesCount + b.commentsCount).compareTo(a.likesCount + a.commentsCount));
      return recommendedPosts.take(limit).toList();
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return [];
    }
  }

  // Hybrid feed (mix of strategies)
  Future<List<Post>> _getHybridFeed(String userId, int limit, DocumentSnapshot? lastDocument) async {
    try {
      // Mix 70% following, 20% trending, 10% recommended
      final followingCount = (limit * 0.7).round();
      final trendingCount = (limit * 0.2).round();
      final recommendedCount = limit - followingCount - trendingCount;

      final followingPosts = await _getFollowingFeed(userId, followingCount, lastDocument);
      final trendingPosts = await _getTrendingFeed(trendingCount, null);
      final recommendedPosts = await _getRecommendedFeed(userId, recommendedCount, null);

      // Combine and deduplicate
      final allPosts = <String, Post>{};
      
      for (final post in followingPosts) {
        allPosts[post.postId] = post;
      }
      
      for (final post in trendingPosts) {
        if (!allPosts.containsKey(post.postId)) {
          allPosts[post.postId] = post;
        }
      }
      
      for (final post in recommendedPosts) {
        if (!allPosts.containsKey(post.postId)) {
          allPosts[post.postId] = post;
        }
      }

      // Sort by creation time and return
      final sortedPosts = allPosts.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return sortedPosts.take(limit).toList();
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return [];
    }
  }

  // Simple fallback feed
  Future<List<Post>> _getSimpleFeed(int limit, DocumentSnapshot? lastDocument) async {
    try {
      Query postsQuery = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        postsQuery = postsQuery.startAfterDocument(lastDocument);
      }

      final postsSnapshot = await postsQuery.get();
      
      return postsSnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .where((post) => !post.isExpired)
          .toList();
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return [];
    }
  }

  // Batch load user data to prevent N+1 queries
  Future<Map<String, AppUser>> batchLoadUserData(List<String> userIds) async {
    try {
      final usersMap = <String, AppUser>{};
      
      // Firestore allows up to 10 items in 'whereIn' query
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        
        final usersQuery = _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch);
        
        final usersSnapshot = await usersQuery.get();
        
        for (final doc in usersSnapshot.docs) {
          final userData = doc.data() as Map<String, dynamic>;
          final user = AppUser(
            uid: doc.id,
            username: userData['username'] ?? '',
            email: userData['email'] ?? '',
            displayName: userData['displayName'] ?? '',
            bio: userData['bio'] ?? '',
            profileImage: userData['profileImage'] ?? '',
            phoneNumber: userData['phoneNumber'] ?? '',
            isVerified: userData['isVerified'] ?? false,
            followersCount: userData['followersCount'] ?? 0,
            followingCount: userData['followingCount'] ?? 0,
            postsCount: userData['postsCount'] ?? 0,
            createdAt: userData['createdAt'] ?? Timestamp.now(),
          );
          usersMap[doc.id] = user;
        }
      }
      
      return usersMap;
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return {};
    }
  }

  // Preload next page for smooth scrolling
  Future<List<Post>> preloadNextPage({
    required String userId,
    required DocumentSnapshot lastDocument,
    int limit = 10,
  }) async {
    try {
      return await getOptimizedFeed(
        userId: userId,
        limit: limit,
        lastDocument: lastDocument,
        strategy: FeedStrategy.followingOnly,
      );
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return [];
    }
  }

  // Monitor feed performance
  Future<void> logFeedPerformance({
    required String userId,
    required FeedStrategy strategy,
    required Duration loadTime,
    required int postCount,
    int? cacheHits,
  }) async {
    try {
      final metrics = {
        'userId': userId,
        'strategy': strategy.toString(),
        'loadTime': loadTime.inMilliseconds,
        'postCount': postCount,
        'cacheHits': cacheHits ?? 0,
        'timestamp': Timestamp.now(),
      };

      await FirebaseCrashlytics.instance.log(
        'Feed Performance: ${strategy.toString()} took ${loadTime.inMilliseconds}ms for $postCount posts'
      );
      
      // Store in Firestore for analysis (in production)
      // await _firestore.collection('feed_performance').add(metrics);
    } catch (e) {
      print('Failed to log feed performance: $e');
    }
  }

  // Get feed strategy based on user behavior
  FeedStrategy getOptimalStrategy({
    required int followingCount,
    required int userActivity,
    required NetworkQuality networkQuality,
  }) {
    // Use simpler strategy for poor network
    if (networkQuality == NetworkQuality.poor || networkQuality == NetworkQuality.none) {
      return FeedStrategy.followingOnly;
    }

    // Use trending for new users with few follows
    if (followingCount < 10) {
      return FeedStrategy.trendingOnly;
    }

    // Use hybrid for active users
    if (userActivity > 50) {
      return FeedStrategy.hybrid;
    }

    // Default to following
    return FeedStrategy.followingOnly;
  }
}

enum FeedStrategy {
  followingOnly,
  trendingOnly,
  recommendedOnly,
  hybrid,
}

// Import NetworkQuality from device optimization service
enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  none,
  unknown,
}
