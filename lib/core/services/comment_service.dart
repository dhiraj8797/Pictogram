import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../models/notification.dart';
import 'firebase_service.dart';
import 'notification_service.dart';
import 'backend_rate_limit_service.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final NotificationService _notificationService = NotificationService();
  final BackendRateLimitService _backendRateLimit = BackendRateLimitService();

  // Create a comment with backend enforcement
  Future<Comment> createComment({
    required String postId,
    required String userId,
    required String username,
    required String userProfileImage,
    required String text,
    required bool isVerifiedComment,
  }) async {
    try {
      // Check if user can comment (backend enforced)
      final canComment = await _backendRateLimit.canUserComment(userId);
      if (!canComment) {
        throw Exception('You have exceeded the comment limit. Please wait before commenting again.');
      }

      // Check if user is blocked (backend enforced)
      if (await _backendRateLimit.isUserBlocked(userId)) {
        throw Exception('Your account has been restricted from commenting.');
      }

      // Validate comment text
      if (text.trim().isEmpty) {
        throw Exception('Comment cannot be empty');
      }

      if (text.length > 300) {
        throw Exception('Comment is too long (max 300 characters)');
      }

      // Check for spam content (backend enforced)
      if (await _backendRateLimit.isContentSpam(text, userId)) {
        throw Exception('Comment contains inappropriate content');
      }

      // Check if user is verified for commenting
      if (!isVerifiedComment) {
        throw Exception('Only verified users can comment. Please complete Aadhaar verification to comment on posts.');
      }

      // Validate post exists
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      final postOwnerId = postData['ownerId'] ?? '';

      // Check for duplicate comments (same user, same post, similar text)
      final recentComments = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 5))))
          .get();

      for (final comment in recentComments.docs) {
        final commentData = comment.data() as Map<String, dynamic>;
        final existingText = commentData['text'] as String;
        if (existingText.toLowerCase() == text.toLowerCase()) {
          throw Exception('You have already posted this comment');
        }
      }

      // Create comment document
      final commentRef = _firestore.collection('comments').doc();
      final comment = Comment(
        commentId: commentRef.id,
        postId: postId,
        userId: userId,
        username: username,
        userProfileImage: userProfileImage,
        text: text.trim(),
        isVerifiedComment: isVerifiedComment,
        likesCount: 0,
        createdAt: Timestamp.now(),
      );

      await _firestore.runTransaction((transaction) async {
        // Create comment
        transaction.set(commentRef, comment.toFirestore());

        // Increment post's comments count
        final postRef = _firestore.collection('posts').doc(postId);
        transaction.update(postRef, {
          'commentsCount': FieldValue.increment(1),
        });
      });

      // Create notification for post owner (if not own comment) - backend enforced
      if (postOwnerId != userId && postOwnerId.isNotEmpty) {
        try {
          // Get current user info for notification
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            final displayName = userData['displayName'] ?? username;
            final profileImage = userData['profileImage'] ?? userProfileImage;

            await _notificationService.createCommentNotification(
              postOwnerId: postOwnerId,
              commenterId: userId,
              commenterUsername: displayName,
              commenterProfileImage: profileImage,
              postId: postId,
              commentId: commentRef.id,
            );
          }
        } catch (e) {
          print('Failed to create comment notification: $e');
        }
      }

      return comment;
    } catch (e) {
      throw Exception('Failed to create comment: $e');
    }
  }

  // Get comments for a post
  Future<List<Comment>> getCommentsForPost(
    String postId, {
    int limit = 20,
    Timestamp? lastTimestamp,
  }) async {
    try {
      Query query = _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false) // Newest comments last (like Instagram)
          .limit(limit);

      if (lastTimestamp != null) {
        query = query.startAfter([lastTimestamp]);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Comment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  // Like/unlike a comment
  Future<void> toggleCommentLike(String commentId, String userId) async {
    try {
      final commentRef = _firestore.collection('comments').doc(commentId);
      final likeRef = commentRef.collection('likes').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final commentDoc = await transaction.get(commentRef);
        final likeDoc = await likeRef.get();

        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        if (likeDoc.exists) {
          // Unlike
          transaction.delete(likeRef);
          transaction.update(commentRef, {
            'likesCount': FieldValue.increment(-1),
          });
        } else {
          // Like
          transaction.set(likeRef, {
            'userId': userId,
            'createdAt': Timestamp.now(),
          });
          transaction.update(commentRef, {
            'likesCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle comment like: $e');
    }
  }

  // Check if user liked a comment
  Future<bool> isCommentLiked(String commentId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('comments')
          .doc(commentId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('comments').doc(commentId);
        final commentDoc = await transaction.get(commentRef);

        if (!commentDoc.exists) {
          throw Exception('Comment not found');
        }

        final commentData = commentDoc.data() as Map<String, dynamic>;
        final commentUserId = commentData['userId'] ?? '';
        final postId = commentData['postId'] ?? '';

        // Check if user is the owner
        if (commentUserId != userId) {
          throw Exception('You can only delete your own comments');
        }

        // Delete comment
        transaction.delete(commentRef);

        // Decrement post's comments count
        final postRef = _firestore.collection('posts').doc(postId);
        transaction.update(postRef, {
          'commentsCount': FieldValue.increment(-1),
        });
      });
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>;
        return postData['commentsCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Report a comment
  Future<void> reportComment(String commentId, String userId, String reason) async {
    try {
      await _firestore.collection('comment_reports').add({
        'commentId': commentId,
        'reporterId': userId,
        'reason': reason,
        'createdAt': Timestamp.now(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to report comment: $e');
    }
  }

  // Get user's comments
  Future<List<Comment>> getUserComments(String userId, {int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Comment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user comments: $e');
    }
  }

  // Search comments by text
  Future<List<Comment>> searchComments(String postId, String query, {int limit = 10}) async {
    try {
      // Note: This is a simplified search. In production, you might want to use
      // a more sophisticated search solution like Algolia or Elasticsearch
      final querySnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: true)
          .limit(100) // Get recent comments to search through
          .get();

      final allComments = querySnapshot.docs
          .map((doc) => Comment.fromFirestore(doc))
          .toList();

      // Filter comments that contain the query (case-insensitive)
      final filteredComments = allComments
          .where((comment) => comment.text.toLowerCase().contains(query.toLowerCase()))
          .take(limit)
          .toList();

      return filteredComments;
    } catch (e) {
      throw Exception('Failed to search comments: $e');
    }
  }
}
