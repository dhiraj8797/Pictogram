import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/constants/app_constants.dart';

// Singleton controllers to prevent recreation
class LoginControllers {
  static final LoginControllers _instance = LoginControllers._internal();
  factory LoginControllers() => _instance;
  LoginControllers._internal();
  
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  
  void clear() {
    email.clear();
    phone.clear();
    password.clear();
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Use singleton controllers
  final LoginControllers _controllers = LoginControllers();
  
  // State
  bool _obscurePassword = true;
  bool _useEmailLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('DEBUG: LoginScreen initState - Email: "${_controllers.email.text}", Phone: "${_controllers.phone.text}", Password: "${_controllers.password.text}"');
  }

  @override
  void dispose() {
    print('DEBUG: LoginScreen dispose - Email: "${_controllers.email.text}", Phone: "${_controllers.phone.text}", Password: "${_controllers.password.text}"');
    // Don't dispose singleton controllers
    super.dispose();
  }

  // Manual validation
  bool _validateInputs() {
    final email = _controllers.email.text.trim();
    final phone = _controllers.phone.text.trim();
    final password = _controllers.password.text.trim();

    if (_useEmailLogin) {
      if (email.isEmpty) {
        _setError('Please enter your email');
        return false;
      }
      if (!RegExp(r'^[\w\-.]+@[\w-]+\.[\w-]{2,4}$').hasMatch(email)) {
        _setError('Please enter a valid email');
        return false;
      }
      if (password.isEmpty) {
        _setError('Please enter your password');
        return false;
      }
      if (password.length < 6) {
        _setError('Password must be at least 6 characters');
        return false;
      }
    } else {
      if (phone.isEmpty) {
        _setError('Please enter your phone number');
        return false;
      }
      if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
        _setError('Please enter a valid 10-digit phone number');
        return false;
      }
    }

    return true;
  }

  void _setError(String error) {
    setState(() {
      _errorMessage = error;
    });
    
    // Clear error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    print('DEBUG: _handleLogin called - Email: "${_controllers.email.text}", Phone: "${_controllers.phone.text}", Password: "${_controllers.password.text}"');
    print('DEBUG: _useEmailLogin: $_useEmailLogin, _isLoading: $_isLoading');
    
    if (_isLoading) return;

    if (!_validateInputs()) {
      print('DEBUG: Validation failed');
      return;
    }

    print('DEBUG: Validation passed, setting loading state');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      
      if (_useEmailLogin) {
        print('DEBUG: Attempting email login...');
        await authNotifier.signInWithEmail(
          email: _controllers.email.text.trim(),
          password: _controllers.password.text.trim(),
        );
        print('DEBUG: Email login completed');
      } else {
        print('DEBUG: Navigating to OTP for phone login...');
        context.push('/otp-verify', extra: {
          'phoneNumber': _controllers.phone.text.trim(),
          'isSignup': false,
        });
      }
    } catch (e) {
      print('DEBUG: Login error: $e');
      _setError('Login failed: ${e.toString()}');
    } finally {
      if (mounted) {
        print('DEBUG: Setting loading to false');
        setState(() {
          _isLoading = false;
        });
        print('DEBUG: Final state - Email: "${_controllers.email.text}", Password: "${_controllers.password.text}"');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: build() called - Email: "${_controllers.email.text}", Phone: "${_controllers.phone.text}", Password: "${_controllers.password.text}"');
    final authState = ref.watch(authNotifierProvider);

    // Navigate to home if already authenticated
    ref.listen(currentUserProvider, (previous, next) {
      print('DEBUG: currentUserProvider changed - ${next.value?.uid}');
      if (next.value != null) {
        context.go('/home');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0010),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Title
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Email/Phone toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useEmailLogin = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _useEmailLogin ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _useEmailLogin ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            fontWeight: _useEmailLogin ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useEmailLogin = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_useEmailLogin ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Phone',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_useEmailLogin ? Colors.white : Colors.white.withValues(alpha: 0.5),
                            fontWeight: !_useEmailLogin ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Email/Phone field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _useEmailLogin ? _controllers.email : _controllers.phone,
                  keyboardType: _useEmailLogin ? TextInputType.emailAddress : TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    labelText: _useEmailLogin ? 'Email' : 'Phone Number',
                    hintText: _useEmailLogin ? 'Enter your email' : 'Enter your phone number',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                    prefixIcon: Icon(
                      _useEmailLogin ? Icons.email_outlined : Icons.phone_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password field (only for email login)
              if (_useEmailLogin) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: TextField(
                    controller: _controllers.password,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: forgot password screen
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade400, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Auth state error
              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.error!,
                          style: TextStyle(color: Colors.red.shade400, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Login button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading || authState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE0389A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading || authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                  TextButton(
                    onPressed: () => context.go('/signup'),
                    child: const Text('Sign up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
