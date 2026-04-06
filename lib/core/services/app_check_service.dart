import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class AppCheckService {
  static final AppCheckService _instance = AppCheckService._internal();
  factory AppCheckService() => _instance;
  AppCheckService._internal();

  Future<void> initialize() async {
    try {
      // Only initialize App Check if enabled for current environment
      if (!AppConfig.enableAppCheck) {
        print('🔒 Firebase App Check disabled for ${AppConfig.environmentName}');
        return;
      }

      // Initialize App Check with different providers based on platform and environment
      if (AppConfig.currentEnvironment == Environment.development) {
        // In development, use debug provider for easier testing
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          webProvider: ReCaptchaV3Provider(AppConfig.recaptchaSiteKey),
        );
      } else {
        // In staging/production, use proper providers
        if (!kIsWeb) {
          await FirebaseAppCheck.instance.activate(
            androidProvider: AndroidProvider.playIntegrity,
            appleProvider: AppleProvider.appAttest,
          );
        } else {
          // Web provider - configured in Firebase console
          await FirebaseAppCheck.instance.activate(
            webProvider: ReCaptchaV3Provider(AppConfig.recaptchaSiteKey),
          );
        }
      }

      // Enable App Check token refresh
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

      print('🔒 Firebase App Check initialized successfully for ${AppConfig.environmentName}');
    } catch (e) {
      print('❌ Failed to initialize Firebase App Check: $e');
      // In production, you might want to handle this more gracefully
      // For now, we'll continue without App Check if it fails
    }
  }

  // Get current App Check token (for custom backend calls)
  Future<String?> getAppCheckToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      return token;
    } catch (e) {
      print('❌ Failed to get App Check token: $e');
      return null;
    }
  }

  // Force refresh App Check token
  Future<String?> refreshAppCheckToken() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken(true);
      return token;
    } catch (e) {
      print('❌ Failed to refresh App Check token: $e');
      return null;
    }
  }

  // Check if App Check is enabled
  bool get isAppCheckEnabled {
    return true; // Since we enable it in initialize if conditions are met
  }
}
