import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/glass_widgets.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                        'Terms & Conditions',
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
                        'Welcome to PictoGram. These Terms and Conditions ("Terms") govern your use of the PictoGram mobile application and services. By creating an account or using PictoGram, you agree to be bound by these Terms. Please read them carefully.',
                      ),

                      _buildSection(
                        '1. Acceptance of Terms',
                        'By downloading, installing, accessing, or using PictoGram, you confirm that you are at least 13 years old, have read and understood these Terms, and agree to be legally bound by them. If you do not agree, do not use PictoGram.',
                      ),

                      _buildSection(
                        '2. User Accounts',
                        '• You may register using your email address or mobile phone number (via OTP verification).\n\n'
                        '• You must provide accurate and complete information during registration.\n\n'
                        '• You are solely responsible for maintaining the confidentiality of your login credentials and for all activity that occurs under your account.\n\n'
                        '• You must notify us immediately at support@pictogram.app if you suspect any unauthorised use of your account.\n\n'
                        '• One person may not maintain more than one account. Creating multiple accounts to evade bans or restrictions is prohibited.',
                      ),

                      _buildSection(
                        '3. Eligibility',
                        '• You must be at least 13 years old to use PictoGram.\n\n'
                        '• Users between 13–18 years old must have parental or guardian consent.\n\n'
                        '• By using PictoGram, you represent that you meet these age requirements.',
                      ),

                      _buildSection(
                        '4. Content You Post',
                        '• You retain ownership of all photos, videos, stories, captions, and other content ("Content") you post on PictoGram.\n\n'
                        '• By posting Content, you grant PictoGram a non-exclusive, royalty-free, worldwide licence to display, store, and distribute your Content solely for the purpose of operating and improving the platform.\n\n'
                        '• You are solely responsible for the Content you post and must ensure it does not violate any laws or third-party rights.\n\n'
                        '• We may remove any Content that violates these Terms without prior notice.',
                      ),

                      _buildSection(
                        '5. Prohibited Activities',
                        'You agree NOT to:\n\n'
                        '• Post content that is illegal, harmful, abusive, threatening, defamatory, obscene, or sexually explicit.\n\n'
                        '• Harass, bully, stalk, or intimidate other users.\n\n'
                        '• Post content that infringes the intellectual property or privacy rights of others.\n\n'
                        '• Use PictoGram to spread misinformation, fake news, or misleading content.\n\n'
                        '• Impersonate any person, entity, or organisation.\n\n'
                        '• Use automated bots, scripts, or tools to scrape data or interact with the platform.\n\n'
                        '• Attempt to hack, reverse-engineer, or disrupt PictoGram\'s systems or servers.\n\n'
                        '• Post spam, phishing links, or malware.\n\n'
                        '• Sell, trade, or transfer your account to another person.',
                      ),

                      _buildSection(
                        '6. Phone Number & OTP',
                        'When you choose to sign up or log in with your mobile number, you consent to receiving an OTP via SMS. Standard messaging rates from your carrier may apply. You must enter a phone number that you own and are authorised to use. We are not responsible for delays in OTP delivery caused by network issues.',
                      ),

                      _buildSection(
                        '7. Privacy',
                        'Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information, including your phone number, photos, and usage data. By using PictoGram, you agree to our Privacy Policy.',
                      ),

                      _buildSection(
                        '8. Intellectual Property',
                        '• PictoGram, its logo, name, and all associated trademarks are the exclusive property of PictoGram.\n\n'
                        '• The app\'s code, design, graphics, and features are protected by copyright and intellectual property laws.\n\n'
                        '• You may not copy, modify, distribute, or create derivative works of any part of PictoGram without our written permission.',
                      ),

                      _buildSection(
                        '9. Account Suspension & Termination',
                        '• We reserve the right to suspend or permanently terminate your account if you violate these Terms or engage in harmful behaviour.\n\n'
                        '• You may delete your account at any time from the Settings screen.\n\n'
                        '• Upon termination, your content will be removed from the platform within 30 days, except where retention is required by law.',
                      ),

                      _buildSection(
                        '10. Disclaimers & Limitation of Liability',
                        '• PictoGram is provided "as is" and "as available" without warranties of any kind, express or implied.\n\n'
                        '• We do not guarantee uninterrupted, error-free, or secure access to the platform.\n\n'
                        '• To the maximum extent permitted by law, PictoGram shall not be liable for any indirect, incidental, or consequential damages arising from your use of the service.\n\n'
                        '• We are not responsible for user-generated content posted by others.',
                      ),

                      _buildSection(
                        '11. Third-Party Services',
                        'PictoGram integrates with third-party services such as Google Firebase. These services have their own terms and privacy policies. We are not responsible for the practices of these third parties. By using PictoGram, you also agree to Google\'s Terms of Service.',
                      ),

                      _buildSection(
                        '12. Governing Law',
                        'These Terms are governed by the laws of India. Any disputes arising from these Terms or your use of PictoGram shall be subject to the exclusive jurisdiction of the courts located in India.',
                      ),

                      _buildSection(
                        '13. Changes to Terms',
                        'We may update these Terms from time to time to reflect changes in our services or applicable law. We will notify you of significant changes via in-app notification. Your continued use of PictoGram after changes take effect constitutes your acceptance of the new Terms.',
                      ),

                      _buildSection(
                        '14. Contact Us',
                        'If you have questions, concerns, or complaints about these Terms:\n\n'
                        'Email: info@pictogram.online\n'
                        'Support: support@pictogram.online\n'
                        'Phone: +91 7022918586\n\n'
                        'We will respond within 30 working days.',
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
