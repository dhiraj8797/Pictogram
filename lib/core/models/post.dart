import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String postId;
  final String ownerId;
  final String ownerName;
  final String ownerProfileImage;
  final String imageUrl;
  final String caption;
  final String? location;
  final List<String> tags;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int viewsCount;
  final List<String> collaboratorIds;
  final double? imageAspectRatio;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final DocumentSnapshot? documentSnapshot;

  const Post({
    required this.postId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerProfileImage,
    required this.imageUrl,
    this.caption = '',
    this.location,
    this.tags = const [],
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.viewsCount = 0,
    this.collaboratorIds = const [],
    this.imageAspectRatio,
    required this.createdAt,
    this.updatedAt,
    this.documentSnapshot,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Post(
      postId: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerProfileImage: data['ownerProfileImage'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      location: data['location'],
      tags: List<String>.from(data['tags'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
      viewsCount: data['viewsCount'] ?? 0,
      collaboratorIds: List<String>.from(data['collaboratorIds'] ?? []),
      imageAspectRatio: (data['imageAspectRatio'] as num?)?.toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      documentSnapshot: doc,
    );
  }

  // Get display name with fallback
  String get displayName {
    if (ownerName.isNotEmpty && ownerName != 'Unknown') {
      return ownerName;
    }
    return 'User';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerProfileImage': ownerProfileImage,
      'imageUrl': imageUrl,
      'caption': caption,
      if (location != null) 'location': location,
      'tags': tags,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'viewsCount': viewsCount,
      if (imageAspectRatio != null) 'imageAspectRatio': imageAspectRatio,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  Post copyWith({
    String? postId,
    String? ownerId,
    String? ownerName,
    String? ownerProfileImage,
    String? imageUrl,
    String? caption,
    String? location,
    List<String>? tags,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? viewsCount,
    double? imageAspectRatio,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Post(
      postId: postId ?? this.postId,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerProfileImage: ownerProfileImage ?? this.ownerProfileImage,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      imageAspectRatio: imageAspectRatio ?? this.imageAspectRatio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}