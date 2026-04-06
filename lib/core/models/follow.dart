import 'package:cloud_firestore/cloud_firestore.dart';

class Follow {
  final String followId;
  final String followerId;
  final String followingId;

  // For fast UI rendering
  final String followerName;
  final String followerProfileImage;

  final String followingName;
  final String followingProfileImage;

  final Timestamp createdAt;

  const Follow({
    required this.followId,
    required this.followerId,
    required this.followingId,
    required this.followerName,
    required this.followerProfileImage,
    required this.followingName,
    required this.followingProfileImage,
    required this.createdAt,
  });

  factory Follow.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Follow(
      followId: doc.id,
      followerId: data['followerId'] ?? '',
      followingId: data['followingId'] ?? '',
      followerName: data['followerName'] ?? '',
      followerProfileImage: data['followerProfileImage'] ?? '',
      followingName: data['followingName'] ?? '',
      followingProfileImage: data['followingProfileImage'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'followerName': followerName,
      'followerProfileImage': followerProfileImage,
      'followingName': followingName,
      'followingProfileImage': followingProfileImage,
      'createdAt': createdAt,
    };
  }
}