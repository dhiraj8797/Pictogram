import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import './firebase_service.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);

      await _firestore.runTransaction((transaction) async {
        // Add like document
        transaction.set(likeRef, {
          'userId': userId,
          'createdAt': Timestamp.now(),
        });

        // Increment post's likes count
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(1),
        });
      });

      print('DEBUG: User $userId liked post $postId');
    } catch (e) {
      print('DEBUG: Error liking post: $e');
      throw Exception('Failed to like post: $e');
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);

      await _firestore.runTransaction((transaction) async {
        // Remove like document
        transaction.delete(likeRef);

        // Decrement post's likes count
        transaction.update(postRef, {
          'likesCount': FieldValue.increment(-1),
        });
      });

      print('DEBUG: User $userId unliked post $postId');
    } catch (e) {
      print('DEBUG: Error unliking post: $e');
      throw Exception('Failed to unlike post: $e');
    }
  }

  // Check if user has liked a post
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('DEBUG: Error checking if post is liked: $e');
      return false;
    }
  }

  // Get post likes count
  Future<int> getPostLikesCount(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      
      if (postDoc.exists) {
        final data = postDoc.data() as Map<String, dynamic>;
        return data['likesCount'] ?? 0;
      }
      
      return 0;
    } catch (e) {
      print('DEBUG: Error getting post likes count: $e');
      return 0;
    }
  }

  // Get users who liked a post
  Future<List<AppUser>> getPostLikers(String postId, {int limit = 20}) async {
    try {
      final likesSnapshot = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      List<AppUser> likers = [];
      
      for (var likeDoc in likesSnapshot.docs) {
        final userId = likeDoc['userId'] as String;
        final userDoc = await _firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          likers.add(AppUser.fromFirestore(userDoc));
        }
      }

      return likers;
    } catch (e) {
      print('DEBUG: Error getting post likers: $e');
      throw Exception('Failed to get post likers: $e');
    }
  }

  // Get user's liked posts
  Future<List<String>> getUserLikedPosts(String userId, {int limit = 50}) async {
    try {
      final userLikesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('likedPosts')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return userLikesSnapshot.docs
          .map((doc) => doc['postId'] as String)
          .toList();
    } catch (e) {
      print('DEBUG: Error getting user liked posts: $e');
      return [];
    }
  }
}

// Provider for LikeService
final likeServiceProvider = Provider<LikeService>((ref) {
  return LikeService();
});
