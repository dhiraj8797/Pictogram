import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/user.dart';
import 'firebase_service.dart';

class ProductionPostService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final FirebaseStorage _storage = FirebaseService.storage;

  // Validate image before upload
  Future<File?> _validateAndCompressImage(File imageFile) async {
    try {
      // Check file size (max 10MB)
      final fileSize = await imageFile.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('Image size must be less than 10MB');
      }

      // Check file extension
      final fileName = imageFile.path.toLowerCase();
      if (!fileName.endsWith('.jpg') && 
          !fileName.endsWith('.jpeg') && 
          !fileName.endsWith('.png')) {
        throw Exception('Only JPG and PNG images are allowed');
      }

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolutePath,
        '${imageFile.parent?.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
        quality: 85,
        minWidth: 800,
        minHeight: 600,
      );

      if (compressedFile == null) {
        throw Exception('Failed to compress image');
      }

      // Check compressed file size
      final compressedSize = await compressedFile.length();
      if (compressedSize > 5 * 1024 * 1024) {
        throw Exception('Compressed image is still too large');
      }

      return compressedFile;
    } catch (e) {
      throw Exception('Image validation failed: $e');
    }
  }

  // Upload image with validation
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Validate and compress image
      final validatedImage = await _validateAndCompressImage(imageFile);
      
      if (validatedImage == null) {
        throw Exception('Image validation failed');
      }

      // Create a reference to the file location
      final storageRef = _storage.ref().child('posts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Upload the file
      final uploadTask = await storageRef.putFile(validatedImage);
      
      // Check for upload errors
      if (uploadTask.state == TaskState.error) {
        throw Exception('Failed to upload image to storage');
      }
      
      // Get download URL
      final downloadUrl = await storageRef.ref.getDownloadURL();
      
      // Validate URL
      if (downloadUrl.isEmpty || !downloadUrl.startsWith('https://')) {
        throw Exception('Invalid download URL received');
      }
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create post with comprehensive validation
  Future<Post> createPost({
    required String userId,
    required String username,
    required String userProfileImage,
    required File imageFile,
    String? caption,
  }) async {
    try {
      // Validate inputs
      if (userId.isEmpty || userId.length > 128) {
        throw Exception('Invalid user ID');
      }
      
      if (username.isEmpty || username.length < 3 || username.length > 30) {
        throw Exception('Invalid username');
      }
      
      if (caption != null && caption.length > 100) {
        throw Exception('Caption too long (max 100 characters)');
      }

      // Validate user exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Upload image
      final imageUrl = await uploadImage(imageFile, userId);
      
      // Create post document with validation
      final postRef = _firestore.collection('posts').doc();
      final post = Post(
        postId: postRef.id,
        ownerId: userId,
        ownerUsername: username,
        ownerProfileImage: userProfileImage,
        imageUrl: imageUrl,
        caption: caption ?? '',
        likesCount: 0,
        commentsCount: 0,
        createdAt: Timestamp.now(),
      );

      // Use transaction for atomic creation
      await _firestore.runTransaction((transaction) async {
        // Create post
        transaction.set(postRef, post.toFirestore());

        // Increment user's posts count
        final userRef = _firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'postsCount': FieldValue.increment(1),
        });
      });

      return post;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get posts with error handling
  Future<List<Post>> getPosts({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      
      // Validate and filter posts
      final validPosts = <Post>[];
      for (final doc in querySnapshot.docs) {
        try {
          final post = Post.fromFirestore(doc);
          
          // Validate post data integrity
          if (post.postId.isNotEmpty && 
              post.ownerId.isNotEmpty && 
              post.imageUrl.isNotEmpty &&
              post.imageUrl.startsWith('https://')) {
            validPosts.add(post);
          }
        } catch (e) {
          // Skip invalid posts but log error
          print('Skipping invalid post ${doc.id}: $e');
        }
      }

      return validPosts;
    } catch (e) {
      throw Exception('Failed to get posts: $e');
    }
  }

  // Get user posts with validation
  Future<List<Post>> getUserPosts(String userId, {int limit = 20}) async {
    try {
      // Validate user ID
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      final querySnapshot = await _firestore
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final validPosts = <Post>[];
      for (final doc in querySnapshot.docs) {
        try {
          final post = Post.fromFirestore(doc);
          
          // Additional validation for user posts
          if (post.ownerId == userId && post.imageUrl.startsWith('https://')) {
            validPosts.add(post);
          }
        } catch (e) {
          print('Skipping invalid user post ${doc.id}: $e');
        }
      }

      return validPosts;
    } catch (e) {
      throw Exception('Failed to get user posts: $e');
    }
  }

  // Toggle like with duplicate prevention
  Future<void> toggleLike(String postId, String userId) async {
    try {
      // Validate inputs
      if (postId.isEmpty || userId.isEmpty) {
        throw Exception('Invalid post or user ID');
      }

      final postRef = _firestore.collection('posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(userId);

      await _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        final likeDoc = await transaction.get(likeRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        // Validate post data
        final postData = postDoc.data() as Map<String, dynamic>;
        if (postData['imageUrl'] == null || !(postData['imageUrl'] as String).startsWith('https://')) {
          throw Exception('Invalid post data');
        }

        if (likeDoc.exists) {
          // Unlike
          transaction.delete(likeRef);
          transaction.update(postRef, {'likesCount': FieldValue.increment(-1)});
        } else {
          // Like
          transaction.set(likeRef, {
            'userId': userId,
            'createdAt': Timestamp.now(),
          });
          transaction.update(postRef, {'likesCount': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Delete post with cleanup
  Future<void> deletePost(String postId, String userId) async {
    try {
      if (postId.isEmpty || userId.isEmpty) {
        throw Exception('Invalid post or user ID');
      }

      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('posts').doc(postId);
        final postDoc = await transaction.get(postRef);

        if (!postDoc.exists) {
          throw Exception('Post not found');
        }

        final postData = postDoc.data() as Map<String, dynamic>;
        final postOwnerId = postData['ownerId'] ?? '';

        if (postOwnerId != userId) {
          throw Exception('You can only delete your own posts');
        }

        // Delete post document
        transaction.delete(postRef);

        // Decrement user's posts count
        final userRef = _firestore.collection('users').doc(userId);
        transaction.update(userRef, {
          'postsCount': FieldValue.increment(-1),
        });
      });

      // Delete image from storage (outside transaction)
      try {
        final postDoc = await _firestore.collection('posts').doc(postId).get();
        if (postDoc.exists) {
          final postData = postDoc.data() as Map<String, dynamic>;
          final imageUrl = postData['imageUrl'] ?? '';
          if (imageUrl.isNotEmpty) {
            final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
            await storageRef.delete();
          }
        }
      } catch (e) {
        print('Warning: Failed to delete post image: $e');
      }
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Check if user liked a post
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      if (postId.isEmpty || userId.isEmpty) {
        return false;
      }

      final likeDoc = await _firestore
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();
      return likeDoc.exists;
    } catch (e) {
      return false; // Fail silently for UI
    }
  }
}
