import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class AbuseProtectionService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Check if user is rate limited for posts
  Future<bool> isUserRateLimitedForPosts(String userId) async {
    try {
      final now = Timestamp.now();
      final oneHourAgo = Timestamp.fromDate(now.toDate().subtract(const Duration(hours: 1)));

      final recentPosts = await _firestore
          .collection('posts')
          .where('ownerId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: oneHourAgo)
          .limit(6) // Max 6 posts per hour
          .get();

      return recentPosts.docs.length >= 6;
    } catch (e) {
      return false; // Fail open - don't block if service fails
    }
  }

  // Check if user is rate limited for comments
  Future<bool> isUserRateLimitedForComments(String userId) async {
    try {
      final now = Timestamp.now();
      final fiveMinutesAgo = Timestamp.fromDate(now.toDate().subtract(const Duration(minutes: 5)));

      final recentComments = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: fiveMinutesAgo)
          .limit(10) // Max 10 comments per 5 minutes
          .get();

      return recentComments.docs.length >= 10;
    } catch (e) {
      return false;
    }
  }

  // Check if user is rate limited for follows
  Future<bool> isUserRateLimitedForFollows(String userId) async {
    try {
      final now = Timestamp.now();
      final oneHourAgo = Timestamp.fromDate(now.toDate().subtract(const Duration(hours: 1)));

      final recentFollows = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: oneHourAgo)
          .limit(50) // Max 50 follows per hour
          .get();

      return recentFollows.docs.length >= 50;
    } catch (e) {
      return false;
    }
  }

  // Check if user is rate limited for likes
  Future<bool> isUserRateLimitedForLikes(String userId) async {
    try {
      final now = Timestamp.now();
      final oneMinuteAgo = Timestamp.fromDate(now.toDate().subtract(const Duration(minutes: 1)));

      final recentLikes = await _firestore
          .collectionGroup('likes')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: oneMinuteAgo)
          .limit(30) // Max 30 likes per minute
          .get();

      return recentLikes.docs.length >= 30;
    } catch (e) {
      return false;
    }
  }

  // Check for spam patterns in text
  bool containsSpam(String text) {
    // Check for repeated characters (e.g., "aaaaaa")
    if (RegExp(r'(.)\1{4,}').hasMatch(text)) {
      return true;
    }

    // Check for excessive capitalization
    final uppercaseCount = text.replaceAll(RegExp(r'[^A-Z]'), '').length;
    if (uppercaseCount > text.length * 0.7 && text.length > 10) {
      return true;
    }

    // Check for common spam words
    final spamWords = [
      'free', 'winner', 'congratulations', 'claim', 'prize', 
      'click here', 'buy now', 'limited offer', 'act now',
      'viagra', 'casino', 'lottery', 'money back'
    ];
    
    final lowerText = text.toLowerCase();
    for (final word in spamWords) {
      if (lowerText.contains(word)) {
        return true;
      }
    }

    return false;
  }

  // Check for suspicious activity patterns
  Future<bool> hasSuspiciousActivity(String userId) async {
    try {
      final now = Timestamp.now();
      final oneHourAgo = Timestamp.fromDate(now.toDate().subtract(const Duration(hours: 1)));

      // Check for rapid actions across multiple collections
      final batch = [
        _firestore.collection('posts').where('ownerId', isEqualTo: userId).where('createdAt', isGreaterThan: oneHourAgo),
        _firestore.collection('comments').where('userId', isEqualTo: userId).where('createdAt', isGreaterThan: oneHourAgo),
        _firestore.collection('follows').where('followerId', isEqualTo: userId).where('createdAt', isGreaterThan: oneHourAgo),
      ];

      int totalActions = 0;
      for (final query in batch) {
        final snapshot = await query.limit(100).get();
        totalActions += snapshot.docs.length;
      }

      // Flag if more than 100 actions in 1 hour
      return totalActions > 100;
    } catch (e) {
      return false;
    }
  }

  // Log abuse attempt
  Future<void> logAbuseAttempt({
    required String userId,
    required String action,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _firestore.collection('abuse_logs').add({
        'userId': userId,
        'action': action,
        'reason': reason,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.now(),
        'userAgent': 'flutter_app', // Could be enhanced
      });
    } catch (e) {
      print('Failed to log abuse attempt: $e');
    }
  }

  // Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['isBlocked'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Block user (admin function)
  Future<void> blockUser(String userId, String reason) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isBlocked': true,
        'blockedAt': Timestamp.now(),
        'blockedReason': reason,
      });

      // Log the block action
      await logAbuseAttempt(
        userId: userId,
        action: 'user_blocked',
        reason: reason,
      );
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  // Get user's abuse score
  Future<int> getUserAbuseScore(String userId) async {
    try {
      final now = Timestamp.now();
      final sevenDaysAgo = Timestamp.fromDate(now.toDate().subtract(const Duration(days: 7)));

      final abuseLogs = await _firestore
          .collection('abuse_logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: sevenDaysAgo)
          .get();

      // Calculate score based on number and severity of violations
      int score = 0;
      for (final log in abuseLogs.docs) {
        final data = log.data() as Map<String, dynamic>;
        final reason = data['reason'] as String;
        
        // Weight different violations
        if (reason.contains('rate_limit')) score += 1;
        if (reason.contains('spam')) score += 3;
        if (reason.contains('suspicious')) score += 5;
        if (reason.contains('blocked')) score += 10;
      }

      return score;
    } catch (e) {
      return 0;
    }
  }

  // Validate content safety
  Future<bool> isContentSafe(String content) async {
    // Basic content validation
    if (containsSpam(content)) {
      return false;
    }

    // Length validation
    if (content.length > 1000) {
      return false;
    }

    // Check for suspicious patterns
    final suspiciousPattern = RegExp(r'[^\w\s#@.,!?\'"-]');
    if (suspiciousPattern.hasMatch(content)) {
      return false; // Contains unusual characters
    }

    return true;
  }

  // Rate limit check wrapper
  Future<bool> canPerformAction(String userId, String action) async {
    // Check if user is blocked
    if (await isUserBlocked(userId)) {
      return false;
    }

    // Check rate limits based on action type
    switch (action) {
      case 'post':
        return !(await isUserRateLimitedForPosts(userId));
      case 'comment':
        return !(await isUserRateLimitedForComments(userId));
      case 'follow':
        return !(await isUserRateLimitedForFollows(userId));
      case 'like':
        return !(await isUserRateLimitedForLikes(userId));
      default:
        return true;
    }
  }
}
