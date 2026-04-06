import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';
import 'package:local_auth_platform_interface/types/biometric_type.dart' as biometric_types;

// Biometric authentication state
class BiometricState {
  final bool isSupported;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final List<biometric_types.BiometricType> availableBiometrics;
  final biometric_types.BiometricType? primaryBiometric;

  const BiometricState({
    this.isSupported = false,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.availableBiometrics = const [],
    this.primaryBiometric,
  });

  BiometricState copyWith({
    bool? isSupported,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    List<biometric_types.BiometricType>? availableBiometrics,
    biometric_types.BiometricType? primaryBiometric,
  }) {
    return BiometricState(
      isSupported: isSupported ?? this.isSupported,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
      primaryBiometric: primaryBiometric ?? this.primaryBiometric,
    );
  }

  bool get canUseBiometrics => isSupported && availableBiometrics.isNotEmpty;
  bool get hasFaceId => availableBiometrics.contains(biometric_types.BiometricType.face);
  bool get hasFingerprint => availableBiometrics.contains(biometric_types.BiometricType.fingerprint);
  String get biometricName => primaryBiometric != null 
      ? BiometricService.getBiometricTypeName(primaryBiometric!)
      : 'Biometric';

  /// Get user-friendly status message
  String get statusMessage {
    if (errorMessage != null) {
      return errorMessage!;
    }

    if (!isSupported) {
      return 'Biometric authentication is not supported on this device';
    }

    if (availableBiometrics.isEmpty) {
      return 'No biometrics are enrolled. Please set up fingerprint or Face ID in your device settings.';
    }

    final biometricNames = availableBiometrics
        .map((type) => BiometricService.getBiometricTypeName(type))
        .join(' and ');

    return '$biometricNames available for secure login';
  }

  /// Get authentication prompt text
  String getAuthenticationPrompt() {
    if (hasFaceId) {
      return 'Use Face ID to access your account';
    } else if (hasFingerprint) {
      return 'Use fingerprint to access your account';
    } else {
      return 'Use biometric authentication to access your account';
    }
  }
}

// Biometric authentication provider
class BiometricProvider extends StateNotifier<BiometricState> {
  BiometricProvider() : super(const BiometricState());

  /// Initialize biometric capabilities
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final isSupported = await BiometricService.isDeviceSupported();
      
      if (!isSupported) {
        state = state.copyWith(
          isSupported: false,
          isLoading: false,
          errorMessage: 'Biometric authentication is not supported on this device',
        );
        return;
      }

      final availableBiometrics = await BiometricService.getAvailableBiometrics();
      final primaryBiometric = await BiometricService.getPrimaryBiometricType();

      state = state.copyWith(
        isSupported: true,
        availableBiometrics: availableBiometrics,
        primaryBiometric: primaryBiometric,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize biometric authentication: $e',
      );
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    String reason = 'Authenticate to access PictoGram',
  }) async {
    if (!state.canUseBiometrics) {
      state = state.copyWith(
        errorMessage: 'Biometric authentication is not available',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final isAuthenticated = await BiometricService.authenticate(
        reason: reason,
      );

      state = state.copyWith(
        isAuthenticated: isAuthenticated,
        isLoading: false,
        errorMessage: isAuthenticated ? null : 'Authentication failed',
      );

      return isAuthenticated;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Authentication error: $e',
      );
      return false;
    }
  }

  /// Reset authentication state
  void reset() {
    state = state.copyWith(
      isAuthenticated: false,
      errorMessage: null,
      isLoading: false,
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Get user-friendly status message
  String get statusMessage {
    if (state.errorMessage != null) {
      return state.errorMessage!;
    }

    if (!state.isSupported) {
      return 'Biometric authentication is not supported on this device';
    }

    if (state.availableBiometrics.isEmpty) {
      return 'No biometrics are enrolled. Please set up fingerprint or Face ID in your device settings.';
    }

    final biometricNames = state.availableBiometrics
        .map((type) => BiometricService.getBiometricTypeName(type))
        .join(' and ');

    return '$biometricNames available for secure login';
  }

  /// Get authentication prompt text
  String getAuthenticationPrompt() {
    if (state.hasFaceId) {
      return 'Use Face ID to access your account';
    } else if (state.hasFingerprint) {
      return 'Use fingerprint to access your account';
    } else {
      return 'Use biometric authentication to access your account';
    }
  }

  /// Get biometric icon
  String get biometricIcon {
    if (state.hasFaceId) {
      return '👤'; // Face ID icon
    } else if (state.hasFingerprint) {
      return '👆'; // Fingerprint icon
    } else {
      return '🔐'; // Generic biometric icon
    }
  }
}

// Provider instances
final biometricProvider = StateNotifierProvider<BiometricProvider, BiometricState>((ref) {
  return BiometricProvider();
});

final biometricStatusProvider = Provider<String>((ref) {
  final biometricState = ref.watch(biometricProvider);
  return biometricState.statusMessage;
});

final canUseBiometricsProvider = Provider<bool>((ref) {
  final biometricState = ref.watch(biometricProvider);
  return biometricState.canUseBiometrics;
});

final biometricNameProvider = Provider<String>((ref) {
  final biometricState = ref.watch(biometricProvider);
  return biometricState.biometricName;
});
