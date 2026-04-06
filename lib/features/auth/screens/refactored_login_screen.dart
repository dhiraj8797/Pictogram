import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/biometric_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_glass_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

const Color _pink  = Color.fromRGBO(255, 61,  135, 1.0);
const Color _coral = Color.fromRGBO(255, 106,  92, 1.0);
const Color _cardBorder = Color.fromRGBO(255, 255, 255, 0.10);

class RefactoredLoginScreen extends ConsumerStatefulWidget {
  const RefactoredLoginScreen({super.key});

  @override
  ConsumerState<RefactoredLoginScreen> createState() => _RefactoredLoginScreenState();
}

class _RefactoredLoginScreenState extends ConsumerState<RefactoredLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Check auth state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated && mounted) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    // Prevent multiple clicks with debouncing
    if (_isProcessing) return;

    // Validate input immediately
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Email validation
    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    // Password validation
    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters long');
      return;
    }

    _isProcessing = true;
    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      
      // Email login with shorter timeout
      await authNotifier.signInWithEmail(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException('Login timeout. Please try again.');
        },
      );

      if (mounted) {
        context.pushReplacement('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Login failed';
        
        // Handle specific Firebase auth errors
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'No account found with this email';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Incorrect password';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address';
        } else if (e.toString().contains('user-disabled')) {
          errorMessage = 'This account has been disabled';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Too many failed attempts. Please try again later';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage = 'Network error. Please check your connection';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Login timeout. Please check your connection and try again.';
        } else {
          errorMessage = 'Login failed: ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        _showError(errorMessage);
      }
    } finally {
      // Reset processing states
      _isProcessing = false;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Email validation regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).clearSnackBars();
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes to auto-navigate after Google Sign-In
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        context.go('/home');
      }
      if (next.isPendingGoogle && next.pendingUid != null && mounted) {
        // Navigate to permission screen for new Google users
        context.push('/google-permission', extra: {
          'uid': next.pendingUid!,
          'email': next.pendingEmail!,
          'displayName': next.pendingDisplayName!,
          'profileImage': next.pendingProfileImage,
        });
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const AuthHeader(
                  title: 'Welcome Back',
                  subtitle: 'Sign in to continue sharing your moments on PictoGram',
                ),
                const SizedBox(height: 28),
                AuthGlassCard(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  radius: 20,
                  child: Column(
                    children: [
                      AuthTextField(
                        controller: emailController,
                        hintText: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12), // Reduced from 14
                      AuthTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Reduced from 12
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => context.push('/forgot-password'),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Reduced from 8
                      AuthButton(
                        text: 'Login',
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          final canUseBiometrics = ref.watch(canUseBiometricsProvider);
                          final biometricName = ref.watch(biometricNameProvider);
                          if (!canUseBiometrics) return const SizedBox.shrink();
                          return GestureDetector(
                            onTap: () => context.go('/biometric-login'),
                            child: Container(
                              width: double.infinity,
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_pink, _coral],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pink.withValues(alpha: 0.30),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.fingerprint,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Login with $biometricName',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: _cardBorder)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or continue with',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ),
                          const Expanded(child: Divider(color: _cardBorder)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Social Login Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _GlassSocialBtn(
                            onTap: () async => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
                            glowColor: const Color(0xFF4285F4),
                            child: _GoogleLetterG(),
                          ),
                          _GlassSocialBtn(
                            onTap: () {},
                            glowColor: const Color(0xFF1DA1F2),
                            child: const Icon(Icons.flight_rounded, color: Colors.white, size: 22),
                          ),
                          _GlassSocialBtn(
                            onTap: () {},
                            glowColor: Colors.white,
                            child: _XLettermark(),
                          ),
                          _GlassSocialBtn(
                            onTap: () => context.push('/phone-auth'),
                            glowColor: _pink,
                            child: const Icon(Icons.phone_rounded, color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Reduced from 22
                AuthGlassCard(
                  radius: 16, // Reduced from 22
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14, // Reduced from 16
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14, // Reduced from 15
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          context.push('/signup');
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14, // Reduced from 15
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

// ── HD Glassy social button ───────────────────────────────────────────────────
class _GlassSocialBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Color glowColor;
  final Widget child;
  const _GlassSocialBtn({required this.onTap, required this.glowColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glowColor.withValues(alpha: 0.18),
                  glowColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: glowColor.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.20),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

// Google multicolour segmented G
class _GoogleLetterG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'G',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [
                  Color(0xFF4285F4),
                  Color(0xFF34A853),
                  Color(0xFFFBBC05),
                  Color(0xFFEA4335),
                ],
              ).createShader(const Rect.fromLTWH(0, 0, 28, 28)),
          ),
        ),
      ],
    );
  }
}

// X lettermark
class _XLettermark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'X',
      style: TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}


