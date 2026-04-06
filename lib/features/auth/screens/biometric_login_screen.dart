import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/biometric_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../core/constants/app_constants.dart';

class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() => _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Initialize biometric capabilities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(biometricProvider.notifier).initialize();
    });

    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    final biometricNotifier = ref.read(biometricProvider.notifier);
    
    final success = await biometricNotifier.authenticate(
      reason: biometricNotifier.getAuthenticationPrompt(),
    );

    if (success) {
      // Biometric authentication successful
      if (mounted) {
        // Navigate to home screen
        context.go('/home');
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(biometricNotifier.state.errorMessage ?? 'Authentication failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _usePasswordInstead() {
    // Navigate to regular login screen
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final biometricState = ref.watch(biometricProvider);
    final currentUser = ref.watch(currentUserProvider);
    final user = currentUser.value;

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo and Title
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withOpacity(0.8),
                            Colors.blue.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PictoGram',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome back, ${user?.displayName ?? 'User'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Biometric Authentication Section
                GlassCard(
                  radius: 24,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Biometric Icon with Animation
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.8),
                                    Colors.purple.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getBiometricIcon(),
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Biometric Type Text
                      Text(
                        biometricState.biometricName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Authentication Prompt
                      Text(
                        biometricState.getAuthenticationPrompt(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Authenticate Button
                      if (biometricState.canUseBiometrics)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: GlassButton(
                            onPressed: biometricState.isLoading ? null : _authenticateWithBiometrics,
                            child: biometricState.isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Authenticating...'),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getBiometricIcon(),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Use ${biometricState.biometricName}'),
                                    ],
                                  ),
                          ),
                        ),

                      // Error Message
                      if (biometricState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    biometricState.errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Status Message
                      if (!biometricState.canUseBiometrics && biometricState.errorMessage == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info, color: Colors.orange, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    biometricState.statusMessage,
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Use Password Instead Button
                TextButton(
                  onPressed: _usePasswordInstead,
                  child: const Text(
                    'Use password instead',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    final biometricState = ref.read(biometricProvider);
    if (biometricState.hasFaceId) {
      return Icons.face;
    } else if (biometricState.hasFingerprint) {
      return Icons.fingerprint;
    } else {
      return Icons.lock;
    }
  }
}

// Glass Button Widget
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: onPressed != null
              ? [
                  Colors.blue.withOpacity(0.8),
                  Colors.purple.withOpacity(0.8),
                ]
              : [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: onPressed != null
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
