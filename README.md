# PictoGram - Photo-First Social App

A Flutter-based mobile application where users can upload photos, like posts, comment (with Aadhaar verification), share posts, post Stories, view profiles, and see follower/following counts using alternate naming.

## Features

### Core Features
- **Photo Upload**: Upload only image files (JPG/PNG/WEBP, max 10MB)
- **Social Interactions**: Like, comment, share posts
- **Stories**: 24-hour expiring photo stories
- **Profile System**: View profiles with custom naming
- **Follow System**: "Supporters" (followers) and "Circles" (following)

### Unique Features
- **Aadhaar Verification**: Comment access restricted to verified users only
- **Alternate Naming**: Uses "Supporters" instead of "Followers" and "Circles" instead of "Following"
- **Photo-First**: Focus on visual content sharing

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Riverpod** - State management
- **GoRouter** - Navigation
- **Material Design 3** - UI components

### Backend
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - Image storage
- **Cloud Functions** - Server-side logic
- **Firebase App Check** - Security
- **Firebase Cloud Messaging** - Push notifications

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/
│   ├── router.dart             # Navigation configuration
│   └── theme.dart              # App theme
├── core/
│   ├── constants/              # App constants
│   ├── models/                 # Firestore models
│   ├── providers/              # Riverpod providers
│   ├── services/               # Firebase services
│   ├── utils/                  # Utility functions
│   └── widgets/                # Reusable widgets
└── features/
    ├── auth/                   # Authentication
    ├── home/                   # Home feed
    ├── upload/                 # Photo upload
    ├── stories/                # Stories feature
    ├── profile/                # User profiles
    ├── comments/               # Comments system
    ├── search/                 # Search functionality
    ├── notifications/          # Notifications
    └── verification/           # Aadhaar verification
```

## Setup Instructions

### Prerequisites
- Flutter SDK (>=3.11.0)
- Android Studio / VS Code with Flutter extensions
- Firebase account

### 1. Clone and Install Dependencies
```bash
git clone <repository-url>
cd pictogram
flutter pub get
```

### 2. Firebase Setup
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable the following services:
   - Authentication (Email/Password)
   - Cloud Firestore
   - Firebase Storage
   - App Check
   - Cloud Messaging

### 3. Configure Firebase
#### Android
1. Download `google-services.json` from Firebase Console
2. Replace the placeholder in `android/app/google-services.json`
3. Update the following in the file:
   - `YOUR_PROJECT_NUMBER`
   - `YOUR_PROJECT_ID`
   - `YOUR_ANDROID_APP_ID`
   - `YOUR_API_KEY`
   - `YOUR_CLIENT_ID`

#### iOS
1. Download `GoogleService-Info.plist` from Firebase Console
2. Replace the placeholder in `ios/Runner/GoogleService-Info.plist`
3. Update the following in the file:
   - `YOUR_PROJECT_NUMBER`
   - `YOUR_PROJECT_ID`
   - `YOUR_IOS_APP_ID`
   - `YOUR_API_KEY`
   - `YOUR_CLIENT_ID`

### 4. Run the App
```bash
# Check connected devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Or run in debug mode
flutter run --debug
```

## Firestore Collections

### Users
```json
{
  "uid": "user_123",
  "username": "dhiraj",
  "displayName": "Dhiraj Kumar",
  "bio": "Traveler and creator",
  "profileImage": "url",
  "postsCount": 12,
  "supportersCount": 420,
  "circlesCount": 180,
  "isAadhaarVerified": true,
  "verificationBadge": true,
  "createdAt": "timestamp"
}
```

### Posts
```json
{
  "postId": "post_123",
  "ownerId": "user_123",
  "imageUrl": "url",
  "caption": "Evening view",
  "location": "Bengaluru",
  "tags": ["travel", "photography"],
  "likesCount": 52,
  "commentsCount": 8,
  "sharesCount": 3,
  "createdAt": "timestamp"
}
```

### Comments
```json
{
  "commentId": "comment_123",
  "postId": "post_123",
  "userId": "user_789",
  "text": "Nice shot!",
  "isVerifiedComment": true,
  "createdAt": "timestamp"
}
```

### Stories
```json
{
  "storyId": "story_123",
  "ownerId": "user_123",
  "imageUrl": "url",
  "expiresAt": "timestamp",
  "createdAt": "timestamp",
  "seenBy": ["user_456", "user_789"]
}
```

## Security Features

### Comment Verification
- Only Aadhaar-verified users can comment
- Verification status stored in user document
- Backend validation ensures compliance

### Data Storage
- No raw Aadhaar data stored in app
- Only verification status and masked reference
- Secure backend-only verification flow

## Development Status

### ✅ Completed
- Flutter project setup with proper folder structure
- Firebase configuration and dependencies
- App router and theme system
- Authentication service (Firebase Auth)
- Login/Signup UI screens
- Firestore models and basic services
- Navigation structure with bottom navigation

### 🚧 In Progress
- Home feed UI with stories and photo feed
- Photo upload functionality
- Profile page with supporters/circles system

### 📋 Planned
- Follow/unfollow functionality
- Stories feature with 24-hour expiry
- Aadhaar verification for comments
- Comments system with verification gating
- Notifications system
- Search functionality

## Building for Production

### Android APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# Build for iOS (requires macOS)
flutter build ios --release
```

## Legal & Safety Notes

- Aadhaar handling is sensitive and must comply with legal requirements
- Verification provider logic should remain backend-only
- Never store raw Aadhaar numbers or downloadable identity data
- Ensure compliance with platform policies and local regulations

## Contributing

1. Follow the existing code structure and patterns
2. Use Riverpod for state management
3. Implement proper error handling
4. Add tests for new features
5. Update documentation as needed

## License

This project is licensed under the MIT License - see the LICENSE file for details.
