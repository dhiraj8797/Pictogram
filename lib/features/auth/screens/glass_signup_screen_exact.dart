import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import 'glass_login_screen_exact.dart';

class GlassSignupScreen extends ConsumerStatefulWidget {
  const GlassSignupScreen({super.key});

  @override
  ConsumerState<GlassSignupScreen> createState() => _GlassSignupScreenState();
}

class _GlassSignupScreenState extends ConsumerState<GlassSignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool acceptedTerms = true;
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

  Future<void> _signup() async {
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions and Privacy Policy'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      
      await authNotifier.signUpWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text,
        displayName: nameController.text.trim(),
      );

      if (mounted) {
        context.pushReplacement('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: $e'),
            backgroundColor: Colors.red,
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9B5CFF),
              Color(0xFF611CFF),
              Color(0xFF2A005F),
            ],
          ),
        ),
        child: Stack(
          children: [
            _bgCircle(
              top: -70,
              left: -90,
              size: 260,
              color: Colors.white.withOpacity(0.14),
            ),
            _bgCircle(
              top: 320,
              right: -110,
              size: 220,
              color: Colors.white.withOpacity(0.10),
            ),
            _bgCircle(
              bottom: 120,
              left: -70,
              size: 170,
              color: Colors.white.withOpacity(0.08),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    _topIcon(),
                    const SizedBox(height: 18),
                    const Text(
                      'Join PictoGram',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your account',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _glassContainer(
                      child: Column(
                        children: [
                          _inputField(
                            controller: nameController,
                            hintText: 'Name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: emailController,
                            hintText: 'Email ID',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: mobileController,
                            hintText: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            obscureText: obscurePassword,
                            suffix: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            controller: confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_outline,
                            obscureText: obscureConfirmPassword,
                            suffix: IconButton(
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
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
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
                                  color: Colors.white.withOpacity(0.9),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.78),
                                      fontSize: 15,
                                      height: 1.5,
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
                          const SizedBox(height: 26),
                          _signupButton(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _glassContainer(
                      child: Column(
                        children: [
                          Text(
                            'Or sign up with',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _socialButton(
                            text: 'Continue with Google',
                            backgroundColor: const Color(0xFF4285F4),
                            textColor: Colors.white,
                            leading: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _socialButton(
                            text: 'Continue with X',
                            backgroundColor: Colors.white,
                            textColor: Colors.black,
                            leading: const Text(
                              'X',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 26),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.72),
                            fontSize: 17,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            context.push('/glass-login-exact');
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
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
          ],
        ),
      ),
    );
  }

  Widget _topIcon() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.30),
            Colors.white.withOpacity(0.12),
          ],
        ),
      ),
      child: const Icon(
        Icons.camera_alt_outlined,
        color: Colors.white,
        size: 42,
      ),
    );
  }

  Widget _glassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            color: Colors.white.withOpacity(0.10),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Container(
      height: 104,
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withOpacity(0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.black54, size: 34),
                const SizedBox(width: 18),
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hintText,
                      hintStyle: const TextStyle(
                        color: Colors.black54,
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                if (suffix != null) suffix,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _signupButton() {
    return SizedBox(
      width: double.infinity,
      height: 104,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signup,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFBBA6F7),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _socialButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Widget leading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 94,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement social signup
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$text will be implemented soon'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgCircle({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
