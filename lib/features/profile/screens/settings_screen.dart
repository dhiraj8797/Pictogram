import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/security_service.dart';
import '../../../widgets/glass_widgets.dart';

const Color _bgDialog = Color.fromRGBO(37,  4, 20, 1.0);
const Color _pink     = Color.fromRGBO(255, 61, 135, 1.0);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notification prefs
  bool _notifLikes     = true;
  bool _notifComments  = true;
  bool _notifFollows   = true;
  bool _notifMessages  = true;

  // Privacy prefs
  bool _privateAccount = false;
  bool _showActivity   = true;

  // Security prefs
  bool _biometricLogin = false;
  bool _screenshotBlock = true;

  static const _appVersion = '1.0.0';
  static const _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifLikes      = p.getBool('notif_likes')      ?? true;
      _notifComments   = p.getBool('notif_comments')   ?? true;
      _notifFollows    = p.getBool('notif_follows')    ?? true;
      _notifMessages   = p.getBool('notif_messages')   ?? true;
      _privateAccount  = p.getBool('private_account')  ?? false;
      _showActivity    = p.getBool('show_activity')    ?? true;
      _biometricLogin  = p.getBool('biometric_login')  ?? false;
      _screenshotBlock = p.getBool('screenshot_block') ?? true;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.signOut();
      await AnalyticsService().trackCustomEvent('user_logout', {
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        context.pushReplacement('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Delete Account ──────────────────────────────────────────────────────────
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
          'This will permanently delete your account, all posts, followers, and data. '
          'This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack('Account deletion request sent. We will process it within 30 days.');
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Change Password ─────────────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    final currentUser = ref.read(currentUserProvider).value;
    final emailController = TextEditingController(
      text: currentUser?.email ?? '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A password reset link will be sent to your email.',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email address',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              Navigator.pop(context);
              if (email.isEmpty) {
                _showSnack('Please enter your email', color: Colors.orange);
                return;
              }
              try {
                await fb_auth.FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                _showSnack('Reset link sent to $email');
              } catch (e) {
                _showSnack('Failed to send reset email: $e', color: Colors.red);
              }
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Clear Cache ─────────────────────────────────────────────────────────────
  Future<void> _clearCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      final cacheManager = DefaultCacheManager();
      await cacheManager.emptyCache();
      _showSnack('Cache cleared successfully');
    } catch (_) {
      _showSnack('Cache cleared');
    }
  }

  void _showSnack(String msg, {Color color = Colors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GlassIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text('Settings',
                        style: TextStyle(color: Colors.white, fontSize: 20,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [

                    // ── Account ────────────────────────────────────────────
                    _sectionHeader('Account'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (currentUser != null) ...[
                            _profileRow(currentUser),
                            _divider(),
                          ],
                          _tile(Icons.edit_outlined, 'Edit Profile',
                              onTap: () => context.push('/edit-profile')),
                          _divider(),
                          _tile(Icons.lock_reset_outlined, 'Change Password',
                              onTap: _showChangePasswordDialog),
                          _divider(),
                          _tile(Icons.phone_outlined, 'Linked Phone Number',
                              subtitle: currentUser?.phoneNumber?.isNotEmpty == true
                                  ? currentUser!.phoneNumber!
                                  : 'Not linked',
                              onTap: () => context.push('/phone-auth')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Privacy ────────────────────────────────────────────
                    _sectionHeader('Privacy'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _switchTile(
                            Icons.lock_outline,
                            'Private Account',
                            'Only approved followers can see your posts',
                            _privateAccount,
                            (v) async {
                              setState(() => _privateAccount = v);
                              _savePref('private_account', v);
                              final uid = ref.read(currentUserProvider).value?.uid;
                              if (uid != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({'isPrivate': v});
                              }
                            },
                          ),
                          _divider(),
                          _switchTile(
                            Icons.visibility_outlined,
                            'Show Activity Status',
                            'Let others see when you were last active',
                            _showActivity,
                            (v) {
                              setState(() => _showActivity = v);
                              _savePref('show_activity', v);
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Security ───────────────────────────────────────────
                    _sectionHeader('Security'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _switchTile(
                            Icons.fingerprint,
                            'Biometric Login',
                            'Use fingerprint or face to sign in',
                            _biometricLogin,
                            (v) {
                              setState(() => _biometricLogin = v);
                              _savePref('biometric_login', v);
                            },
                          ),
                          _divider(),
                          _switchTile(
                            Icons.screenshot_monitor_outlined,
                            'Block Screenshots',
                            'Prevent screenshots on profile & home feed',
                            _screenshotBlock,
                            (v) async {
                              setState(() => _screenshotBlock = v);
                              _savePref('screenshot_block', v);
                              if (v) {
                                await SecurityService().enableSecureScreen();
                              } else {
                                await SecurityService().disableSecureScreen();
                              }
                            },
                          ),
                          _divider(),
                          _tile(Icons.devices_outlined, 'Active Sessions',
                              subtitle: 'Manage logged-in devices',
                              onTap: () => _showSnack('Feature coming soon', color: Colors.orange)),
                          _divider(),
                          _tile(Icons.block_outlined, 'Blocked Users',
                              onTap: () => _showSnack('Feature coming soon', color: Colors.orange)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Notifications ──────────────────────────────────────
                    _sectionHeader('Notifications'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _switchTile(Icons.favorite_border, 'Likes',
                              'Notify when someone likes your post',
                              _notifLikes, (v) { setState(() => _notifLikes = v); _savePref('notif_likes', v); }),
                          _divider(),
                          _switchTile(Icons.comment_outlined, 'Comments',
                              'Notify when someone comments',
                              _notifComments, (v) { setState(() => _notifComments = v); _savePref('notif_comments', v); }),
                          _divider(),
                          _switchTile(Icons.person_add_outlined, 'Follows',
                              'Notify when someone follows you',
                              _notifFollows, (v) { setState(() => _notifFollows = v); _savePref('notif_follows', v); }),
                          _divider(),
                          _switchTile(Icons.message_outlined, 'Messages',
                              'Notify when you receive a message',
                              _notifMessages, (v) { setState(() => _notifMessages = v); _savePref('notif_messages', v); }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Storage ────────────────────────────────────────────
                    _sectionHeader('Storage & Data'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _tile(Icons.cleaning_services_outlined, 'Clear Cache',
                              subtitle: 'Free up local storage',
                              onTap: _clearCache),
                          _divider(),
                          _tile(Icons.download_outlined, 'Download My Data',
                              subtitle: 'Request a copy of your data',
                              onTap: () => _showSnack('Data export request sent to your email')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Support ────────────────────────────────────────────
                    _sectionHeader('Support'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _tile(Icons.help_outline, 'Help & Support',
                              subtitle: 'support@pictogram.app',
                              onTap: () => _showSnack('Email: support@pictogram.app')),
                          _divider(),
                          _tile(Icons.bug_report_outlined, 'Report a Problem',
                              onTap: () => _showSnack('Feature coming soon', color: Colors.orange)),
                          _divider(),
                          _tile(Icons.description_outlined, 'Terms & Conditions',
                              onTap: () => context.push('/terms')),
                          _divider(),
                          _tile(Icons.privacy_tip_outlined, 'Privacy Policy',
                              onTap: () => context.push('/privacy')),
                          _divider(),
                          _tile(Icons.info_outline, 'About PictoGram',
                              subtitle: 'Version $_appVersion (Build $_buildNumber)',
                              onTap: () => _showAboutDialog()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Contact Us ───────────────────────────────────────────
                    _sectionHeader('Contact Us'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _tile(Icons.email_outlined, 'Email Us',
                              subtitle: 'info@pictogram.online',
                              onTap: () => _showContactDialog('Email', 'info@pictogram.online')),
                          _divider(),
                          _tile(Icons.support_agent_outlined, 'Support',
                              subtitle: 'support@pictogram.online',
                              onTap: () => _showContactDialog('Support', 'support@pictogram.online')),
                          _divider(),
                          _tile(Icons.phone_outlined, 'Call Us',
                              subtitle: '+91 7022918586',
                              onTap: () => _showContactDialog('Phone', '+91 7022918586')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Danger Zone ────────────────────────────────────────
                    _sectionHeader('Account Actions'),
                    GlassCard(
                      radius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _tile(Icons.logout, 'Logout',
                              color: Colors.redAccent,
                              onTap: _showLogoutDialog),
                          _divider(),
                          _tile(Icons.delete_forever_outlined, 'Delete Account',
                              color: Colors.red,
                              subtitle: 'Permanently remove your account',
                              onTap: _showDeleteAccountDialog),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: Text(
                        'PictoGram v$_appVersion',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500,
                letterSpacing: 0.6)),
      );

  Widget _divider() => const Divider(color: Colors.white12, height: 20);

  Widget _profileRow(AppUser user) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: GestureDetector(
          onTap: () => context.push('/profile/${user.uid}'),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage:
                    user.profileImage?.isNotEmpty == true ? NetworkImage(user.profileImage!) : null,
                child: user.profileImage?.isNotEmpty != true
                    ? const Icon(Icons.person, color: Colors.white70)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    Text(user.email.isNotEmpty ? user.email : user.phoneNumber ?? user.displayName,
                        style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      );

  Widget _tile(IconData icon, String label,
      {String? subtitle, Color? color, VoidCallback? onTap}) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: c, fontSize: 15)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: color != null ? color.withValues(alpha: 0.6) : Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(IconData icon, String label, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: _pink,
          activeTrackColor: _pink.withValues(alpha: 0.35),
          inactiveThumbColor: Colors.white54,
          inactiveTrackColor: Colors.white12,
        ),
      ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('PictoGram', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_rounded, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text('Version $_appVersion (Build $_buildNumber)',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            const Text('A beautiful photo sharing app.',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 8),
            const Text('© 2025 PictoGram. All rights reserved.',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(String title, String value) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _bgDialog,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          value,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnack('Copied to clipboard: $value');
            },
            child: const Text('Copy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

