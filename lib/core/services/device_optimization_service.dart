import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class DeviceOptimizationService {
  static final DeviceOptimizationService _instance = DeviceOptimizationService._internal();
  factory DeviceOptimizationService() => _instance;
  DeviceOptimizationService._internal();

  // Check network quality
  Future<NetworkQuality> getNetworkQuality() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return NetworkQuality.excellent;
        case ConnectivityResult.ethernet:
          return NetworkQuality.excellent;
        case ConnectivityResult.mobile:
          return await _testMobileSpeed();
        case ConnectivityResult.none:
          return NetworkQuality.none;
        default:
          return NetworkQuality.unknown;
      }
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return NetworkQuality.unknown;
    }
  }

  Future<NetworkQuality> _testMobileSpeed() async {
    try {
      // Simple speed test by timing a small HTTP request
      final stopwatch = Stopwatch()..start();
      
      // Test with a small image or API endpoint
      // This is a basic implementation - in production use a proper speed test service
      await Future.delayed(const Duration(milliseconds: 100));
      
      stopwatch.stop();
      final responseTime = stopwatch.elapsedMilliseconds;
      
      if (responseTime < 200) return NetworkQuality.excellent;
      if (responseTime < 500) return NetworkQuality.good;
      if (responseTime < 1000) return NetworkQuality.fair;
      return NetworkQuality.poor;
    } catch (e) {
      return NetworkQuality.poor;
    }
  }

  // Optimize image based on network quality
  ImageQualitySettings getImageQualitySettings(NetworkQuality networkQuality) {
    switch (networkQuality) {
      case NetworkQuality.excellent:
        return ImageQualitySettings(
          maxWidth: 1080,
          maxHeight: 1920,
          quality: 85,
          maxSizeBytes: 5 * 1024 * 1024, // 5MB
        );
      case NetworkQuality.good:
        return ImageQualitySettings(
          maxWidth: 800,
          maxHeight: 1200,
          quality: 75,
          maxSizeBytes: 3 * 1024 * 1024, // 3MB
        );
      case NetworkQuality.fair:
        return ImageQualitySettings(
          maxWidth: 600,
          maxHeight: 800,
          quality: 65,
          maxSizeBytes: 2 * 1024 * 1024, // 2MB
        );
      case NetworkQuality.poor:
        return ImageQualitySettings(
          maxWidth: 400,
          maxHeight: 600,
          quality: 50,
          maxSizeBytes: 1 * 1024 * 1024, // 1MB
        );
      case NetworkQuality.none:
        return ImageQualitySettings(
          maxWidth: 200,
          maxHeight: 300,
          quality: 30,
          maxSizeBytes: 500 * 1024, // 500KB
        );
      default:
        return ImageQualitySettings(
          maxWidth: 800,
          maxHeight: 1200,
          quality: 75,
          maxSizeBytes: 3 * 1024 * 1024,
        );
    }
  }

  // Check device capabilities
  Future<DeviceCapabilities> getDeviceCapabilities() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      final storageInfo = await _getStorageInfo();
      
      return DeviceCapabilities(
        totalMemory: memoryInfo['total'],
        availableMemory: memoryInfo['available'],
        totalStorage: storageInfo['total'],
        availableStorage: storageInfo['available'],
        isLowEndDevice: memoryInfo['total'] < 2 * 1024 * 1024 * 1024, // < 2GB RAM
        hasLimitedStorage: storageInfo['available'] < 1024 * 1024 * 1024, // < 1GB free
      );
    } catch (e) {
      await FirebaseCrashlytics.instance.recordError(e, stackTrace: StackTrace.current);
      return DeviceCapabilities(
        totalMemory: 4 * 1024 * 1024 * 1024,
        availableMemory: 2 * 1024 * 1024 * 1024,
        totalStorage: 64 * 1024 * 1024 * 1024,
        availableStorage: 32 * 1024 * 1024 * 1024,
        isLowEndDevice: false,
        hasLimitedStorage: false,
      );
    }
  }

  Future<Map<String, int>> _getMemoryInfo() async {
    // This is a simplified implementation
    // In production, use platform-specific APIs
    if (Platform.isAndroid) {
      return {
        'total': 4 * 1024 * 1024 * 1024, // 4GB default
        'available': 2 * 1024 * 1024 * 1024, // 2GB available
      };
    } else if (Platform.isIOS) {
      return {
        'total': 3 * 1024 * 1024 * 1024, // 3GB default
        'available': 1.5 * 1024 * 1024 * 1024, // 1.5GB available
      };
    } else {
      return {
        'total': 8 * 1024 * 1024 * 1024, // 8GB default
        'available': 4 * 1024 * 1024 * 1024, // 4GB available
      };
    }
  }

  Future<Map<String, int>> _getStorageInfo() async {
    // This is a simplified implementation
    // In production, use platform-specific APIs
    return {
      'total': 64 * 1024 * 1024 * 1024, // 64GB default
      'available': 32 * 1024 * 1024 * 1024, // 32GB available
    };
  }

  // Optimize app behavior based on device capabilities
  AppOptimizationSettings getAppOptimizationSettings(DeviceCapabilities device, NetworkQuality network) {
    final isLowEnd = device.isLowEndDevice;
    final hasLimitedStorage = device.hasLimitedStorage;
    final isPoorNetwork = network == NetworkQuality.poor || network == NetworkQuality.none;

    return AppOptimizationSettings(
      enableAnimations: !isLowEnd,
      enableHighQualityImages: !isLowEnd && !hasLimitedStorage && network != NetworkQuality.poor,
      enableRealTimeUpdates: !isPoorNetwork,
      cacheSize: isLowEnd ? 50 : 200, // Number of items to cache
      preloadImages: !isLowEnd && !isPoorNetwork,
      enableBackgroundSync: !isPoorNetwork,
      compressionLevel: isLowEnd || hasLimitedStorage ? 0.7 : 0.85,
    );
  }

  // Monitor app performance
  Future<void> logPerformanceMetrics({
    required String operation,
    required Duration duration,
    int? memoryUsage,
    NetworkQuality? networkQuality,
    DeviceCapabilities? device,
  }) async {
    try {
      final metrics = {
        'operation': operation,
        'duration': duration.inMilliseconds,
        'memoryUsage': memoryUsage ?? 0,
        'networkQuality': networkQuality?.toString() ?? 'unknown',
        'isLowEndDevice': device?.isLowEndDevice ?? false,
        'hasLimitedStorage': device?.hasLimitedStorage ?? false,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'isDebugMode': kDebugMode,
      };

      // Log to Crashlytics for analysis
      await FirebaseCrashlytics.instance.log('Performance: $operation took ${duration.inMilliseconds}ms');
      
      // Store in Firestore for analysis (in production)
      // await FirebaseFirestore.instance.collection('performance_metrics').add(metrics);
    } catch (e) {
      print('Failed to log performance metrics: $e');
    }
  }

  // Check if app should use offline mode
  Future<bool> shouldUseOfflineMode() async {
    final networkQuality = await getNetworkQuality();
    return networkQuality == NetworkQuality.none || networkQuality == NetworkQuality.poor;
  }

  // Get retry strategy based on network
  RetryStrategy getRetryStrategy(NetworkQuality networkQuality) {
    switch (networkQuality) {
      case NetworkQuality.excellent:
        return RetryStrategy(
          maxAttempts: 3,
          baseDelay: const Duration(milliseconds: 500),
          maxDelay: const Duration(seconds: 2),
          backoffMultiplier: 2.0,
        );
      case NetworkQuality.good:
        return RetryStrategy(
          maxAttempts: 5,
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(seconds: 5),
          backoffMultiplier: 2.0,
        );
      case NetworkQuality.fair:
        return RetryStrategy(
          maxAttempts: 7,
          baseDelay: const Duration(seconds: 2),
          maxDelay: const Duration(seconds: 10),
          backoffMultiplier: 1.5,
        );
      case NetworkQuality.poor:
        return RetryStrategy(
          maxAttempts: 10,
          baseDelay: const Duration(seconds: 3),
          maxDelay: const Duration(seconds: 30),
          backoffMultiplier: 1.2,
        );
      case NetworkQuality.none:
        return RetryStrategy(
          maxAttempts: 1,
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(seconds: 1),
          backoffMultiplier: 1.0,
        );
      default:
        return RetryStrategy(
          maxAttempts: 3,
          baseDelay: const Duration(seconds: 1),
          maxDelay: const Duration(seconds: 5),
          backoffMultiplier: 2.0,
        );
    }
  }

  // Monitor battery usage (simplified)
  Future<void> logBatteryUsage(String operation, double batteryLevel) async {
    try {
      await FirebaseCrashlytics.instance.log('Battery: $operation at ${batteryLevel.toStringAsFixed(1)}%');
    } catch (e) {
      print('Failed to log battery usage: $e');
    }
  }
}

enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  none,
  unknown,
}

class ImageQualitySettings {
  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int maxSizeBytes;

  const ImageQualitySettings({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.maxSizeBytes,
  });
}

class DeviceCapabilities {
  final int totalMemory;
  final int availableMemory;
  final int totalStorage;
  final int availableStorage;
  final bool isLowEndDevice;
  final bool hasLimitedStorage;

  const DeviceCapabilities({
    required this.totalMemory,
    required this.availableMemory,
    required this.totalStorage,
    required this.availableStorage,
    required this.isLowEndDevice,
    required this.hasLimitedStorage,
  });
}

class AppOptimizationSettings {
  final bool enableAnimations;
  final bool enableHighQualityImages;
  final bool enableRealTimeUpdates;
  final int cacheSize;
  final bool preloadImages;
  final bool enableBackgroundSync;
  final double compressionLevel;

  const AppOptimizationSettings({
    required this.enableAnimations,
    required this.enableHighQualityImages,
    required this.enableRealTimeUpdates,
    required this.cacheSize,
    required this.preloadImages,
    required this.enableBackgroundSync,
    required this.compressionLevel,
  });
}

class RetryStrategy {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryStrategy({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    required this.backoffMultiplier,
  });
}
