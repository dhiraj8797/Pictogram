import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_glass_card.dart';
import '../widgets/auth_button.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  String _countryCode = '+91';
  bool _isSending = false;

  static const _countryCodes = [
    ('+91', '🇮🇳 IN'),
    ('+1',  '🇺🇸 US'),
    ('+44', '🇬🇧 UK'),
    ('+61', '🇦🇺 AU'),
    ('+971','🇦🇪 AE'),
    ('+92', '🇵🇰 PK'),
    ('+880','🇧🇩 BD'),
    ('+65', '🇸🇬 SG'),
    ('+60', '🇲🇾 MY'),
    ('+66', '🇹🇭 TH'),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    FocusScope.of(context).unfocus();
    final number = _phoneController.text.trim();
    if (number.isEmpty || number.length < 6) {
      _showError('Enter a valid phone number');
      return;
    }

    setState(() => _isSending = true);

    final full = '$_countryCode$number';

    await _authService.sendPhoneOTP(
      phoneNumber: full,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _isSending = false);
        context.push('/otp-verify', extra: {
          'phoneNumber': full,
          'verificationId': verificationId,
          'isSignup': false,
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isSending = false);
        _showError(error);
      },
      onAutoVerified: (credential) async {
        if (!mounted) return;
        final result = await _authService.signInWithPhoneOTP(
          verificationId: credential.verificationId ?? '',
          smsCode: credential.smsCode ?? '',
        );
        if (!mounted) return;
        setState(() => _isSending = false);
        if (result.success) {
          context.go('/home');
        } else {
          _showError(result.error ?? 'Auto verification failed');
        }
      },
    );
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
                  'Enter your\nmobile number',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We'll send a one-time verification code",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 36),
                AuthGlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Country code dropdown
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _countryCode,
                                dropdownColor: const Color(0xFF3A1A80),
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                icon: const Icon(Icons.expand_more, color: Colors.white70, size: 18),
                                items: _countryCodes.map((item) {
                                  return DropdownMenuItem(
                                    value: item.$1,
                                    child: Text('${item.$2}  ${item.$1}',
                                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _countryCode = v!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: 'Phone number',
                                hintStyle: const TextStyle(color: Colors.white38),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.white54),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.10),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AuthButton(
                        text: 'Send OTP',
                        isLoading: _isSending,
                        onPressed: _sendOTP,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'By continuing you agree to receive an SMS.\nStandard rates may apply.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
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
