import 'package:get_it/get_it.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/follow_service.dart';
import '../services/story_service.dart';
import '../services/notification_service.dart';
import '../services/user_search_service.dart';
import '../services/firebase_service.dart';
import '../services/backend_rate_limit_service.dart';
import '../services/analytics_service.dart';
import '../exceptions/app_exceptions.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Service locator setup
/// Initialize all services and dependencies
Future<void> setupServiceLocator() async {
  try {
    // Register core services as singletons
    sl.registerLazySingleton<FirebaseService>(() => FirebaseService());
    sl.registerLazySingleton<AuthService>(() => AuthService());
    sl.registerLazySingleton<PostService>(() => PostService());
    sl.registerLazySingleton<FollowService>(() => FollowService());
    sl.registerLazySingleton<StoryService>(() => StoryService());
    sl.registerLazySingleton<NotificationService>(() => NotificationService());
    sl.registerLazySingleton<UserSearchService>(() => UserSearchService());
    sl.registerLazySingleton<BackendRateLimitService>(() => BackendRateLimitService());
    sl.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
    
    // Register configuration
    sl.registerLazySingleton<AppConfig>(() => AppConfig());
    
    print('Service locator initialized successfully');
  } catch (e) {
    print('Failed to initialize service locator: $e');
    throw ServiceException('Service locator initialization failed', originalError: e);
  }
}

/// Clean up service locator
Future<void> cleanupServiceLocator() async {
  try {
    await sl.reset();
    print('Service locator cleaned up successfully');
  } catch (e) {
    print('Failed to cleanup service locator: $e');
  }
}

/// Service locator exceptions
class ServiceException extends AppException {
  const ServiceException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);
  
  static const String initializationFailedCode = 'INITIALIZATION_FAILED';
  static const String serviceNotFoundCode = 'SERVICE_NOT_FOUND';
  static const String dependencyCycleCode = 'DEPENDENCY_CYCLE';
}

/// Extension methods for easy service access
extension ServiceLocatorExtensions on GetIt {
  /// Get service or throw exception
  T getService<T extends Object>() {
    try {
      return get<T>();
    } catch (e) {
      throw ServiceException(
        'Service ${T.toString()} not found',
        code: ServiceException.serviceNotFoundCode,
        originalError: e,
      );
    }
  }
  
  /// Get service or return null
  T? getServiceOrNull<T extends Object>() {
    try {
      return get<T>();
    } catch (e) {
      return null;
    }
  }
  
  /// Check if service is registered
  bool isRegistered<T extends Object>() {
    return isRegistered<T>();
  }
}

/// Convenience getters for commonly used services
class Services {
  static AuthService get auth => sl.getService<AuthService>();
  static PostService get posts => sl.getService<PostService>();
  static FollowService get follows => sl.getService<FollowService>();
  static StoryService get stories => sl.getService<StoryService>();
  static NotificationService get notifications => sl.getService<NotificationService>();
  static UserSearchService get search => sl.getService<UserSearchService>();
  static FirebaseService get firebase => sl.getService<FirebaseService>();
  static BackendRateLimitService get rateLimit => sl.getService<BackendRateLimitService>();
  static AnalyticsService get analytics => sl.getService<AnalyticsService>();
  static AppConfig get config => sl.getService<AppConfig>();
}

/// Service factory for creating instances with proper configuration
class ServiceFactory {
  /// Create auth service with configuration
  static AuthService createAuthService({bool enableDebug = false}) {
    return AuthService();
  }
  
  /// Create post service with custom configuration
  static PostService createPostService({
    int maxFileSize = 10 * 1024 * 1024, // 10MB
    List<String> allowedFormats = const ['jpg', 'jpeg', 'png', 'webp'],
  }) {
    return PostService();
  }
  
  /// Create search service with limits
  static UserSearchService createSearchService({
    int maxResults = 20,
    Duration timeout = const Duration(seconds: 10),
  }) {
    return UserSearchService();
  }
}

/// Service health checker
class ServiceHealthChecker {
  static Future<Map<String, bool>> checkAllServices() async {
    final results = <String, bool>{};
    
    try {
      // Check Firebase connection
      await Services.firebase.firestore.collection('health').limit(1).get();
      results['firebase'] = true;
    } catch (e) {
      results['firebase'] = false;
    }
    
    try {
      // Check auth service
      final currentUser = Services.auth.currentUser;
      results['auth'] = true;
    } catch (e) {
      results['auth'] = false;
    }
    
    try {
      // Check post service
      await Services.posts.getFeedPosts(limit: 1);
      results['posts'] = true;
    } catch (e) {
      results['posts'] = false;
    }
    
    return results;
  }
  
  static Future<bool> isHealthy() async {
    final results = await checkAllServices();
    return results.values.every((isHealthy) => isHealthy);
  }
}
