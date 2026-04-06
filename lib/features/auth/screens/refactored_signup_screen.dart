import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_glass_card.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

const Color _pink  = Color.fromRGBO(255, 61,  135, 1.0);
const Color _coral = Color.fromRGBO(255, 106,  92, 1.0);

class RefactoredSignupScreen extends ConsumerStatefulWidget {
  const RefactoredSignupScreen({super.key});

  @override
  ConsumerState<RefactoredSignupScreen> createState() => _RefactoredSignupScreenState();
}

class _RefactoredSignupScreenState extends ConsumerState<RefactoredSignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptedTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return false;
    }
    if (emailController.text.trim().isEmpty) {
      _showError('Please enter your email');
      return false;
    }
    if (!emailController.text.contains('@')) {
      _showError('Please enter a valid email');
      return false;
    }
    if (mobileController.text.trim().isEmpty) {
      _showError('Please enter your mobile number');
      return false;
    }
    if (mobileController.text.length < 10) {
      _showError('Please enter a valid mobile number');
      return false;
    }
    if (passwordController.text.trim().isEmpty) {
      _showError('Please enter your password');
      return false;
    }
    if (passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }
    if (confirmPasswordController.text.trim().isEmpty) {
      _showError('Please confirm your password');
      return false;
    }
    if (passwordController.text != confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }
    if (!acceptedTerms) {
      _showError('Please accept the Terms & Conditions and Privacy Policy');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _signup() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      
      await authNotifier.signUpWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        displayName: nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Let\'s complete your profile.'),
            backgroundColor: Colors.green,
          ),
        );
        // Wait a moment for the user to see the success message
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          // Redirect to edit profile for first-time setup
          context.pushReplacement('/edit-profile?firstTime=true');
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Signup failed';
        
        // Handle specific error cases
        if (e.toString().contains('network') || 
            e.toString().contains('connection') ||
            e.toString().contains('host') ||
            e.toString().contains('unavailable')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'An account with this email already exists.';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Password is too weak. Please choose a stronger password.';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Invalid email address.';
        } else {
          errorMessage = 'Signup failed: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
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
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: Column(
              children: [
                const SizedBox(height: 18),
                _topIcon(),
                const SizedBox(height: 18),
                const Text(
                  'Join PictoGram',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create your account',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                    AuthGlassCard(
                      child: Column(
                        children: [
                          AuthTextField(
                            controller: nameController,
                            hintText: 'Name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12), // Reduced from 16
                          AuthTextField(
                            controller: emailController,
                            hintText: 'Email ID',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12), // Reduced from 16
                          AuthTextField(
                            controller: mobileController,
                            hintText: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12), // Reduced from 16
                          AuthTextField(
                            controller: passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
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
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AuthTextField(
                            controller: confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            obscureText: obscureConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    acceptedTerms = !acceptedTerms;
                                  });
                                },
                                child: Icon(
                                  acceptedTerms
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  color: acceptedTerms ? _pink : Colors.white54,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                    children: const [
                                      TextSpan(text: 'I accept the '),
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20), // Reduced from 26
                          AuthButton(
                            text: 'Sign Up',
                            onPressed: _signup,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    AuthGlassCard(
                      child: Column(
                        children: [
                          const Text(
                            'Or sign up with',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
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

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.white60, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/login'),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_pink, _coral],
        ),
        boxShadow: [
          BoxShadow(
            color: _pink.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.white,
        size: 32,
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

class _GoogleLetterG extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
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
    );
  }
}

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
