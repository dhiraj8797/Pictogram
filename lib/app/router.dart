import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/auth/screens/otp_verification_screen.dart';
import '../features/auth/screens/phone_auth_screen.dart';
import '../features/auth/screens/verify_email_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/glass_login_screen.dart';
import '../features/auth/screens/glass_login_screen_exact.dart';
import '../features/auth/screens/glass_signup_screen_exact.dart';
import '../features/auth/screens/refactored_login_screen.dart';
import '../features/auth/screens/refactored_signup_screen.dart';
import '../features/auth/screens/terms_screen.dart';
import '../features/auth/screens/privacy_screen.dart';
import '../features/auth/screens/biometric_login_screen.dart';
import '../features/auth/screens/google_permission_screen.dart';
import '../features/home/screens/glass_home_screen.dart';
import '../features/upload/screens/upload_screen.dart';
import '../features/profile/screens/glass_profile_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/stories/screens/story_viewer_screen.dart';
import '../features/comments/screens/comments_screen.dart';
import '../features/verification/screens/verification_screen.dart';
import '../features/debug/screens/firebase_test_screen.dart';
import '../features/debug/screens/detailed_firebase_test.dart';
import '../features/debug/screens/chat_test_screen.dart';
import '../features/stories/screens/create_story_screen.dart';
import '../features/stories/screens/story_edit_screen.dart';
import '../features/stories/screens/story_viewer_screen.dart';
import '../features/post/screens/edit_post_screen.dart';
import '../features/post/screens/post_detail_screen.dart';
import '../features/messages/screens/messages_screen.dart';
import '../features/messages/screens/chat_screen.dart';
import '../core/models/post.dart';
import '../core/models/story.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/glass_widgets.dart';
import 'dart:io';

