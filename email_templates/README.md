# Pictogram Email Templates

Production-ready HTML email templates for Pictogram with the dark glassy UI aesthetic matching the app design.

## Templates Included

| Template | File | Description | Variables |
|----------|------|-------------|-----------|
| **Welcome** | `welcome_email.html` | New user onboarding | `{{userName}}`, `{{appUrl}}` |
| **OTP Verification** | `otp_verification.html` | Phone/email verification code | `{{userName}}`, `{{otpCode}}` |
| **Password Reset** | `password_reset.html` | Forgot password flow | `{{userName}}`, `{{resetLink}}` |
| **Account Suspended** | `account_suspended.html` | Violation notification | `{{userName}}`, `{{suspensionReason}}`, `{{appealUrl}}` |
| **New Follower** | `new_follower.html` | Social engagement | `{{followerName}}`, `{{followerAvatar}}`, `{{profileUrl}}` |
| **Content Reported** | `content_reported.html` | Moderation alert | `{{contentType}}`, `{{reportReason}}`, `{{contentPreview}}` |
| **Login Alert** | `login_alert.html` | Security notification | `{{userName}}`, `{{loginTime}}`, `{{deviceName}}`, `{{location}}`, `{{resetLink}}` |
| **Support Acknowledgement** | `support_acknowledgement.html` | Ticket confirmation | `{{userName}}`, `{{ticketId}}`, `{{ticketSubject}}` |

## Support Contact

All templates include:
- **Support Email**: `support@pictogram.online`
- **Dark Theme**: Matches app aesthetic (#0b0b14 background, purple gradients)
- **Responsive**: Works on all devices
- **Inline CSS**: Compatible with all email clients

## Usage

Replace placeholders before sending via your backend (Firebase Functions, Node.js, etc.):

```javascript
const welcomeHtml = fs.readFileSync('email_templates/welcome_email.html', 'utf8')
  .replace('{{userName}}', user.displayName)
  .replace('{{appUrl}}', 'https://pictogram.app');
```

## Design System

- **Background**: `#0b0b14` (dark)
- **Primary Gradient**: `#7c3aed` to `#a855f7` to `#ec4899`
- **Card Background**: `#151528` to `#0f1020`
- **Border**: `#2d2f55`
- **Text Primary**: `#ffffff`
- **Text Secondary**: `#cbd5e1`
- **Accent**: `#c4b5fd` (links)

---
© 2026 Pictogram. All rights reserved.
