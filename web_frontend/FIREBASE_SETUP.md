# Firebase Setup Guide for PictoGram Website

## 🔑 Get Your Firebase Configuration

Your website is now ready to connect to the same Firebase backend as your Flutter app. Follow these steps:

### 1. Get Firebase Config from Your Flutter App

Open your Flutter app's Firebase configuration file:

**Path**: `android/app/google-services.json` (for Android) or `ios/Runner/GoogleService-Info.plist` (for iOS)

Or get it from your Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your PictoGram project
3. Click Project Settings (gear icon)
4. Under "Your apps", select your web app
5. Copy the `firebaseConfig` object

### 2. Update Firebase Configuration

Edit `web_frontend/script.js` and replace the placeholder config:

```javascript
// Find this section in script.js (around line 32)
const firebaseConfig = {
    apiKey: "your-api-key-here",           // Replace with your API key
    authDomain: "your-project-id.firebaseapp.com",  // Replace with your project ID
    projectId: "your-project-id",          // Replace with your project ID
    storageBucket: "your-project-id.appspot.com",   // Replace with your project ID
    messagingSenderId: "your-sender-id",   // Replace with your sender ID
    appId: "your-app-id"                  // Replace with your app ID
};
```

### 3. Example Firebase Config

Your config should look something like this:

```javascript
const firebaseConfig = {
    apiKey: "AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    authDomain: "pictogram-app.firebaseapp.com",
    projectId: "pictogram-app",
    storageBucket: "pictogram-app.appspot.com",
    messagingSenderId: "123456789012",
    appId: "1:123456789012:web:abcdef1234567890"
};
```

### 4. Enable Authentication Methods

In your Firebase Console:
1. Go to Authentication → Sign-in method
2. Enable **Email/Password** authentication
3. Configure any additional providers (Google, Facebook, etc.)

### 5. Configure Firestore Rules

Ensure your Firestore security rules allow web access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public posts can be read by everyone, written by authenticated users
    match /posts/{postId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Messages between users
    match /chats/{chatId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 🚀 Features Available

### ✅ Authentication
- **Login with Email/Password** - Same as your Flutter app
- **Signup with Email/Password** - Creates account in same Firebase project
- **User Profile Management** - Display names, avatars
- **Session Persistence** - Users stay logged in

### ✅ Real-time Features (when configured)
- **User Database** - Same users collection as app
- **Posts Feed** - Real-time posts from Firestore
- **Messaging System** - Chat functionality
- **Follow System** - User relationships

### 🔄 Demo Mode
If Firebase is not configured, the website runs in **demo mode**:
- Users can "login" with any email/password
- Data is stored locally (not persisted)
- Perfect for testing UI/UX

## 🛠️ Testing Firebase Integration

### 1. Test Demo Mode First
```bash
# Open website
http://localhost:3000

# Try login with any email (demo mode)
test@example.com
password123
```

### 2. Test Firebase Mode
After configuring Firebase:
```bash
# Use real Firebase credentials
your-real-email@example.com
your-real-password
```

### 3. Verify Cross-Platform
- **Create account** on website
- **Login with same credentials** in Flutter app
- **Posts/messages** should sync across platforms

## 🔧 Troubleshooting

### Common Issues:

**"Firebase not configured" message**
- Check your Firebase config values
- Ensure Firebase SDK loads properly
- Check browser console for errors

**"No account found with this email"**
- User doesn't exist in Firebase
- Create account first, then login
- Check Authentication → Users in Firebase Console

**"Incorrect password"**
- Wrong password for existing user
- Reset password in Firebase Console if needed

**"Too many failed attempts"**
- Firebase rate limiting
- Wait a few minutes before trying again
- Check Authentication → Sign-in method settings

### Debug Mode:
Open browser console (F12) to see:
- Firebase initialization status
- Authentication errors
- Network requests to Firebase

## 📱 Cross-Platform Benefits

### Same User Base:
- **One account** works on both web and mobile
- **Unified user database** in Firebase
- **Consistent authentication** across platforms

### Shared Data:
- **Posts** created on web appear in app
- **Messages** sync in real-time
- **User profiles** are consistent

### Seamless Experience:
- **Start conversation on web, continue on mobile**
- **Upload photo from app, view on web**
- **Single sign-on** ecosystem

## 🌟 Next Steps

1. **Configure Firebase** with your real credentials
2. **Test authentication** with real user accounts
3. **Enable real-time features** (posts, messages)
4. **Deploy to pictogram.online** with Firebase
5. **Share unified experience** with your users!

---

**🎯 Your PictoGram website will use the exact same Firebase backend as your mobile app!**
