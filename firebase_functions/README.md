# Email System Setup Guide

Complete email infrastructure for Pictogram using Firebase Functions + SendGrid.

## 📁 Project Structure

```
firebase_functions/
├── src/
│   └── index.ts          # All email cloud functions
├── package.json          # Node dependencies
├── tsconfig.json         # TypeScript config
├── firebase.json         # Firebase config
└── .env                  # Environment variables (not in git)

lib/core/services/
└── email_service.dart    # Flutter email service

email_templates/
├── welcome_email.html
├── otp_verification.html
├── password_reset.html
├── account_suspended.html
├── new_follower.html
├── content_reported.html
├── login_alert.html
└── support_acknowledgement.html
```

## 🚀 Setup Instructions

### 1. Get SendGrid API Key

1. Sign up at [SendGrid](https://sendgrid.com)
2. Create a Single Sender (use `support@pictogram.online`)
3. Get API Key from Settings > API Keys
4. Verify domain (optional but recommended for production)

### 2. Deploy Firebase Functions

```bash
cd firebase_functions

# Install dependencies
npm install

# Login to Firebase
firebase login

# Set SendGrid API key
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"

# Deploy functions
firebase deploy --only functions
```

### 3. Add Flutter Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  cloud_functions: ^4.6.0
  firebase_core: ^2.27.0
```

### 4. Initialize in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Use emulator in development
  if (kDebugMode) {
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }
  
  runApp(PictogramApp());
}
```

## 📧 Email Functions Available

| Function | Trigger | Usage |
|----------|---------|-------|
| `sendWelcomeEmail` | Auto on signup | Sends welcome email automatically |
| `sendOtpEmail` | Callable | OTP verification codes |
| `sendPasswordResetEmail` | Callable | Password reset links |
| `sendLoginAlertEmail` | Callable | Security notifications |
| `sendNewFollowerEmail` | Callable | Social notifications |
| `sendContentReportedEmail` | Callable | Moderation alerts |
| `sendAccountSuspendedEmail` | Admin only | Account suspension notices |
| `sendSupportAcknowledgement` | Callable | Support ticket confirmation |

## 🎯 Usage Examples

### Send OTP
```dart
await emailService.sendOtpEmail(
  email: 'user@example.com',
  otpCode: '123456',
  userName: 'John',
);
```

### Send Login Alert (Security)
```dart
await emailService.sendLoginAlert(
  email: userEmail,
  loginTime: DateTime.now().toString(),
  deviceName: 'iPhone 15 Pro',
  location: 'Mumbai, India',
);
```

### Send Support Ticket Acknowledgement
```dart
await emailService.sendSupportAcknowledgement(
  email: userEmail,
  ticketId: '#TICK-12345',
  ticketSubject: 'Cannot upload photos',
);
```

## 🔒 Security Rules

Add to `firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Only admins can read email logs
    match /emailLogs/{doc} {
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
      allow write: if request.auth != null;
    }
  }
}
```

## 🧪 Local Testing

```bash
# Start Firebase emulators
firebase emulators:start

# In Flutter (main.dart)
FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
```

## 💰 Cost Estimates

| Tier | Emails/Month | Cost |
|------|---------------|------|
| SendGrid Free | 100/day (3,000/month) | $0 |
| SendGrid Essentials | 50,000/month | $19.95 |
| Firebase Functions | 2M invocations | Included in Spark plan |

## 📝 Monitoring

Check email logs in Firestore:
```
Collections > emailLogs
```

Or query:
```dart
FirebaseFirestore.instance
  .collection('emailLogs')
  .where('userId', isEqualTo: currentUserId)
  .orderBy('timestamp', descending: true)
  .get();
```

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| Emails not sending | Check SendGrid API key is set |
| Template not found | Ensure templates are in `email_templates/` folder |
| Functions timeout | Upgrade to Blaze plan (pay-as-you-go) |
| 403 errors | Check Firestore rules allow emailLogs writes |

---

**Ready to send emails!** 🚀
