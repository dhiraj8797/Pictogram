import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String userId;
  final String username;
  final String userProfileImage;
  final String text;
  final bool isVerifiedComment;
  final int likesCount;
  final Timestamp createdAt;

  const Comment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.username,
    required this.userProfileImage,
    required this.text,
    this.isVerifiedComment = false,
    this.likesCount = 0,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Comment(
      commentId: doc.id,
      postId: data['postId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      userProfileImage: data['userProfileImage'] ?? '',
      text: data['text'] ?? '',
      isVerifiedComment: data['isVerifiedComment'] ?? false,
      likesCount: data['likesCount'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'username': username,
      'userProfileImage': userProfileImage,
      'text': text,
      'isVerifiedComment': isVerifiedComment,
      'likesCount': likesCount,
      'createdAt': createdAt,
    };
  }

  Comment copyWith({
    String? text,
    bool? isVerifiedComment,
    int? likesCount,
  }) {
    return Comment(
      commentId: commentId,
      postId: postId,
      userId: userId,
      username: username,
      userProfileImage: userProfileImage,
      text: text ?? this.text,
      isVerifiedComment: isVerifiedComment ?? this.isVerifiedComment,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt,
    );
  }
}