import 'package:cloud_functions/cloud_functions.dart';

class BackendRateLimitService {
  static final BackendRateLimitService _instance = BackendRateLimitService._internal();
  factory BackendRateLimitService() => _instance;
  BackendRateLimitService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Check if user can post (backend enforced)
  Future<bool> canUserPost(String userId) async {
    try {
      final result = await _functions.httpsCallable('canUserPost').call({
        'userId': userId,
      });
      return result.data['canPost'] ?? false;
    } catch (e) {
      // Fail open for now, but log error
      print('Rate limit check failed: $e');
      return true;
    }
  }

  // Check if user can comment (backend enforced)
  Future<bool> canUserComment(String userId) async {
    try {
      final result = await _functions.httpsCallable('canUserComment').call({
        'userId': userId,
      });
      return result.data['canComment'] ?? false;
    } catch (e) {
      print('Rate limit check failed: $e');
      return true;
    }
  }

  // Check if user can follow (backend enforced)
  Future<bool> canUserFollow(String userId) async {
    try {
      final result = await _functions.httpsCallable('canUserFollow').call({
        'userId': userId,
      });
      return result.data['canFollow'] ?? false;
    } catch (e) {
      print('Rate limit check failed: $e');
      return true;
    }
  }

  // Check if user can like (backend enforced)
  Future<bool> canUserLike(String userId) async {
    try {
      final result = await _functions.httpsCallable('canUserLike').call({
        'userId': userId,
      });
      return result.data['canLike'] ?? false;
    } catch (e) {
      print('Rate limit check failed: $e');
      return true;
    }
  }

  // Check if content contains spam (backend enforced)
  Future<bool> isContentSpam(String content, String userId) async {
    try {
      final result = await _functions.httpsCallable('checkSpam').call({
        'content': content,
        'userId': userId,
      });
      return result.data['isSpam'] ?? false;
    } catch (e) {
      print('Spam check failed: $e');
      return false;
    }
  }

  // Create notification (backend only)
  Future<void> createNotification({
    required String userId,
    required String type,
    required String actorId,
    required String actorUsername,
    required String actorProfileImage,
    required String message,
    String? postId,
    String? commentId,
  }) async {
    try {
      await _functions.httpsCallable('createNotification').call({
        'userId': userId,
        'type': type,
        'actorId': actorId,
        'actorUsername': actorUsername,
        'actorProfileImage': actorProfileImage,
        'message': message,
        'postId': postId,
        'commentId': commentId,
      });
    } catch (e) {
      print('Failed to create notification: $e');
      throw Exception('Failed to create notification: $e');
    }
  }

  // Log abuse attempt (backend tracked)
  Future<void> logAbuse({
    required String userId,
    required String action,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _functions.httpsCallable('logAbuse').call({
        'userId': userId,
        'action': action,
        'reason': reason,
        'metadata': metadata ?? {},
      });
    } catch (e) {
      print('Failed to log abuse: $e');
    }
  }

  // Check if user is blocked (backend enforced)
  Future<bool> isUserBlocked(String userId) async {
    try {
      final result = await _functions.httpsCallable('isUserBlocked').call({
        'userId': userId,
      });
      return result.data['isBlocked'] ?? false;
    } catch (e) {
      print('Block check failed: $e');
      return false;
    }
  }

  // Get user's current usage stats
  Future<Map<String, int>> getUserUsageStats(String userId) async {
    try {
      final result = await _functions.httpsCallable('getUserUsageStats').call({
        'userId': userId,
      });
      return Map<String, int>.from(result.data['stats'] ?? {});
    } catch (e) {
      print('Failed to get usage stats: $e');
      return {};
    }
  }
}