// ── Trendily Splash Screen with first-launch detection ───────────────────────
const Color _splashBgDark = Color.fromRGBO(16,  7, 18, 1.0);
const Color _splashBgTop  = Color.fromRGBO(37,  4, 20, 1.0);
const Color _splashPink   = Color.fromRGBO(255, 61, 135, 1.0);
const Color _splashCoral  = Color.fromRGBO(255, 106, 92, 1.0);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _fade  = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _scale = Tween(begin: 0.82, end: 1.0).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _anim.forward();
    _checkAndNavigate();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    // Show splash for a moment
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasLaunchedBefore = prefs.getBool('app_launched_before') ?? false;

    if (!mounted) return;

    if (!hasLaunchedBefore) {
      // First install on this device → signup
      await prefs.setBool('app_launched_before', true);
      if (mounted) context.go('/signup');
      return;
    }

    // Not first install → check auth state
    final authNotifierState = ref.read(authNotifierProvider);
    final authState = ref.read(currentUserProvider).value;
    final isAuthenticated =
        authState != null && !authNotifierState.isPendingGoogle;
    if (mounted) context.go(isAuthenticated ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_splashBgTop, _splashBgDark],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pink radial glow
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3),
                  radius: 1.0,
                  colors: [
                    Color.fromRGBO(255, 61, 135, 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo circle
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_splashPink, _splashCoral],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _splashPink.withValues(alpha: 0.45),
                              blurRadius: 30,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.photo_camera_rounded,
                            color: Colors.white, size: 44),
                      ),
                      const SizedBox(height: 22),
                      // App name
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [_splashPink, _splashCoral],
                        ).createShader(bounds),
                        child: const Text(
                          'PictoGram',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share your world',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 28, height: 28,
                        child: CircularProgressIndicator(
                          color: _splashPink.withValues(alpha: 0.7),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash', // Start with splash screen to check auth state
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The requested page could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(currentUserProvider).value;
      final authNotifierState = ref.read(authNotifierProvider);
      final isAuthenticated = authState != null && !authNotifierState.isPendingGoogle;
      final isSplashPage = state.uri.toString() == '/splash';
      final isLoginPage = state.uri.toString() == '/login';
      final isOldLoginPage = state.uri.toString() == '/old-login';
      final isGlassLoginPage = state.uri.toString() == '/glass-login';
      final isGlassLoginPageExact = state.uri.toString() == '/glass-login-exact';
      final isSignupPage = state.uri.toString() == '/signup';
      final isOldSignupPage = state.uri.toString() == '/old-signup';
      final isGlassSignupPageExact = state.uri.toString() == '/glass-signup-exact';
      final isOtpPage = state.uri.toString().startsWith('/otp-verify');
      final isEmailVerifyPage = state.uri.toString().startsWith('/verify-email');
      final isForgotPasswordPage = state.uri.toString() == '/forgot-password';
      final isResetPasswordPage = state.uri.toString().startsWith('/reset-password');
      final isPhoneAuthPage = state.uri.toString() == '/phone-auth';
      final isGooglePermissionPage = state.uri.toString() == '/google-permission';
      final isTermsPage = state.uri.toString() == '/terms';
      final isPrivacyPage = state.uri.toString() == '/privacy';

      // Splash handles its own navigation via _checkAndNavigate()
      if (isSplashPage) return null;

      // Allow Google permission screen to show for pending users
      if (authNotifierState.isPendingGoogle && isGooglePermissionPage) {
        return null;
      }

      // If not authenticated and not on auth pages, redirect to login
      if (!isAuthenticated && !isLoginPage && !isOldLoginPage && !isGlassLoginPage && !isGlassLoginPageExact && !isSignupPage && !isOldSignupPage && !isGlassSignupPageExact && !isOtpPage && !isPhoneAuthPage && !isTermsPage && !isPrivacyPage && !isEmailVerifyPage && !isForgotPasswordPage && !isResetPasswordPage && !isGooglePermissionPage) {
        return '/login';
      }

      // If authenticated and on auth pages, redirect to home
      if (isAuthenticated && (isLoginPage || isOldLoginPage || isGlassLoginPage || isGlassLoginPageExact || isSignupPage || isOldSignupPage || isGlassSignupPageExact || isOtpPage || isEmailVerifyPage || isForgotPasswordPage || isResetPasswordPage)) {
        return '/home';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Splash screen for initial auth check
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const RefactoredLoginScreen(),
      ),
      GoRoute(
        path: '/biometric-login',
        builder: (context, state) => const BiometricLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const RefactoredSignupScreen(),
      ),
      GoRoute(
        path: '/old-login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/old-signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/glass-login',
        builder: (context, state) => const GlassLoginScreen(),
      ),
      GoRoute(
        path: '/glass-login-exact',
        builder: (context, state) => const GlassLoginScreenExact(),
      ),
      GoRoute(
        path: '/glass-signup-exact',
        builder: (context, state) => const GlassSignupScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/phone-auth',
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OTPVerificationScreen(
            phoneNumber: extra['phoneNumber'] ?? '',
            verificationId: extra['verificationId'] ?? '',
            username: extra['username'],
            displayName: extra['displayName'],
            isSignup: extra['isSignup'] ?? false,
          );
        },
      ),
      // Email verification (OTP via email)
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      // Forgot password
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Reset password
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          final token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(
            email: email,
            token: token,
          );
        },
      ),
      // Google Sign-In permission screen
      GoRoute(
        path: '/google-permission',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return GooglePermissionScreen(
            uid: extra['uid'] ?? '',
            email: extra['email'] ?? '',
            displayName: extra['displayName'] ?? '',
            profileImage: extra['profileImage'],
          );
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const GlassHomeScreen(),
              ),
            ],
          ),
          // Search branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Upload branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/upload',
                builder: (context, state) => const UploadScreen(),
              ),
            ],
          ),
          // Notifications branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          // Profile branch
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  final currentUser = ProviderScope.containerOf(context).read(currentUserProvider).value;
                  if (currentUser == null) {
                    return const LoginScreen();
                  }
                  return GlassProfileScreen(userId: currentUser.uid);
                },
              ),
              GoRoute(
                path: '/profile/:userId',
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return GlassProfileScreen(userId: userId);
                },
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/story/:storyId',
        builder: (context, state) {
          final storyId = state.pathParameters['storyId']!;
          return StoryViewerScreen(initialStoryId: storyId);
        },
      ),

      GoRoute(
        path: '/comments/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return CommentsScreen(postId: postId);
        },
      ),

      GoRoute(
        path: '/verification',
        builder: (context, state) => const VerificationScreen(),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: '/edit-profile',
        builder: (context, state) {
          final isFirstTime = state.uri.queryParameters['firstTime'] == 'true';
          return EditProfileScreen(isFirstTimeSetup: isFirstTime);
        },
      ),

      GoRoute(
        path: '/firebase-test',
        builder: (context, state) => const FirebaseTestScreen(),
      ),

      GoRoute(
        path: '/detailed-test',
        builder: (context, state) => const DetailedFirebaseTest(),
      ),

      GoRoute(
        path: '/chat-test',
        builder: (context, state) => const ChatTestScreen(),
      ),

      GoRoute(
        path: '/create-story',
        builder: (context, state) => const CreateStoryScreen(),
      ),

      GoRoute(
        path: '/story-edit',
        builder: (context, state) {
          final imageFile = state.extra as File?;
          return StoryEditScreen(imageFile: imageFile);
        },
      ),

      GoRoute(
        path: '/story-viewer',
        builder: (context, state) {
          final extra = state.extra;
          List<Story>? stories;
          String? initialId;
          if (extra is List<Story>) {
            stories = extra.reversed.toList(); // newest first
            initialId = null; // start from index 0 = newest
          } else if (extra is Story) {
            stories = [extra];
            initialId = null;
          }
          return StoryViewerScreen(
            initialStoryId: initialId,
            stories: stories,
          );
        },
      ),

      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),

      GoRoute(
        path: '/edit-post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final post = state.extra as Post;
          return EditPostScreen(post: post);
        },
      ),

      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
      ),

      GoRoute(
        path: '/chat/:chatId',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatScreen(
            chatId: chatId,
            otherName: extra['otherName'] ?? 'User',
            otherPhoto: extra['otherPhoto'] ?? '',
            otherUid: extra['otherUid'] ?? '',
          );
        },
      ),
    ],
  );
});

int _getCurrentIndex(String location) {
  if (location.startsWith('/home')) return 0;
  if (location.startsWith('/search')) return 1;
  if (location.startsWith('/upload')) return 2;
  if (location.startsWith('/messages')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}

class MainScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/search');
              break;
            case 2:
              context.go('/upload');
              break;
            case 3:
              context.go('/messages');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Glassmorphism Scaffold with Navigation
class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: GlassCard(
          radius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_rounded,
                index: 0,
                currentIndex: navigationShell.currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.search_rounded,
                index: 1,
                currentIndex: navigationShell.currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.add_rounded,
                index: 2,
                currentIndex: navigationShell.currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.favorite_border_rounded,
                index: 3,
                currentIndex: navigationShell.currentIndex,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_rounded,
                index: 4,
                currentIndex: navigationShell.currentIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required int index,
    required int currentIndex,
  }) {
    final isSelected = index == currentIndex;
    
    return GestureDetector(
      onTap: () => navigationShell.goBranch(index),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Colors.white.withOpacity(0.18)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}