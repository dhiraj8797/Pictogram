import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/follow.dart';
import '../models/user.dart';
import '../models/notification.dart';
import 'firebase_service.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Check if current user follows target user
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final querySnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .where('followingId', isEqualTo: targetUserId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check follow status: $e');
    }
  }

  // Follow a user with transaction-safe counter updates
  Future<void> followUser({
    required String followerId,
    required String followingId,
    required String followerName,
    required String followerProfileImage,
    required String followingName,
    required String followingProfileImage,
  }) async {
    if (followerId == followingId) {
      throw Exception('You cannot follow yourself');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // Check if already following
        final followsQuery = await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: followerId)
            .where('followingId', isEqualTo: followingId)
            .limit(1)
            .get();

        if (followsQuery.docs.isNotEmpty) {
          throw Exception('You are already following this user');
        }

        // Get user documents for counter updates
        final followerRef = _firestore.collection('users').doc(followerId);
        final followingRef = _firestore.collection('users').doc(followingId);

        final followerDoc = await transaction.get(followerRef);
        final followingDoc = await transaction.get(followingRef);

        if (!followerDoc.exists || !followingDoc.exists) {
          throw Exception('User not found');
        }

        // Create follow document
        final followRef = _firestore.collection('follows').doc();
        final follow = Follow(
          followId: followRef.id,
          followerId: followerId,
          followingId: followingId,
          followerName: followerName,
          followerProfileImage: followerProfileImage,
          followingName: followingName,
          followingProfileImage: followingProfileImage,
          createdAt: Timestamp.now(),
        );

        transaction.set(followRef, follow.toFirestore());

        // Update counters
        transaction.update(followerRef, {
          'circlesCount': FieldValue.increment(1),
        });

        transaction.update(followingRef, {
          'supportersCount': FieldValue.increment(1),
        });

        // Create notification
        final notificationRef = _firestore.collection('notifications').doc();
        final notification = AppNotification(
          notificationId: notificationRef.id,
          userId: followingId, // The person being followed gets notification
          type: 'follow',
          actorId: followerId,
          actorName: followerName,
          actorProfileImage: followerProfileImage,
          message: '$followerName started following you',
          isRead: false,
          createdAt: Timestamp.now(),
        );

        transaction.set(notificationRef, notification.toFirestore());
      });
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  // Unfollow a user with transaction-safe counter updates
  Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Find the follow document
        final followsQuery = await _firestore
            .collection('follows')
            .where('followerId', isEqualTo: followerId)
            .where('followingId', isEqualTo: followingId)
            .limit(1)
            .get();

        if (followsQuery.docs.isEmpty) {
          throw Exception('You are not following this user');
        }

        final followDoc = followsQuery.docs.first;
        final followRef = _firestore.collection('follows').doc(followDoc.id);

        // Get user documents for counter updates
        final followerRef = _firestore.collection('users').doc(followerId);
        final followingRef = _firestore.collection('users').doc(followingId);

        final followerDoc = await transaction.get(followerRef);
        final followingDoc = await transaction.get(followingRef);

        if (!followerDoc.exists || !followingDoc.exists) {
          throw Exception('User not found');
        }

        // Delete follow document
        transaction.delete(followRef);

        // Update counters
        transaction.update(followerRef, {
          'circlesCount': FieldValue.increment(-1),
        });

        transaction.update(followingRef, {
          'supportersCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  // Get user's followers (people who follow this user)
  Future<List<Follow>> getUserFollowers(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Follow.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user followers: $e');
    }
  }

  // Get user's following (people this user follows)
  Future<List<Follow>> getUserFollowing(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Follow.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user following: $e');
    }
  }

  // Get follow suggestions (people you might know)
  Future<List<AppUser>> getFollowSuggestions(String userId, {int limit = 10}) async {
    try {
      // Get users that current user follows
      final followingQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .limit(20)
          .get();

      final followingIds = followingQuery.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followingId'] as String)
          .toList();

      // Get followers of people you follow (friends of friends)
      if (followingIds.isEmpty) {
        // If user doesn't follow anyone, return random users
        final querySnapshot = await _firestore
            .collection('users')
            .where('uid', isNotEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();

        return querySnapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .toList();
      }

      final suggestionsQuery = await _firestore
          .collection('follows')
          .where('followerId', whereIn: followingIds)
          .where('followingId', isNotEqualTo: userId)
          .limit(limit * 2)
          .get();

      final suggestedUserIds = suggestionsQuery.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followingId'] as String)
          .toSet()
          .toList();

      // Remove users already followed and self
      suggestedUserIds.remove(userId);
      followingIds.forEach((id) => suggestedUserIds.remove(id));

      if (suggestedUserIds.isEmpty) {
        return [];
      }

      // Get user documents for suggestions
      final usersQuery = await _firestore
          .collection('users')
          .where('uid', whereIn: suggestedUserIds.take(limit).toList())
          .get();

      return usersQuery.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get follow suggestions: $e');
    }
  }

  // Get mutual followers between two users
  Future<List<AppUser>> getMutualFollowers(String userId1, String userId2, {int limit = 10}) async {
    try {
      // Get followers of user1
      final followers1Query = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId1)
          .get();

      final followers1Ids = followers1Query.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followerId'] as String)
          .toSet();

      // Get followers of user2
      final followers2Query = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId2)
          .get();

      final followers2Ids = followers2Query.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followerId'] as String)
          .toSet();

      // Find intersection (mutual followers)
      final mutualIds = followers1Ids.intersection(followers2Ids).toList();

      if (mutualIds.isEmpty) {
        return [];
      }

      // Get user documents for mutual followers
      final usersQuery = await _firestore
          .collection('users')
          .where('uid', whereIn: mutualIds.take(limit).toList())
          .get();

      return usersQuery.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get mutual followers: $e');
    }
  }
  
  // Get user's supporters (followers) count
  Future<int> getSupportersCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: userId)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get supporters count: $e');
    }
  }

  // Get user's circles (following) count
  Future<int> getCirclesCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get circles count: $e');
    }
  }
}
