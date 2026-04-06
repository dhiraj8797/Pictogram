import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/crash_reporting_service.dart';
import '../services/analytics_service.dart';
import '../services/permission_service.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

// Permission service provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

// Story refresh provider - increment to trigger home screen story refresh
final storyRefreshProvider = StateProvider<int>((ref) => 0);

// Latest created story - set immediately after story creation for instant display
final latestCreatedStoryProvider = StateProvider<Map<String, dynamic>?>((ref) => null);

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current user provider
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.asyncMap((firebaseUser) async {
    if (firebaseUser == null) {
      // Clear user identifiers from services when user logs out
      await CrashReportingService().clearUserIdentifier();
      await AnalyticsService().setUserId('anonymous');
      await AnalyticsService().setUserProperties();
      return null;
    }
    
    try {
      final userData = await authService.getUserData(firebaseUser.uid);
      
      // Set user identifiers in services
      await CrashReportingService().setUserIdentifier(firebaseUser.uid);
      await AnalyticsService().setUserId(firebaseUser.uid);
      
      // Track user properties for analytics
      if (userData != null) {
        await AnalyticsService().setUserProperties(
          displayName: userData.displayName,
          tier: userData.tier ?? 'free',
          accountAge: _calculateAccountAge(userData.createdAt),
        );
      }
      
      return userData;
    } catch (e) {
      // Record auth errors in crash reporting and analytics
      await CrashReportingService().recordAuthError('get_user_data', e, StackTrace.current);
      await AnalyticsService().trackError('auth_error', 'Failed to get user data: $e');
      return null;
    }
  });
});

// Helper function to calculate account age
String _calculateAccountAge(Timestamp createdAt) {
  final days = DateTime.now().difference(createdAt.toDate()).inDays;
  if (days < 7) return '<1_week';
  if (days < 30) return '<1_month';
  if (days < 365) return '<1_year';
  return '>1_year';
}

// User data provider
final userDataProvider = FutureProvider.family<AppUser?, String>((ref, uid) {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserData(uid);
});

// Auth state provider for UI state management
class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isPendingGoogle;
  final String? pendingUid;
  final String? pendingEmail;
  final String? pendingDisplayName;
  final String? pendingProfileImage;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isPendingGoogle = false,
    this.pendingUid,
    this.pendingEmail,
    this.pendingDisplayName,
    this.pendingProfileImage,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isPendingGoogle,
    String? pendingUid,
    String? pendingEmail,
    String? pendingDisplayName,
    String? pendingProfileImage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPendingGoogle: isPendingGoogle ?? this.isPendingGoogle,
      pendingUid: pendingUid ?? this.pendingUid,
      pendingEmail: pendingEmail ?? this.pendingEmail,
      pendingDisplayName: pendingDisplayName ?? this.pendingDisplayName,
      pendingProfileImage: pendingProfileImage ?? this.pendingProfileImage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.success) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    print('DEBUG: AuthNotifier: Starting sign in for $email');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.signInWithEmail(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Login timeout in AuthNotifier');
        },
      );

      print('DEBUG: AuthNotifier: Sign in result - success: ${result.success}');
      
      if (result.success) {
        state = state.copyWith(isLoading: false, isAuthenticated: true);
        print('DEBUG: AuthNotifier: Login successful, state updated');
      } else {
        print('DEBUG: AuthNotifier: Login failed - ${result.error}');
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      print('DEBUG: AuthNotifier: Exception in signInWithEmail: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final result = await _authService.signInWithGoogle();
      
      if (result.success) {
        // Existing user - authenticated
        state = state.copyWith(isLoading: false, isAuthenticated: true);
      } else if (result.isPending) {
        // New user - waiting for permission screen
        state = state.copyWith(
          isLoading: false,
          isPendingGoogle: true,
          pendingUid: result.pendingUid,
          pendingEmail: result.pendingEmail,
          pendingDisplayName: result.pendingDisplayName,
          pendingProfileImage: result.pendingProfileImage,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _authService.signOut();
    state = state.copyWith(isLoading: false, isAuthenticated: false);
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authService.sendPasswordResetEmail(email);

    if (result.success) {
      state = state.copyWith(isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: result.error);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
