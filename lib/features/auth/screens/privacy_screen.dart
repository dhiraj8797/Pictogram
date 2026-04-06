import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/glass_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
                      const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Content
                GlassCard(
                  radius: 28,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntro(
                        'PictoGram ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, share, and safeguard your personal information when you use the PictoGram mobile application and related services.',
                      ),

                      _buildSection(
                        '1. Information We Collect',
                        '• Account Information: When you register, we collect your name, username, email address, and/or mobile phone number.\n\n'
                        '• Phone Number & OTP: If you sign up or log in via mobile number, we collect your phone number and verify it using a one-time password (OTP) delivered by SMS through Google Firebase Authentication.\n\n'
                        '• Profile Information: Profile photo, bio, date of birth, and account privacy settings you choose to provide.\n\n'
                        '• Content You Post: Photos, captions, stories, comments, likes, and direct messages you create or share.\n\n'
                        '• Device & Usage Data: Device model, operating system, IP address, app version, crash reports, and how you interact with features.\n\n'
                        '• Camera & Storage: When you upload photos or stories, we access your camera and media library only with your explicit permission.',
                      ),

                      _buildSection(
                        '2. How We Use Your Information',
                        '• To create and manage your account.\n\n'
                        '• To verify your identity via OTP and prevent unauthorised access.\n\n'
                        '• To display your posts, profile, and stories to other users according to your privacy settings.\n\n'
                        '• To send notifications about activity on your account (likes, comments, follows, messages).\n\n'
                        '• To detect, prevent, and address fraud, abuse, and security issues.\n\n'
                        '• To analyse app performance and improve features using anonymised analytics.\n\n'
                        '• To comply with legal obligations and enforce our Terms and Conditions.',
                      ),

                      _buildSection(
                        '3. Information Sharing',
                        '• With Other Users: Your username, profile picture, bio, and public posts are visible to other users. If your account is private, only approved followers can see your content.\n\n'
                        '• With Service Providers: We use Google Firebase (Authentication, Firestore, Storage, Analytics, Crashlytics) and Google Cloud Platform to operate our services. These providers process data on our behalf under strict data protection agreements.\n\n'
                        '• For Legal Compliance: We may disclose information if required by law, court order, or government authority.\n\n'
                        '• Business Transfers: In the event of a merger or acquisition, your data may be transferred. We will notify you of any such change.\n\n'
                        '• We do NOT sell your personal information to any third party.',
                      ),

                      _buildSection(
                        '4. Phone Number & SMS',
                        'Your phone number is used solely for account verification and login via OTP. We do not use your phone number for marketing SMS without your explicit consent. SMS delivery is handled by Google Firebase, and standard messaging rates from your carrier may apply.',
                      ),

                      _buildSection(
                        '5. Photos & Media',
                        'Photos and videos you upload are stored securely on Google Firebase Storage. Public posts are accessible to all users; private account posts are visible only to approved followers. You retain full ownership of all content you upload. We do not use your photos for advertising or AI training without explicit consent.',
                      ),

                      _buildSection(
                        '6. Data Security',
                        'We use industry-standard security measures including:\n\n'
                        '• End-to-end encrypted data transmission (HTTPS/TLS).\n\n'
                        '• Firebase Security Rules to restrict database and storage access.\n\n'
                        '• Google Firebase App Check to prevent unauthorised API access.\n\n'
                        '• Biometric authentication support (fingerprint/face) for secure login.\n\n'
                        'No method of electronic transmission or storage is 100% secure. We cannot guarantee absolute security, but we are committed to protecting your data.',
                      ),

                      _buildSection(
                        '7. Data Retention',
                        'We retain your personal data for as long as your account is active or as needed to provide services. You may delete your account at any time; upon deletion, your data will be permanently removed within 30 days, except where retention is required by law.',
                      ),

                      _buildSection(
                        '8. Your Rights',
                        '• Access: Request a copy of the personal data we hold about you.\n\n'
                        '• Correction: Update or correct inaccurate information through your profile settings.\n\n'
                        '• Deletion: Delete your account and all associated data permanently.\n\n'
                        '• Portability: Request your data in a portable format.\n\n'
                        '• Withdraw Consent: Revoke permissions (camera, notifications) at any time via your device settings.\n\n'
                        'To exercise any of these rights, contact us at privacy@pictogram.app',
                      ),

                      _buildSection(
                        '9. Third-Party Services',
                        'PictoGram is built on Google Firebase and uses the following Google services:\n\n'
                        '• Firebase Authentication — identity verification\n'
                        '• Cloud Firestore — user and content database\n'
                        '• Firebase Storage — photo and media storage\n'
                        '• Firebase Analytics — anonymous usage analytics\n'
                        '• Firebase Crashlytics — crash reporting\n'
                        '• Firebase App Check — API security\n\n'
                        'These services are governed by Google\'s Privacy Policy: policies.google.com/privacy',
                      ),

                      _buildSection(
                        '10. Children\'s Privacy',
                        'PictoGram is not intended for users under the age of 13. We do not knowingly collect personal information from children under 13. If we discover that a child under 13 has provided us with personal data, we will delete it immediately. Parents or guardians who believe their child has provided us data may contact us at privacy@pictogram.app',
                      ),

                      _buildSection(
                        '11. International Users',
                        'PictoGram is operated from India. If you access PictoGram from outside India, your data may be transferred to and processed in India or other countries where our service providers operate, subject to applicable data protection laws.',
                      ),

                      _buildSection(
                        '12. Changes to This Policy',
                        'We may update this Privacy Policy from time to time. We will notify you of significant changes through an in-app notification or email. Continued use of PictoGram after changes constitutes your acceptance of the updated policy.',
                      ),

                      _buildSection(
                        '13. Contact Us',
                        'For privacy-related questions, concerns, or requests:\n\n'
                        'Email: info@pictogram.online\n'
                        'Support: support@pictogram.online\n'
                        'Phone: +91 7022918586\n\n'
                        'We will respond to all requests within 30 days.',
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'Last updated: 3 April 2025',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
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

  Widget _buildIntro(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
