import 'package:flutter/foundation.dart';

enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  static Environment get currentEnvironment {
    if (kReleaseMode) {
      return Environment.production;
    } else if (kProfileMode) {
      return Environment.staging;
    } else {
      return Environment.development;
    }
  }

  static String get environmentName {
    switch (currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  // Firebase project IDs for different environments
  static String get firebaseProjectId {
    switch (currentEnvironment) {
      case Environment.development:
        return 'pictogram-dev'; // Replace with actual dev project ID
      case Environment.staging:
        return 'pictogram-staging'; // Replace with actual staging project ID
      case Environment.production:
        return 'pictogram-prod'; // Replace with actual production project ID
    }
  }

  // API endpoints for different environments
  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.development:
        return 'https://dev-api.pictogram.app';
      case Environment.staging:
        return 'https://staging-api.pictogram.app';
      case Environment.production:
        return 'https://api.pictogram.app';
    }
  }

  // Feature flags
  static bool get enableDebugFeatures {
    return currentEnvironment == Environment.development;
  }

  static bool get enableAnalytics {
    return currentEnvironment != Environment.development;
  }

  static bool get enableCrashReporting {
    return currentEnvironment == Environment.production;
  }

  static bool get enableAppCheck {
    return currentEnvironment == Environment.production;
  }

  // Rate limiting configurations
  static Map<String, int> get rateLimits {
    switch (currentEnvironment) {
      case Environment.development:
        return {
          'posts_per_hour': 20,
          'comments_per_5min': 50,
          'follows_per_hour': 100,
          'likes_per_minute': 60,
        };
      case Environment.staging:
        return {
          'posts_per_hour': 12,
          'comments_per_5min': 20,
          'follows_per_hour': 60,
          'likes_per_minute': 40,
        };
      case Environment.production:
        return {
          'posts_per_hour': 6,
          'comments_per_5min': 10,
          'follows_per_hour': 50,
          'likes_per_minute': 30,
        };
    }
  }

  // Cost control limits
  static Map<String, int> get costLimits {
    switch (currentEnvironment) {
      case Environment.development:
        return {
          'daily_reads_per_user': 1000,
          'daily_writes_per_user': 500,
          'daily_storage_mb_per_user': 100,
        };
      case Environment.staging:
        return {
          'daily_reads_per_user': 500,
          'daily_writes_per_user': 200,
          'daily_storage_mb_per_user': 50,
        };
      case Environment.production:
        return {
          'daily_reads_per_user': 200,
          'daily_writes_per_user': 50,
          'daily_storage_mb_per_user': 20,
        };
    }
  }

  // Logging configuration
  static bool get enableVerboseLogging {
    return false; // Disabled to remove debug messages
  }

  static bool get enablePerformanceMonitoring {
    return currentEnvironment != Environment.development;
  }

  // Cache settings
  static Duration get cacheExpiration {
    switch (currentEnvironment) {
      case Environment.development:
        return const Duration(minutes: 5);
      case Environment.staging:
        return const Duration(hours: 1);
      case Environment.production:
        return const Duration(hours: 4);
    }
  }

  // Image compression settings
  static Map<String, int> get imageCompression {
    switch (currentEnvironment) {
      case Environment.development:
        return {
          'quality': 90,
          'max_width': 2048,
          'max_height': 2048,
        };
      case Environment.staging:
        return {
          'quality': 85,
          'max_width': 1920,
          'max_height': 1920,
        };
      case Environment.production:
        return {
          'quality': 80,
          'max_width': 1080,
          'max_height': 1920,
        };
    }
  }

  // App Check configuration
  static String get appCheckDebugToken {
    switch (currentEnvironment) {
      case Environment.development:
        return 'debug-token-dev'; // Replace with actual debug token
      case Environment.staging:
        return 'debug-token-staging'; // Replace with actual debug token
      case Environment.production:
        return ''; // No debug token in production
    }
  }

  // Recaptcha site key for web
  static String get recaptchaSiteKey {
    switch (currentEnvironment) {
      case Environment.development:
        return '6LeIxAcTAAAAAJcZVRqyHh71UMIEbUjQpYk8M7U_'; // Google test key
      case Environment.staging:
        return 'staging-recaptcha-key'; // Replace with actual staging key
      case Environment.production:
        return 'production-recaptcha-key'; // Replace with actual production key
    }
  }

  // Print current configuration (for debugging)
  static void printCurrentConfig() {
    if (kDebugMode) {
      print('🔧 Environment Configuration');
      print('Environment: $environmentName');
      print('Firebase Project ID: $firebaseProjectId');
      print('API Base URL: $apiBaseUrl');
      print('Analytics Enabled: $enableAnalytics');
      print('Crash Reporting Enabled: $enableCrashReporting');
      print('App Check Enabled: $enableAppCheck');
      print('Rate Limits: $rateLimits');
      print('Cost Limits: $costLimits');
      print('Verbose Logging: $enableVerboseLogging');
      print('Performance Monitoring: $enablePerformanceMonitoring');
      print('Cache Expiration: $cacheExpiration');
      print('Image Compression: $imageCompression');
    }
  }
}
