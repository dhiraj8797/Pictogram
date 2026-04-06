import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';
import 'firebase_service.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Create notification with spam prevention
  Future<void> createNotification({
    required String userId,
    required String type,
    required String actorId,
    required String actorName,
    required String actorProfileImage,
    required String message,
    String? postId,
    String? commentId,
  }) async {
    try {
      print('DEBUG: Creating notification - userId: $userId, type: $type, actorId: $actorId');
      
      // Don't create notification if user is acting on their own content
      if (userId == actorId) {
        print('DEBUG: Skipping notification - user is acting on their own content');
        return;
      }

      // For likes and comments, check for duplicate notifications
      if (type == 'like' || type == 'comment') {
        // Use only 2-field query to avoid index requirement
        final existingNotifications = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: type)
            .get();

        // Filter all other conditions on client side
        final duplicateNotifications = existingNotifications.docs.where((doc) {
          final data = doc.data();
          return data['actorId'] == actorId && 
                 data['postId'] == postId && 
                 data['isRead'] == false;
        });

        if (duplicateNotifications.isNotEmpty) {
          return; // Don't create duplicate like/comment notification
        }
      }

      // For follows, check if already following
      if (type == 'follow') {
        // Use only 2-field query to avoid index requirement
        final existingFollowNotifications = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: type)
            .get();

        // Filter all other conditions on client side
        final existingUnreadFollows = existingFollowNotifications.docs.where((doc) {
          final data = doc.data();
          return data['actorId'] == actorId && data['isRead'] == false;
        });

        if (existingUnreadFollows.isNotEmpty) {
          return; // Don't create duplicate follow notification
        }
      }

      final notificationRef = _firestore.collection('notifications').doc();
      final notification = AppNotification(
        notificationId: notificationRef.id,
        userId: userId,
        type: type,
        actorId: actorId,
        actorName: actorName,
        actorProfileImage: actorProfileImage,
        postId: postId,
        commentId: commentId,
        message: message,
        isRead: false,
        createdAt: Timestamp.now(),
      );

      print('DEBUG: Saving notification to Firestore - ID: ${notificationRef.id}');
      await notificationRef.set(notification.toFirestore());
      print('DEBUG: Notification saved successfully to Firestore');
    } catch (e) {
      print('DEBUG: Error creating notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get user notifications
  Future<List<AppNotification>> getUserNotifications(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      // Try the optimized query with composite index first
      Query query = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
    } catch (e) {
      // If composite index error, fall back to simple query + client-side sort
      if (e.toString().contains('failed-precondition') || 
          e.toString().contains('index') ||
          e.toString().contains('requires an index')) {
        print('DEBUG: Falling back to simple query without index');
        
        final querySnapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();
        
        final notifications = querySnapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList();
        
        // Sort client-side by createdAt descending
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Apply limit after sorting
        if (notifications.length > limit) {
          return notifications.sublist(0, limit);
        }
        return notifications;
      }
      
      throw Exception('Failed to get user notifications: $e');
    }
  }

  // Get unread notifications count
  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      // Use single-field query to avoid index requirement
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      // Filter unread notifications on client side
      final unreadCount = querySnapshot.docs
          .where((doc) => doc.data()['isRead'] == false)
          .length;

      return unreadCount;
    } catch (e) {
      throw Exception('Failed to get unread notifications count: $e');
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Clear all notifications for user
  Future<void> clearAllNotifications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear all notifications: $e');
    }
  }

  // Create like notification
  Future<void> createLikeNotification({
    required String postOwnerId,
    required String likerId,
    required String likerName,
    required String likerProfileImage,
    required String postId,
  }) async {
    await createNotification(
      userId: postOwnerId,
      type: 'like',
      actorId: likerId,
      actorName: likerName,
      actorProfileImage: likerProfileImage,
      message: '$likerName liked your post',
      postId: postId,
    );
  }

  // Create comment notification
  Future<void> createCommentNotification({
    required String postOwnerId,
    required String commenterId,
    required String commenterUsername,
    required String commenterProfileImage,
    required String postId,
    required String commentId,
  }) async {
    await createNotification(
      userId: postOwnerId,
      type: 'comment',
      actorId: commenterId,
      actorName: commenterUsername,
      actorProfileImage: commenterProfileImage,
      message: '$commenterUsername commented on your post',
      postId: postId,
      commentId: commentId,
    );
  }

  // Create follow notification
  Future<void> createFollowNotification({
    required String followedUserId,
    required String followerId,
    required String followerUsername,
    required String followerProfileImage,
  }) async {
    await createNotification(
      userId: followedUserId,
      type: 'follow',
      actorId: followerId,
      actorName: followerUsername,
      actorProfileImage: followerProfileImage,
      message: '$followerUsername started following you',
    );
  }

  // Create mention notification
  Future<void> createMentionNotification({
    required String mentionedUserId,
    required String mentionerId,
    required String mentionerUsername,
    required String mentionerProfileImage,
    required String postId,
    required String commentId,
  }) async {
    await createNotification(
      userId: mentionedUserId,
      type: 'mention',
      actorId: mentionerId,
      actorName: mentionerUsername,
      actorProfileImage: mentionerProfileImage,
      message: '$mentionerUsername mentioned you in a comment',
      postId: postId,
    );
  }

  // Real-time notification stream
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc))
          .toList();
      // Sort by createdAt descending
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  // Real-time unread count stream
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
