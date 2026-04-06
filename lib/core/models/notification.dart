import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String notificationId;
  final String userId;
  final String type;
  final String actorId;
  final String actorName;
  final String actorProfileImage;
  final String? postId;
  final String? commentId;
  final String? message;
  final Timestamp createdAt;
  final bool isRead;

  const AppNotification({
    required this.notificationId,
    required this.userId,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.actorProfileImage,
    this.postId,
    this.commentId,
    this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppNotification(
      notificationId: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? '',
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorProfileImage: data['actorProfileImage'] ?? '',
      postId: data['postId'],
      commentId: data['commentId'],
      message: data['message'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'actorId': actorId,
      'actorName': actorName,
      'actorProfileImage': actorProfileImage,
      'postId': postId,
      'commentId': commentId,
      'message': message,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }

  AppNotification copyWith({
    bool? isRead,
    String? message,
  }) {
    return AppNotification(
      notificationId: notificationId,
      userId: userId,
      type: type,
      actorId: actorId,
      actorName: actorName,
      actorProfileImage: actorProfileImage,
      postId: postId,
      commentId: commentId,
      message: message ?? this.message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationType {
  static const String like = 'like';
  static const String comment = 'comment';
  static const String follow = 'follow';
  static const String mention = 'mention';
  static const String storyReaction = 'story_reaction';
}