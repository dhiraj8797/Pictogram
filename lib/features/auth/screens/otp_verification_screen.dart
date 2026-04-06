import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_glass_card.dart';
import '../widgets/auth_button.dart';

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final String? username;
  final String? displayName;
  final bool isSignup;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.username,
    this.displayName,
    this.isSignup = false,
  });

  @override
  ConsumerState<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends ConsumerState<OTPVerificationScreen> {
  final List<TextEditingController> _ctrl = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();

  bool _isVerifying = false;
  bool _canResend = false;
  int _resendTimer = 60;
  Timer? _timer;
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _ctrl) c.dispose();
    for (final f in _focus) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        setState(() => _canResend = true);
        t.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    for (final c in _ctrl) c.clear();
    _focus[0].requestFocus();
    _startResendTimer();

    await _authService.sendPhoneOTP(
      phoneNumber: widget.phoneNumber,
      onCodeSent: (id) {
        if (!mounted) return;
        setState(() => _verificationId = id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent'), backgroundColor: Colors.green),
        );
      },
      onError: (e) {
        if (mounted) _showError(e);
      },
    );
  }

  Future<void> _verifyOTP() async {
    FocusScope.of(context).unfocus();
    final otp = _ctrl.map((c) => c.text.trim()).join();
    if (otp.length != 6) {
      _showError('Enter all 6 digits');
      return;
    }

    setState(() => _isVerifying = true);

    final result = await _authService.signInWithPhoneOTP(
      verificationId: _verificationId,
      smsCode: otp,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result.success) {
      context.go('/home');
    } else {
      // New user — no Firestore doc yet → go to profile setup
      final err = result.error ?? '';
      if (err.contains('not found') || err.contains('User not found')) {
        context.go('/setup-profile');
      } else {
        _showError(err.isNotEmpty ? err : 'Verification failed');
      }
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    if (_ctrl.every((c) => c.text.isNotEmpty)) {
      _verifyOTP();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verify your\nnumber',
                  style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to\n${widget.phoneNumber}',
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 36),
                AuthGlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // 6-digit boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (i) {
                          return SizedBox(
                            width: 44,
                            height: 54,
                            child: TextField(
                              controller: _ctrl[i],
                              focusNode: _focus[i],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              onChanged: (v) => _onDigitChanged(v, i),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),
                      AuthButton(
                        text: 'Verify OTP',
                        isLoading: _isVerifying,
                        onPressed: _verifyOTP,
                      ),
                      const SizedBox(height: 20),
                      // Resend row
                      Center(
                        child: _canResend
                            ? GestureDetector(
                                onTap: _resendOTP,
                                child: const Text(
                                  'Resend OTP',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Resend in ${_resendTimer}s',
                                style: const TextStyle(color: Colors.white54, fontSize: 14),
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
