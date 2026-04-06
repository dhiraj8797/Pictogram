import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  Future<void> initialize() async {
    try {
      // Enable Crashlytics in debug mode for testing
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      // Set user identifier (will be updated when user logs in)
      await FirebaseCrashlytics.instance.setUserIdentifier('anonymous');
      
      // Set custom keys for app version
      await FirebaseCrashlytics.instance.setCustomKey('app_version', '1.0.0');
      await FirebaseCrashlytics.instance.setCustomKey('build_mode', kDebugMode ? 'debug' : 'release');
      
      print('Crashlytics initialized successfully');
    } catch (e) {
      print('Failed to initialize Crashlytics: $e');
    }
  }

  Future<void> setUserIdentifier(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      print('Failed to set user identifier: $e');
    }
  }

  Future<void> clearUserIdentifier() async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('anonymous');
    } catch (e) {
      print('Failed to clear user identifier: $e');
    }
  }

  Future<void> recordError(
    dynamic error, {
    StackTrace? stackTrace,
    bool fatal = false,
    Map<String, dynamic>? customKeys,
  }) async {
    try {
      // Add custom keys if provided
      if (customKeys != null) {
        for (final entry in customKeys.entries) {
          await FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Record the error
      if (fatal) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
          information: [
            DiagnosticsProperty('user_action', 'critical_error'),
          ],
        );
      } else {
        await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
    } catch (e) {
      print('Failed to record error: $e');
    }
  }

  Future<void> recordMessage(String message, {String? level = 'info'}) async {
    try {
      await FirebaseCrashlytics.instance.log('$level: $message');
    } catch (e) {
      print('Failed to record message: $e');
    }
  }

  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
    } catch (e) {
      print('Failed to set custom key: $e');
    }
  }

  // Convenience methods for common errors
  Future<void> recordAuthError(String operation, dynamic error, StackTrace? stackTrace) async {
    await recordError(
      error,
      stackTrace: stackTrace,
      customKeys: {
        'error_type': 'auth_error',
        'operation': operation,
      },
    );
  }

  Future<void> recordNetworkError(String url, dynamic error, StackTrace? stackTrace) async {
    await recordError(
      error,
      stackTrace: stackTrace,
      customKeys: {
        'error_type': 'network_error',
        'url': url,
      },
    );
  }

  Future<void> recordDatabaseError(String operation, dynamic error, StackTrace? stackTrace) async {
    await recordError(
      error,
      stackTrace: stackTrace,
      customKeys: {
        'error_type': 'database_error',
        'operation': operation,
      },
    );
  }

  Future<void> recordValidationError(String field, dynamic value, String reason) async {
    await recordError(
      Exception('Validation failed: $field = $value - $reason'),
      customKeys: {
        'error_type': 'validation_error',
        'field': field,
        'value': value.toString(),
        'reason': reason,
      },
    );
  }

  Future<void> recordPerformanceIssue(String operation, Duration duration, {Map<String, dynamic>? metadata}) async {
    await recordMessage(
      'Performance issue: $operation took ${duration.inMilliseconds}ms',
      level: 'warning',
    );
    
    if (metadata != null) {
      for (final entry in metadata.entries) {
        await setCustomKey('perf_${entry.key}', entry.value);
      }
    }
  }

  Future<void> recordUserAction(String action, {Map<String, dynamic>? metadata}) async {
    await recordMessage('User action: $action', level: 'info');
    
    if (metadata != null) {
      for (final entry in metadata.entries) {
        await setCustomKey('action_${entry.key}', entry.value);
      }
    }
  }

  Future<void> testCrash() async {
    // Only allow test crashes in debug mode
    if (kDebugMode) {
      // Note: This will crash the app for testing
      // FirebaseCrashlytics.instance.crash();
      // For now, just log a test error
      await recordError(
        Exception('Test crash for debugging'),
        stackTrace: StackTrace.current,
        fatal: true,
        customKeys: {'test': 'crash_test'},
      );
    }
  }
}
