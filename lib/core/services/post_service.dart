import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../models/notification.dart';
import './firebase_service.dart';
import './notification_service.dart';
import './backend_rate_limit_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseStorage _storage = FirebaseService.storage;
  final NotificationService _notificationService = NotificationService();
  final BackendRateLimitService _backendRateLimitService = BackendRateLimitService();

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Create a reference to the file location
      final storageRef = _storage.ref().child('posts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Upload the file
      final uploadTask = await storageRef.putFile(imageFile);
      
      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create a new post with backend enforcement
  Future<Post> createPost({
    required String userId,
    required String displayName,
    required String userProfileImage,
    required File imageFile,
    required String caption,
    String? location,
    List<String>? tags,
  }) async {
    try {
      // Check if user can post (backend enforced)
      final canPost = await _backendRateLimitService.canUserPost(userId);
      if (!canPost) {
        throw Exception('You have reached your posting limit. Please try again later.');
      }

      // Upload image and get aspect ratio
      final imageUrl = await uploadImage(imageFile, userId);
      final aspectRatio = await _getImageAspectRatio(imageFile);

      // Create post document with transaction
      final userRef = _firestore.collection('users').doc(userId);
      final postRef = _firestore.collection('posts').doc();
      
      await _firestore.runTransaction((transaction) async {
        // Get user document
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        // Create post document
        final postData = {
          'ownerId': userId,
          'ownerName': displayName,
          'ownerProfileImage': userProfileImage,
          'imageUrl': imageUrl,
          'caption': caption,
          'location': location,
          'tags': tags ?? [],
          'likesCount': 0,
          'commentsCount': 0,
          'sharesCount': 0,
          'imageAspectRatio': aspectRatio,
          'createdAt': Timestamp.now(),
        };
        
        print('DEBUG: Creating post with data:');
        print('  - Owner Name: $displayName');
        print('  - Location: $location');
        print('  - Caption: $caption');

        transaction.set(postRef, postData);
        
        print('DEBUG: Post document set with ID: ${postRef.id}');
        print('DEBUG: Post data saved to Firestore successfully');

        // Increment user's posts count
        transaction.update(userRef, {
          'postsCount': FieldValue.increment(1),
        });
        
        print('DEBUG: User posts count incremented');

        return postRef;
      });

      // Return the created post
      final createdPost = await postRef.get();
      return Post.fromFirestore(createdPost);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get posts feed (newest first)
  Future<List<Post>> getFeedPosts({int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      print('DEBUG: getFeedPosts called - limit: $limit, hasLastDocument: ${lastDocument != null}');
      
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      print('DEBUG: getFeedPosts returned ${querySnapshot.docs.length} posts');
      
      final posts = querySnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();
      
      for (var post in posts) {
        print('DEBUG: FEED POST - ID: ${post.postId}, Owner: ${post.ownerId}, Created: ${post.createdAt}');
      }
      
      return posts;
    } catch (e) {
      print('DEBUG: Error in getFeedPosts: $e');
      throw Exception('Failed to get feed posts: $e');
    }
  }

  // Get user's posts
  Future<List<Post>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      print('DEBUG: Querying posts for userId: $userId using Firestore index');
      
      // Use indexed query for optimal performance
      final querySnapshot = await _firestore
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      print('DEBUG: Indexed query returned ${querySnapshot.docs.length} documents');
      
      final posts = querySnapshot.docs
          .map((doc) => Post.fromFirestore(doc))
          .toList();
      
      print('DEBUG: Mapped to ${posts.length} Post objects');
      for (var post in posts) {
        print('  - Post ID: ${post.postId}, Owner: ${post.ownerId}, Image: ${post.imageUrl}, Created: ${post.createdAt}');
      }
      
      return posts;
    } catch (e) {
      print('DEBUG: Error in getUserPosts: $e');
      throw Exception('Failed to get user posts: $e');
    }
  }

  // Get post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      print('DEBUG: Getting post by ID: $postId');
      
      final docSnapshot = await _firestore.collection('posts').doc(postId).get();
      
      if (docSnapshot.exists) {
        final post = Post.fromFirestore(docSnapshot);
        print('DEBUG: Found post - ID: ${post.postId}, Owner: ${post.ownerId}');
        return post;
      } else {
        print('DEBUG: Post not found: $postId');
        return null;
      }
    } catch (e) {
      print('DEBUG: Error getting post by ID: $e');
      throw Exception('Failed to get post: $e');
    }
  }

  // Count user's posts
  Future<int> getUserPostsCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .count()
          .get();
      
      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get user posts count: $e');
    }
  }

  // Update a post
  Future<void> updatePost({
    required String postId,
    String? caption,
    String? location,
    List<String>? tags,
  }) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      
      final updateData = <String, dynamic>{};
      if (caption != null) updateData['caption'] = caption;
      if (location != null) updateData['location'] = location;
      if (tags != null) updateData['tags'] = tags;
      
      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = Timestamp.now();
        await postRef.update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      
      // Get post data to delete image from storage
      final postDoc = await postRef.get();
      if (postDoc.exists) {
        final postData = postDoc.data() as Map<String, dynamic>?;
        final imageUrl = postData?['imageUrl'] as String?;
        
        // Delete image from storage if it exists
        if (imageUrl != null && imageUrl.contains('firebase')) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Failed to delete image from storage: $e');
          }
        }
        
        // Delete likes
        final likesQuery = await postRef.collection('likes').get();
        for (final doc in likesQuery.docs) {
          await doc.reference.delete();
        }
        
        // Delete comments
        final commentsQuery = await postRef.collection('comments').get();
        for (final doc in commentsQuery.docs) {
          await doc.reference.delete();
        }
        
        // Delete the post document
        await postRef.delete();
        
        // Decrement user's posts count
        final deleteData = postDoc.data() as Map<String, dynamic>?;
        final ownerId = deleteData?['ownerId'] as String?;
        if (ownerId != null) {
          final userRef = _firestore.collection('users').doc(ownerId);
          await userRef.update({
            'postsCount': FieldValue.increment(-1),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Like/unlike a post with transaction-safe counter updates and notifications
  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);

    // Pre-fetch user data before transaction
    String? postOwnerId;
    bool shouldCreateNotification = false;

    try {
      // First, perform the transaction for like/unlike operations
      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        final likeDoc = await transaction.get(likeRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        final currentLikes = postData['likesCount'] as int? ?? 0;
        postOwnerId = postData['ownerId'] as String?;

        if (likeDoc.exists) {
          // Unlike the post
          transaction.delete(likeRef);
          transaction.update(postRef, {'likesCount': currentLikes - 1});
          shouldCreateNotification = false;
        } else {
          // Like the post
          transaction.set(likeRef, {
            'userId': userId,
            'createdAt': Timestamp.now(),
          });
          transaction.update(postRef, {'likesCount': currentLikes + 1});
          
          // Check if we should create notification (not liking own post)
          shouldCreateNotification = postOwnerId != null && postOwnerId != userId;
        }
      });

      // Create notification OUTSIDE the transaction (synchronously to ensure it completes)
      if (shouldCreateNotification && postOwnerId != null) {
        try {
          print('DEBUG: Creating like notification for post owner: $postOwnerId from user: $userId');
          
          // Get user data for notification
          final userDoc = await _firestore.collection('users').doc(userId).get();
          final userData = userDoc.data() as Map<String, dynamic>?;
          
          print('DEBUG: User data retrieved: ${userData?['displayName']}');
          
          await _notificationService.createNotification(
            userId: postOwnerId!,
            type: 'like',
            actorId: userId,
            actorName: userData?['displayName'] ?? 'Unknown',
            actorProfileImage: userData?['profileImage'] ?? '',
            message: '${userData?['displayName'] ?? 'Someone'} liked your post',
            postId: postId,
          );
          
          print('DEBUG: Like notification created successfully');
        } catch (notificationError) {
          print('DEBUG: Error creating notification (non-critical): $notificationError');
          // Don't throw - notification failure shouldn't fail the like
        }
      }
    } catch (e) {
      print('DEBUG: Error in toggleLike transaction: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Check if user likes a post
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Get image aspect ratio
  Future<double> _getImageAspectRatio(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final aspectRatio = image.width / image.height;
      image.dispose();
      return aspectRatio;
    } catch (e) {
      return 1.0; // Default aspect ratio
    }
  }

  // Pick image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }
}
