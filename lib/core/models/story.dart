import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String storyId;
  final String ownerId;
  final String ownerName;
  final String ownerProfileImage;
  final String imageUrl;
  final String caption;
  final String? location;
  final Timestamp expiresAt;
  final Timestamp createdAt;
  final List<String> seenBy;

  const Story({
    required this.storyId,
    required this.ownerId,
    required this.ownerName,
    required this.ownerProfileImage,
    required this.imageUrl,
    this.caption = '',
    this.location,
    required this.expiresAt,
    required this.createdAt,
    this.seenBy = const [],
  });

  factory Story.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Story(
      storyId: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      ownerProfileImage: data['ownerProfileImage'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      location: data['location'],
      expiresAt: data['expiresAt'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
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
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerProfileImage': ownerProfileImage,
      'imageUrl': imageUrl,
      'caption': caption,
      'location': location,
      'expiresAt': expiresAt,
      'createdAt': createdAt,
      'seenBy': seenBy,
    };
  }

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.toDate());
}