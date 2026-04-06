import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth_platform_interface/types/biometric_type.dart' as biometric_types;

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      debugPrint('BIOMETRIC: Device supported: $isSupported');
      return isSupported;
    } catch (e) {
      debugPrint('BIOMETRIC: Error checking device support: $e');
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      debugPrint('BIOMETRIC: Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      debugPrint('BIOMETRIC: Error getting available biometrics: $e');
      return [];
    }
  }

  /// Check if biometrics are enrolled
  static Future<bool> areBiometricsEnrolled() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint('BIOMETRIC: Error checking biometric enrollment: $e');
      return false;
    }
  }

  /// Authenticate with biometrics
  static Future<bool> authenticate({
    String reason = 'Authenticate to access PictoGram',
  }) async {
    try {
      debugPrint('BIOMETRIC: Starting authentication...');
      
      final isAuthenticated = await _auth.authenticate(
        localizedReason: reason,
      );

      debugPrint('BIOMETRIC: Authentication result: $isAuthenticated');
      return isAuthenticated;
    } on PlatformException catch (e) {
      debugPrint('BIOMETRIC: Platform exception during authentication: ${e.code}');
      
      switch (e.code) {
        case 'NotAvailable':
          debugPrint('BIOMETRIC: Biometric authentication is not available');
          break;
        case 'NotEnrolled':
          debugPrint('BIOMETRIC: No biometrics enrolled on this device');
          break;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          debugPrint('BIOMETRIC: Biometric authentication locked out');
          break;
        case 'OtherOperatingSystem':
          debugPrint('BIOMETRIC: Biometric authentication not supported on this OS');
          break;
        default:
          debugPrint('BIOMETRIC: Unknown biometric error: ${e.message}');
          break;
      }
      return false;
    } catch (e) {
      debugPrint('BIOMETRIC: Unknown error during authentication: $e');
      return false;
    }
  }

  /// Stop authentication (for sticky auth)
  static Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
      debugPrint('BIOMETRIC: Authentication stopped');
    } catch (e) {
      debugPrint('BIOMETRIC: Error stopping authentication: $e');
    }
  }

  /// Get biometric type name for display
  static String getBiometricTypeName(biometric_types.BiometricType type) {
    switch (type) {
      case biometric_types.BiometricType.fingerprint:
        return 'Fingerprint';
      case biometric_types.BiometricType.face:
        return 'Face ID';
      case biometric_types.BiometricType.iris:
        return 'Iris Scanner';
      case biometric_types.BiometricType.weak:
        return 'Device Unlock';
      case biometric_types.BiometricType.strong:
        return 'Strong Biometric';
      default:
        return 'Biometric';
    }
  }

  /// Get user-friendly biometric status message
  static Future<String> getBiometricStatusMessage() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) {
        return 'Biometric authentication is not supported on this device';
      }

      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return 'No biometrics are enrolled. Please set up fingerprint or Face ID in your device settings.';
      }

      final biometricNames = availableBiometrics
          .map((type) => getBiometricTypeName(type))
          .join(' and ');

      return '$biometricNames available for secure login';
    } catch (e) {
      return 'Unable to check biometric status: $e';
    }
  }

  /// Check if face ID is available
  static Future<bool> isFaceIdAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(biometric_types.BiometricType.face);
    } catch (e) {
      debugPrint('BIOMETRIC: Error checking Face ID availability: $e');
      return false;
    }
  }

  /// Check if fingerprint is available
  static Future<bool> isFingerprintAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(biometric_types.BiometricType.fingerprint);
    } catch (e) {
      debugPrint('BIOMETRIC: Error checking fingerprint availability: $e');
      return false;
    }
  }

  /// Get primary biometric type for UI display
  static Future<biometric_types.BiometricType?> getPrimaryBiometricType() async {
    try {
      final biometrics = await getAvailableBiometrics();
      
      // Prioritize Face ID over fingerprint
      if (biometrics.contains(biometric_types.BiometricType.face)) {
        return biometric_types.BiometricType.face;
      }
      if (biometrics.contains(biometric_types.BiometricType.fingerprint)) {
        return biometric_types.BiometricType.fingerprint;
      }
      
      return biometrics.isNotEmpty ? biometrics.first : null;
    } catch (e) {
      debugPrint('BIOMETRIC: Error getting primary biometric type: $e');
      return null;
    }
  }
}
