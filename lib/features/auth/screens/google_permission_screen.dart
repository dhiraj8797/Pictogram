import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_provider.dart';

// ── Trendily color tokens ─────────────────────────────────────────────────────
const Color _bgDark    = Color.fromRGBO(16,  7,  18, 1.0);
const Color _bgMid     = Color.fromRGBO(23,  8,  19, 1.0);
const Color _bgTop     = Color.fromRGBO(37,  4,  20, 1.0);
const Color _pink      = Color.fromRGBO(255, 61,  135, 1.0);
const Color _coral     = Color.fromRGBO(255, 106,  92, 1.0);
const Color _pinkGlow  = Color.fromRGBO(255, 61,  135, 0.18);
const Color _cardTop   = Color.fromRGBO(255, 255, 255, 0.08);
const Color _cardBot   = Color.fromRGBO(255, 255, 255, 0.03);
const Color _border    = Color.fromRGBO(255, 255, 255, 0.10);

class GooglePermissionScreen extends ConsumerStatefulWidget {
  final String uid;
  final String email;
  final String displayName;
  final String? profileImage;

  const GooglePermissionScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.displayName,
    this.profileImage,
  });

  @override
  ConsumerState<GooglePermissionScreen> createState() =>
      _GooglePermissionScreenState();
}

class _GooglePermissionScreenState
    extends ConsumerState<GooglePermissionScreen> {
  bool _isLoading = false;

  Future<void> _onContinue() async {
    setState(() => _isLoading = true);
    try {
      final newUser = AppUser(
        uid: widget.uid,
        email: widget.email,
        displayName: widget.displayName,
        profileImage: widget.profileImage,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set(newUser.toFirestore());
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create account: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCancel() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ───────────────────────────────────────────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgMid, _bgDark],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.8),
                radius: 1.2,
                colors: [_pinkGlow, Colors.transparent],
                stops: [0.0, 0.5],
              ),
            ),
          ),
          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top bar: "Sign in with Google" ────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Coloured Google G
                      _GoogleGIcon(),
                      const SizedBox(width: 10),
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _border, height: 1),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── App logo + "Sign in to PictoGram" ─────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_pink, _coral],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _pink.withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sign in to PictoGram',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'pictogram.online',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Google account pill ────────────────────────────
                        _glassRow(
                          child: Row(
                            children: [
                              _avatar(size: 32),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.white54, size: 20),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Permissions section ────────────────────────────
                        const Text(
                          'Google will allow PictoGram to access this info about you',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _glassRow(
                          child: _permissionItem(
                            icon: Icons.person_outline_rounded,
                            title: widget.displayName.isNotEmpty
                                ? widget.displayName
                                : 'Your Name',
                            subtitle: 'Name and profile picture',
                            leading: _avatar(size: 36),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _glassRow(
                          child: _permissionItem(
                            icon: Icons.mail_outline_rounded,
                            title: widget.email,
                            subtitle: 'Email address',
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Legal copy ────────────────────────────────────
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                                height: 1.6),
                            children: [
                              const TextSpan(
                                  text:
                                      'Review PictoGram\'s '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    color:
                                        _pink.withValues(alpha: 0.9)),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                    color:
                                        _pink.withValues(alpha: 0.9)),
                              ),
                              const TextSpan(
                                  text:
                                      ' to understand how PictoGram will process and protect your data.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom divider + buttons ──────────────────────────────
                const Divider(color: _border, height: 1),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _onCancel,
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _cardTop,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: _border),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _onContinue,
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isLoading
                                    ? [
                                        _pink.withValues(alpha: 0.5),
                                        _coral.withValues(alpha: 0.5)
                                      ]
                                    : const [_pink, _coral],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: _isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: _pink.withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'Continue',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _avatar({required double size}) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _cardTop,
      backgroundImage:
          (widget.profileImage != null && widget.profileImage!.isNotEmpty)
              ? NetworkImage(widget.profileImage!)
              : null,
      child: (widget.profileImage == null || widget.profileImage!.isEmpty)
          ? Icon(Icons.person_outline,
              size: size * 0.55, color: Colors.white54)
          : null,
    );
  }

  Widget _glassRow({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_cardTop, _cardBot],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border, width: 0.8),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _permissionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? leading,
  }) {
    return Row(
      children: [
        leading ??
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _pink, size: 18),
            ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Google G multicolour icon ─────────────────────────────────────────────────
class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4285F4),
        ),
      ),
    );
  }
}
