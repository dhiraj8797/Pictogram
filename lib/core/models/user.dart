import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String? phoneNumber;
  final String displayName;
  final String bio;
  final String? profileImage;
  final String? location;
  final Timestamp? dateOfBirth;
  final int postsCount;
  final int supportersCount;
  final int circlesCount;
  final bool isAadhaarVerified;
  final bool verificationBadge;
  final bool isPrivate;
  final String? tier;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.phoneNumber,
    required this.displayName,
    this.bio = '',
    this.profileImage,
    this.location,
    this.dateOfBirth,
    this.postsCount = 0,
    this.supportersCount = 0,
    this.circlesCount = 0,
    this.isAadhaarVerified = false,
    this.verificationBadge = false,
    this.isPrivate = false,
    this.tier,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'],
      displayName: data['displayName'] ?? '',
      bio: data['bio'] ?? '',
      profileImage: data['profileImage'],
      location: data['location'],
      dateOfBirth: data['dateOfBirth'],
      postsCount: data['postsCount'] ?? 0,
      supportersCount: data['supportersCount'] ?? 0,
      circlesCount: data['circlesCount'] ?? 0,
      isAadhaarVerified: data['isAadhaarVerified'] ?? false,
      verificationBadge: data['verificationBadge'] ?? false,
      isPrivate: data['isPrivate'] ?? false,
      tier: data['tier'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'bio': bio,
      'profileImage': profileImage,
      'location': location,
      'dateOfBirth': dateOfBirth,
      'postsCount': postsCount,
      'supportersCount': supportersCount,
      'circlesCount': circlesCount,
      'isAadhaarVerified': isAadhaarVerified,
      'verificationBadge': verificationBadge,
      'isPrivate': isPrivate,
      'tier': tier,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  AppUser copyWith({
    String? email,
    String? phoneNumber,
    String? displayName,
    String? bio,
    String? profileImage,
    String? location,
    Timestamp? dateOfBirth,
    int? postsCount,
    int? supportersCount,
    int? circlesCount,
    bool? isAadhaarVerified,
    bool? verificationBadge,
    bool? isPrivate,
    Timestamp? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      postsCount: postsCount ?? this.postsCount,
      supportersCount: supportersCount ?? this.supportersCount,
      circlesCount: circlesCount ?? this.circlesCount,
      isAadhaarVerified: isAadhaarVerified ?? this.isAadhaarVerified,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      isPrivate: isPrivate ?? this.isPrivate,
      tier: tier ?? this.tier,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Utility methods
  DateTime? get dateOfBirthDateTime => dateOfBirth?.toDate();
  
  int? get age {
    if (dateOfBirthDateTime == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirthDateTime!.year;
    if (now.month < dateOfBirthDateTime!.month || 
        (now.month == dateOfBirthDateTime!.month && now.day < dateOfBirthDateTime!.day)) {
      age--;
    }
    return age;
  }

  String get formattedLocation => location?.isNotEmpty == true ? location! : 'No location';
  
  String get formattedBio => bio.isNotEmpty ? bio : 'No bio';
  
  String get formattedDateOfBirth {
    if (dateOfBirthDateTime == null) return 'Not set';
    return '${dateOfBirthDateTime!.day}/${dateOfBirthDateTime!.month}/${dateOfBirthDateTime!.year}';
  }

  bool get hasProfileImage => profileImage != null && profileImage!.isNotEmpty;
  
  bool get isAdult => age != null && age! >= 13;
  
  String get displayNameShort => displayName.length > 20 ? '${displayName.substring(0, 20)}...' : displayName;
  
  String get followersText => supportersCount == 1 ? '1 follower' : '$supportersCount followers';
  
  String get postsText => postsCount == 1 ? '1 post' : '$postsCount posts';
}