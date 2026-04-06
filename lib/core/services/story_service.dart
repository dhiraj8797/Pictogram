import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story.dart';
import '../models/user.dart';
import 'firebase_service.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseStorage _storage = FirebaseService.storage;

  // Upload story image to Firebase Storage
  Future<String> uploadStoryImage(File imageFile, String userId) async {
    try {
      // Create a reference to the file location
      final storageRef = _storage.ref().child('storyImages/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload story image: $e');
    }
  }

  // Create a new story
  Future<Story> createStory({
    required String userId,
    required String displayName,
    required String userProfileImage,
    File? imageFile,
    String? text,
    String? location,
  }) async {
    try {
      print('✅ STORY CREATE START: userId=$userId');
      
      String? imageUrl;

      if (imageFile != null) {
        print('📤 Uploading image...');
        imageUrl = await uploadStoryImage(imageFile, userId);
        print('✅ Image uploaded: $imageUrl');
      }

      final storyRef = _firestore.collection('stories').doc();

      await storyRef.set({
        'ownerId': userId,
        'ownerName': displayName,
        'ownerProfileImage': userProfileImage,
        'imageUrl': imageUrl ?? '',
        'caption': text ?? '',
        'location': location,
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 24)),
        ),
        'seenBy': [],
      });

      print('✅ STORY CREATED: ${storyRef.id}');
      
      // Return the created story
      final storyData = await storyRef.get();
      return Story.fromFirestore(storyData);
    } catch (e) {
      print('❌ STORY CREATE ERROR: $e');
      throw Exception('Failed to create story: $e');
    }
  }

  // Get active stories (not expired) for users
  Future<List<Story>> getActiveStoriesForUsers(List<String> userIds) async {
    try {
      final now = Timestamp.now();
      
      final querySnapshot = await _firestore
          .collection('stories')
          .where('ownerId', whereIn: userIds)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active stories: $e');
    }
  }

  // DEBUG TEST METHOD - Check all stories without expiry filter
  Future<List<Story>> getAllUserStoriesDebug(String userId) async {
    try {
      print('🧪 DEBUG: Getting ALL stories for userId: $userId');
      
      final snapshot = await _firestore
          .collection('stories')
          .where('ownerId', isEqualTo: userId)
          .get();

      print('🧪 ALL STORIES: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        print('🧪 📄 ${doc.data()}');
      }

      return snapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('🧪 ❌ DEBUG FETCH ERROR: $e');
      throw Exception('Failed to get all user stories: $e');
    }
  }

  // Real-time stream of current user's active stories
  Stream<List<Story>> getUserStoriesStream(String userId) {
    final now = Timestamp.now();
    return _firestore
        .collection('stories')
        .where('ownerId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Story.fromFirestore(doc)).toList());
  }

  // Get stories for a specific user
  Future<List<Story>> getUserStories(String userId) async {
    try {
      print('✅ FETCHING STORIES FOR: $userId');
      final now = Timestamp.now();

      final snapshot = await _firestore
          .collection('stories')
          .where('ownerId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      print('✅ STORIES FOUND: ${snapshot.docs.length}');

      return snapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ FETCH ERROR: $e');
      throw Exception('Failed to get user stories: $e');
    }
  }

  // Mark story as seen by user
  Future<void> markStoryAsSeen(String storyId, String userId) async {
    try {
      await _firestore.collection('stories').doc(storyId).update({
        'seenBy': FieldValue.arrayUnion([userId]),
        'viewersCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to mark story as seen: $e');
    }
  }

  // Check if user has seen story
  Future<bool> hasUserSeenStory(String storyId, String userId) async {
    try {
      final storyDoc = await _firestore.collection('stories').doc(storyId).get();
      if (!storyDoc.exists) return false;

      final story = Story.fromFirestore(storyDoc);
      return story.seenBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // Get stories that user hasn't seen yet
  Future<List<Story>> getUnseenStories(String userId) async {
    try {
      final now = Timestamp.now();
      
      // Get all active stories from users that current user follows
      // This is a simplified approach - in production, you'd want to optimize this
      final querySnapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isGreaterThan: now)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit for performance
          .get();

      final allStories = querySnapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .toList();

      // Filter out stories user has seen and their own stories
      final unseenStories = allStories.where((story) {
        return !story.seenBy.contains(userId) && story.ownerId != userId;
      }).toList();

      return unseenStories;
    } catch (e) {
      throw Exception('Failed to get unseen stories: $e');
    }
  }

  // Delete a story
  Future<void> deleteStory(String storyId, String userId) async {
    try {
      final storyDoc = await _firestore.collection('stories').doc(storyId).get();
      
      if (!storyDoc.exists) {
        throw Exception('Story not found');
      }

      final story = Story.fromFirestore(storyDoc);
      
      // Check if user is the owner
      if (story.ownerId != userId) {
        throw Exception('You can only delete your own stories');
      }

      // Delete image from storage
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(story.imageUrl);
        await storageRef.delete();
      } catch (e) {
        // Continue even if image deletion fails
        print('Warning: Failed to delete story image: $e');
      }

      // Delete story document
      await _firestore.collection('stories').doc(storyId).delete();
    } catch (e) {
      throw Exception('Failed to delete story: $e');
    }
  }

  // Clean up expired stories (should be run periodically)
  Future<void> cleanupExpiredStories() async {
    try {
      final now = Timestamp.now();
      
      final querySnapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: now)
          .get();

      // Delete expired stories in batches
      final batch = _firestore.batch();
      
      for (final doc in querySnapshot.docs) {
        final story = Story.fromFirestore(doc);
        
        // Delete image from storage
        try {
          final storageRef = FirebaseStorage.instance.refFromURL(story.imageUrl);
          await storageRef.delete();
        } catch (e) {
          print('Warning: Failed to delete expired story image: $e');
        }
        
        // Delete story document
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to cleanup expired stories: $e');
    }
  }

  // Get story statistics for a user
  Future<Map<String, int>> getUserStoryStats(String userId) async {
    try {
      final now = Timestamp.now();
      
      // Get active stories
      final activeQuery = await _firestore
          .collection('stories')
          .where('ownerId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: now)
          .get();

      final activeStories = activeQuery.docs.map((doc) => Story.fromFirestore(doc)).toList();
      
      // Calculate total views
      int totalViews = 0;
      for (final story in activeStories) {
        totalViews += story.seenBy.length;
      }

      return {
        'activeStories': activeStories.length,
        'totalViews': totalViews,
      };
    } catch (e) {
      throw Exception('Failed to get user story stats: $e');
    }
  }

  // Pick story image from gallery or camera
  Future<File?> pickStoryImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick story image: $e');
    }
  }

  // Get stories from users that current user follows
  Future<List<Story>> getFollowingUserStories(String currentUserId) async {
    try {
      // Get users that current user follows
      final followsQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .get();

      final followingIds = followsQuery.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) {
        return [];
      }

      // Get active stories from followed users
      return await getActiveStoriesForUsers(followingIds);
    } catch (e) {
      throw Exception('Failed to get following user stories: $e');
    }
  }
}
