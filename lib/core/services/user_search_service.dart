import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firebase_service.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Search users by display name
  Future<List<AppUser>> searchUsers(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      // Convert to lowercase for case-insensitive search
      final searchQuery = query.toLowerCase().trim();
      
      print('DEBUG: Searching users with query: "$searchQuery"');
      
      // Search for users whose display name contains the query
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: searchQuery)
          .where('displayName', isLessThanOrEqualTo: searchQuery + '\uf8ff')
          .limit(limit)
          .get();

      final users = querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((user) => user.displayName.toLowerCase().contains(searchQuery))
          .toList();

      print('DEBUG: Found ${users.length} users matching query: "$searchQuery"');
      for (var user in users) {
        print('  - User: ${user.displayName} (${user.uid})');
      }

      return users;
    } catch (e) {
      print('DEBUG: Error searching users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  // Search users by display name with partial matching
  Future<List<AppUser>> searchUsersPartial(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final searchQuery = query.toLowerCase().trim();
      
      print('DEBUG: Partial search users with query: "$searchQuery"');
      
      // Get all users and filter client-side for better partial matching
      final querySnapshot = await _firestore
          .collection('users')
          .limit(limit * 3) // Get more results for better filtering
          .get();

      final users = querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((user) => 
              user.displayName.toLowerCase().contains(searchQuery) ||
              user.email.toLowerCase().contains(searchQuery))
          .take(limit)
          .toList();

      print('DEBUG: Found ${users.length} users with partial matching for: "$searchQuery"');
      for (var user in users) {
        print('  - User: ${user.displayName} (${user.uid})');
      }

      return users;
    } catch (e) {
      print('DEBUG: Error in partial search: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  // Get user suggestions based on query
  Future<List<AppUser>> getUserSuggestions(String query, {int limit = 5}) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      return await searchUsersPartial(query, limit: limit);
    } catch (e) {
      print('DEBUG: Error getting user suggestions: $e');
      return [];
    }
  }

  // Get popular users (for trending/explore section)
  Future<List<AppUser>> getPopularUsers({int limit = 10}) async {
    try {
      print('DEBUG: Getting popular users');
      
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('supportersCount', descending: true)
          .orderBy('postsCount', descending: true)
          .limit(limit)
          .get();

      final users = querySnapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();

      print('DEBUG: Found ${users.length} popular users');
      for (var user in users) {
        print('  - User: ${user.displayName} (${user.supportersCount} supporters, ${user.postsCount} posts)');
      }

      return users;
    } catch (e) {
      print('DEBUG: Error getting popular users: $e');
      return [];
    }
  }
}
