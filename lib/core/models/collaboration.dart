import 'package:cloud_firestore/cloud_firestore.dart';

/// Collaboration invite status
class CollaborationStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
}

/// Model for collaboration invites between users for posts
class Collaboration {
  final String collaborationId;
  final String postId;
  final String postOwnerId;
  final String postOwnerName;
  final String postOwnerProfileImage;
  final String invitedUserId;
  final String invitedUserName;
  final String invitedUserProfileImage;
  final String status; // pending, accepted, rejected, cancelled
  final Timestamp createdAt;
  final Timestamp? respondedAt;
  final String? message; // Optional message from inviter

  const Collaboration({
    required this.collaborationId,
    required this.postId,
    required this.postOwnerId,
    required this.postOwnerName,
    required this.postOwnerProfileImage,
    required this.invitedUserId,
    required this.invitedUserName,
    required this.invitedUserProfileImage,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.message,
  });

  factory Collaboration.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Collaboration(
      collaborationId: doc.id,
      postId: data['postId'] ?? '',
      postOwnerId: data['postOwnerId'] ?? '',
      postOwnerName: data['postOwnerName'] ?? '',
      postOwnerProfileImage: data['postOwnerProfileImage'] ?? '',
      invitedUserId: data['invitedUserId'] ?? '',
      invitedUserName: data['invitedUserName'] ?? '',
      invitedUserProfileImage: data['invitedUserProfileImage'] ?? '',
      status: data['status'] ?? CollaborationStatus.pending,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      respondedAt: data['respondedAt'],
      message: data['message'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'postOwnerId': postOwnerId,
      'postOwnerName': postOwnerName,
      'postOwnerProfileImage': postOwnerProfileImage,
      'invitedUserId': invitedUserId,
      'invitedUserName': invitedUserName,
      'invitedUserProfileImage': invitedUserProfileImage,
      'status': status,
      'createdAt': createdAt,
      if (respondedAt != null) 'respondedAt': respondedAt,
      if (message != null) 'message': message,
    };
  }

  Collaboration copyWith({
    String? status,
    Timestamp? respondedAt,
    String? message,
  }) {
    return Collaboration(
      collaborationId: collaborationId,
      postId: postId,
      postOwnerId: postOwnerId,
      postOwnerName: postOwnerName,
      postOwnerProfileImage: postOwnerProfileImage,
      invitedUserId: invitedUserId,
      invitedUserName: invitedUserName,
      invitedUserProfileImage: invitedUserProfileImage,
      status: status ?? this.status,
      createdAt: createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }

  bool get isPending => status == CollaborationStatus.pending;
  bool get isAccepted => status == CollaborationStatus.accepted;
  bool get isRejected => status == CollaborationStatus.rejected;
  bool get isCancelled => status == CollaborationStatus.cancelled;
}
