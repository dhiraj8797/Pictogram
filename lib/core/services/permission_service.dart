import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/analytics_service.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  // Camera permissions
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      
      if (status.isGranted) {
        await AnalyticsService().trackCustomEvent('permission_granted', {
          'permission_type': 'camera',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return true;
      } else if (status.isPermanentlyDenied) {
        await AnalyticsService().trackCustomEvent('permission_permanently_denied', {
          'permission_type': 'camera',
          'timestamp': DateTime.now().toIso8601String(),
        });
        await _showPermissionDialog('Camera', 'camera');
        return false;
      } else {
        await AnalyticsService().trackCustomEvent('permission_denied', {
          'permission_type': 'camera',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return false;
      }
    } catch (e) {
      await AnalyticsService().trackError('permission_error', 'Camera permission check failed: $e');
      return false;
    }
  }

  // Storage permissions (for Android)
  Future<bool> requestStoragePermission() async {
    try {
      // For Android 13+ (API 33+), we need media permissions instead of storage
      if (defaultTargetPlatform == TargetPlatform.android) {
        final status = await Permission.photos.request();
        
        if (status.isGranted) {
          await AnalyticsService().trackCustomEvent('permission_granted', {
            'permission_type': 'photos',
            'timestamp': DateTime.now().toIso8601String(),
          });
          return true;
        } else if (status.isPermanentlyDenied) {
          await AnalyticsService().trackCustomEvent('permission_permanently_denied', {
            'permission_type': 'photos',
            'timestamp': DateTime.now().toIso8601String(),
          });
          await _showPermissionDialog('Photos', 'photos');
          return false;
        } else {
          await AnalyticsService().trackCustomEvent('permission_denied', {
            'permission_type': 'photos',
            'timestamp': DateTime.now().toIso8601String(),
          });
          return false;
        }
      } else {
        // iOS doesn't need storage permission for app-specific storage
        return true;
      }
    } catch (e) {
      await AnalyticsService().trackError('permission_error', 'Storage permission check failed: $e');
      return false;
    }
  }

  // Notification permissions (especially for Android 13+)
  Future<bool> requestNotificationPermission() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission for iOS
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await AnalyticsService().trackCustomEvent('permission_granted', {
          'permission_type': 'notifications',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return true;
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await AnalyticsService().trackCustomEvent('permission_denied', {
          'permission_type': 'notifications',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return false;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        await AnalyticsService().trackCustomEvent('permission_provisional', {
          'permission_type': 'notifications',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return true; // Provisional is still usable
      } else {
        await AnalyticsService().trackCustomEvent('permission_ephemeral', {
          'permission_type': 'notifications',
          'timestamp': DateTime.now().toIso8601String(),
        });
        return true; // Ephemeral is still usable
      }
    } catch (e) {
      await AnalyticsService().trackError('permission_error', 'Notification permission check failed: $e');
      return false;
    }
  }

  // Check all required permissions for image upload
  Future<bool> checkImageUploadPermissions() async {
    final cameraPermission = await requestCameraPermission();
    final storagePermission = await requestStoragePermission();
    
    return cameraPermission && storagePermission;
  }

  // Check notification permissions
  Future<bool> checkNotificationPermissions() async {
    return await requestNotificationPermission();
  }

  // Check if we need to show rationale for a permission
  Future<bool> shouldShowPermissionRationale(Permission permission) async {
    return await permission.shouldShowRequestRationale;
  }

  // Open app settings for manual permission grant
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
      await AnalyticsService().trackCustomEvent('app_settings_opened', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await AnalyticsService().trackError('permission_error', 'Failed to open app settings: $e');
    }
  }

  // Request all necessary permissions on app startup
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    // Request camera permission
    results['camera'] = await requestCameraPermission();
    
    // Request storage/photos permission
    results['photos'] = await requestStoragePermission();
    
    // Request notification permission
    results['notifications'] = await requestNotificationPermission();
    
    // Track the overall permission request event
    await AnalyticsService().trackCustomEvent('permissions_requested', {
      'camera_granted': results['camera'],
      'photos_granted': results['photos'],
      'notifications_granted': results['notifications'],
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return results;
  }

  // Check current status of all permissions
  Future<Map<String, PermissionStatus>> checkAllPermissionStatus() async {
    final statuses = <String, PermissionStatus>{};
    
    try {
      statuses['camera'] = await Permission.camera.status;
      statuses['photos'] = await Permission.photos.status;
      statuses['notifications'] = await Permission.notification.status;
      
      // Track permission status check
      await AnalyticsService().trackCustomEvent('permissions_status_checked', {
        'camera_status': statuses['camera']?.toString(),
        'photos_status': statuses['photos']?.toString(),
        'notifications_status': statuses['notifications']?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      await AnalyticsService().trackError('permission_error', 'Failed to check permission status: $e');
    }
    
    return statuses;
  }

  // Helper method to show permission dialog
  Future<void> _showPermissionDialog(String permissionType, String permissionKey) async {
    // This would typically show a dialog explaining why the permission is needed
    // and directing the user to app settings
    await AnalyticsService().trackCustomEvent('permission_dialog_shown', {
      'permission_type': permissionType,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Implementation would depend on your UI framework
    // You could use a package like 'permission_dialog' or implement custom dialog
  }

  // Handle image picker with permissions
  Future<ImageSource?> requestImagePickerPermission() async {
    final cameraPermission = await requestCameraPermission();
    
    if (cameraPermission) {
      return ImageSource.camera;
    }
    
    final storagePermission = await requestStoragePermission();
    
    if (storagePermission) {
      return ImageSource.gallery;
    }
    
    return null;
  }

  // Check specific permission with detailed status
  Future<PermissionInfo> getPermissionInfo(Permission permission) async {
    try {
      final status = await permission.status;
      final shouldShowRationale = await permission.shouldShowRequestRationale;
      
      return PermissionInfo(
        status: status,
        shouldShowRationale: shouldShowRationale,
        isGranted: status.isGranted,
        isDenied: status.isDenied,
        isPermanentlyDenied: status.isPermanentlyDenied,
        isLimited: status.isLimited,
        isRestricted: status.isRestricted,
      );
    } catch (e) {
      await AnalyticsService().trackError('permission_error', 'Failed to get permission info: $e');
      return PermissionInfo(
        status: PermissionStatus.denied,
        shouldShowRationale: false,
        isGranted: false,
        isDenied: true,
        isPermanentlyDenied: false,
        isLimited: false,
        isRestricted: false,
      );
    }
  }
}

// Permission info class for detailed status
class PermissionInfo {
  final PermissionStatus status;
  final bool shouldShowRationale;
  final bool isGranted;
  final bool isDenied;
  final bool isPermanentlyDenied;
  final bool isLimited;
  final bool isRestricted;

  PermissionInfo({
    required this.status,
    required this.shouldShowRationale,
    required this.isGranted,
    required this.isDenied,
    required this.isPermanentlyDenied,
    required this.isLimited,
    required this.isRestricted,
  });
}
