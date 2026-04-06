import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;

  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    
    // Set default parameters
    await _analytics.setDefaultEventParameters({
      'app_version': '1.0.0',
      'platform': kIsWeb ? 'web' : 'mobile',
      'environment': AppConfig.environmentName,
      'firebase_project': AppConfig.firebaseProjectId,
    });

    // Enable analytics collection based on environment
    await _analytics.setAnalyticsCollectionEnabled(AppConfig.enableAnalytics);
    
    print('📊 Firebase Analytics initialized - Enabled: ${AppConfig.enableAnalytics}');
  }

  FirebaseAnalytics get analytics => _analytics;

  // User tracking
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperties({
    String? displayName,
    String? tier,
    String? accountAge,
  }) async {
    if (displayName != null) {
      await _analytics.setUserProperty(name: 'display_name', value: displayName);
    }
    if (tier != null) {
      await _analytics.setUserProperty(name: 'user_tier', value: tier);
    }
    if (accountAge != null) {
      await _analytics.setUserProperty(name: 'account_age', value: accountAge);
    }
  }

  // Screen tracking
  Future<void> trackScreen(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // Feature usage tracking
  Future<void> trackPostCreated() async {
    await _analytics.logEvent(
      name: 'post_created',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackStoryCreated() async {
    await _analytics.logEvent(
      name: 'story_created',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackCommentAdded() async {
    await _analytics.logEvent(
      name: 'comment_added',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackLikeGiven() async {
    await _analytics.logEvent(
      name: 'like_given',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackFollowAction() async {
    await _analytics.logEvent(
      name: 'follow_action',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Engagement tracking
  Future<void> trackFeedViewed(String feedType) async {
    await _analytics.logEvent(
      name: 'feed_viewed',
      parameters: {
        'feed_type': feedType, // 'following', 'trending', 'recommended', 'hybrid'
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackProfileViewed(String profileId) async {
    await _analytics.logEvent(
      name: 'profile_viewed',
      parameters: {
        'profile_id': profileId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackStoryViewed(String storyId) async {
    await _analytics.logEvent(
      name: 'story_viewed',
      parameters: {
        'story_id': storyId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Performance tracking
  Future<void> trackImageUpload(String imageSize, String uploadTime) async {
    await _analytics.logEvent(
      name: 'image_upload',
      parameters: {
        'image_size': imageSize,
        'upload_time': uploadTime,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackAppOpen() async {
    await _analytics.logAppOpen();
  }

  // Error tracking (complementary to Crashlytics)
  Future<void> trackError(String errorType, String errorMessage) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Business metrics
  Future<void> trackDailyActiveUser() async {
    await _analytics.logEvent(
      name: 'daily_active_user',
      parameters: {
        'date': DateTime.now().toIso8601String().split('T')[0],
      },
    );
  }

  Future<void> trackRetention(String daysSinceInstall) async {
    await _analytics.logEvent(
      name: 'user_retention',
      parameters: {
        'days_since_install': daysSinceInstall,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Feature discovery
  Future<void> trackFeatureDiscovered(String featureName) async {
    await _analytics.logEvent(
      name: 'feature_discovered',
      parameters: {
        'feature_name': featureName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Content interaction
  Future<void> trackContentShared(String contentType) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: 'content_${DateTime.now().millisecondsSinceEpoch}',
      method: 'app_share',
    );
  }

  Future<void> trackSearchPerformed(String searchQuery) async {
    await _analytics.logSearch(
      searchTerm: searchQuery,
    );
  }

  // E-commerce (if you add premium features)
  Future<void> trackPurchaseStarted(String productName) async {
    await _analytics.logBeginCheckout(
      value: 0.0,
      currency: 'USD',
      items: [
        AnalyticsEventItem(
          itemName: productName,
          itemCategory: 'premium_feature',
        ),
      ],
    );
  }

  Future<void> trackPurchaseCompleted(String productName, double value) async {
    await _analytics.logPurchase(
      value: value,
      currency: 'USD',
      items: [
        AnalyticsEventItem(
          itemName: productName,
          itemCategory: 'premium_feature',
          price: value,
          quantity: 1,
        ),
      ],
    );
  }

  // Custom events
  Future<void> trackCustomEvent(String eventName, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters.cast<String, Object>(),
    );
  }

  // Session tracking
  Future<void> trackSessionStart() async {
    await _analytics.logEvent(
      name: 'session_start',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> trackSessionEnd(int sessionDuration) async {
    await _analytics.logEvent(
      name: 'session_end',
      parameters: {
        'session_duration_seconds': sessionDuration,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  // Cleanup
  Future<void> dispose() async {
    // Clear user data on logout
    await _analytics.setUserId(id: null);
  }
}
