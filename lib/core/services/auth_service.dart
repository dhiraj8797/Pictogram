import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth = FirebaseService.auth;
  final FirebaseFirestore _firestore = FirebaseService.firestore;
  final _functions = FirebaseFunctions.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Auth state changes stream
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  firebase_auth.User? get currentUser => _auth.currentUser;

  // ==================== EMAIL VERIFICATION ====================

  /// Sign up with email and send OTP
  Future<EmailAuthResult> signUpWithOtp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final callable = _functions.httpsCallable('signupWithOtp');
      final result = await callable.call({
        'name': name,
        'username': username,
        'email': email,
        'password': password,
      });

      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return EmailAuthResult.success(
          userId: data['userId'],
          message: data['message'],
        );
      } else {
        return EmailAuthResult.failure(data['message'] ?? 'Signup failed');
      }
    } on FirebaseFunctionsException catch (e) {
      return EmailAuthResult.failure(e.message ?? 'Signup failed');
    } catch (e) {
      return EmailAuthResult.failure('Network error. Please try again.');
    }
  }

  /// Verify email with OTP
  Future<EmailAuthResult> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyEmail');
      final result = await callable.call({
        'email': email,
        'otp': otp,
      });

      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        // Sign in with custom token
        final token = data['token'] as String;
        await _auth.signInWithCustomToken(token);
        
        return EmailAuthResult.success(
          message: data['message'],
          userId: data['user']?['id'],
        );
      } else {
        return EmailAuthResult.failure(data['message'] ?? 'Verification failed');
      }
    } on FirebaseFunctionsException catch (e) {
      return EmailAuthResult.failure(e.message ?? 'Verification failed');
    } catch (e) {
      return EmailAuthResult.failure('Network error. Please try again.');
    }
  }

  /// Resend OTP
  Future<bool> resendOtp({required String email}) async {
    try {
      final callable = _functions.httpsCallable('resendOtp');
      final result = await callable.call({'email': email});
      return result.data['success'] == true;
    } catch (e) {
      print('Resend OTP error: $e');
      return false;
    }
  }

  // ==================== PASSWORD RESET ====================

  /// Send password reset email
  Future<EmailAuthResult> forgotPassword({required String email}) async {
    try {
      final callable = _functions.httpsCallable('forgotPassword');
      final result = await callable.call({'email': email});

      final data = result.data as Map<String, dynamic>;
      return EmailAuthResult.success(message: data['message']);
    } on FirebaseFunctionsException catch (e) {
      return EmailAuthResult.failure(e.message ?? 'Request failed');
    } catch (e) {
      return EmailAuthResult.failure('Network error. Please try again.');
    }
  }

  /// Reset password with token
  Future<EmailAuthResult> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final callable = _functions.httpsCallable('resetPassword');
      final result = await callable.call({
        'email': email,
        'token': token,
        'newPassword': newPassword,
      });

      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return EmailAuthResult.success(message: data['message']);
      } else {
        return EmailAuthResult.failure(data['message'] ?? 'Reset failed');
      }
    } on FirebaseFunctionsException catch (e) {
      return EmailAuthResult.failure(e.message ?? 'Reset failed');
    } catch (e) {
      return EmailAuthResult.failure('Network error. Please try again.');
    }
  }

  // Sign up with email and password
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      final user = AppUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        displayName: displayName,
        bio: '',
        createdAt: Timestamp.now(),
        // Automatically verify official PictoGram account
        verificationBadge: displayName.toLowerCase().contains('pictogram') || 
                           email.toLowerCase().contains('pictogram'),
      );

      // Try to save to Firestore with timeout and error handling
      try {
        await _firestore.collection('users').doc(user.uid).set(user.toFirestore())
            .timeout(const Duration(seconds: 10));
      } catch (firestoreError) {
        // If Firestore fails, we still have the auth user, so log the error but continue
        print('Warning: Failed to save user data to Firestore: $firestoreError');
        // You could implement a retry mechanism or local storage here
      }

      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      // Handle network and other errors
      if (e.toString().contains('network') || 
          e.toString().contains('connection') ||
          e.toString().contains('host') ||
          e.toString().contains('timeout')) {
        return AuthResult.failure('Network connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('timeout')) {
        return AuthResult.failure('Request timed out. Please try again.');
      } else {
        return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
      }
    }
  }

  // Helper method to format phone number to E.164 format
  String _formatPhoneNumberToE164(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If already in E.164 format, return as is
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    }
    
    // For Indian numbers, add +91 prefix
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    
    // For other countries, assume international format without country code
    // This is a simplified implementation - in production, use proper phone number library
    if (cleaned.length > 10 && !cleaned.startsWith('0')) {
      return '+$cleaned';
    }
    
    // Default fallback
    return '+91$cleaned';
  }

  // Format phone number to international format
  String _formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Check if already in international format
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      return '+$cleaned';
    }
    
    // Default fallback for Indian numbers
    if (cleaned.length == 10) {
      return '+91$cleaned';
    }
    
    // Return as is if it doesn't match expected patterns
    return phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';
  }

  // Sign up with phone number
  Future<AuthResult> signUpWithPhone({
    required String phoneNumber,
    required String displayName,
  }) async {
    try {
      // Format phone number
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // Check if phone number already exists
      final existingUser = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        return AuthResult.failure('An account already exists with this phone number');
      }

      // Return success - UI will handle OTP verification
      return AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure('Failed to sign up with phone: $e');
    }
  }

  // Complete phone signup after OTP verification
  Future<AuthResult> completePhoneSignup({
    required String phoneNumber,
    required String displayName,
    required String uid,
  }) async {
    try {
      // Format phone number
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      
      // Create user document in Firestore
      final user = AppUser(
        uid: uid,
        email: '', // Phone auth users don't have email
        phoneNumber: formattedPhone,
        displayName: displayName,
        bio: '',
        createdAt: Timestamp.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(user.toFirestore());

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('Failed to create user account: $e');
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('DEBUG: Starting Firebase sign in for email: $email');
      
      // Add timeout to prevent hanging
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 6),
        onTimeout: () {
          throw TimeoutException('Login timeout. Please check your connection and try again.');
        },
      );

      print('DEBUG: Firebase sign in successful, fetching user data');

      // Fetch user data with timeout
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw TimeoutException('User data fetch timeout. Please try again.');
            },
          );

      if (!userDoc.exists) {
        print('DEBUG: User document not found in Firestore');
        return AuthResult.failure('User not found');
      }

      final user = AppUser.fromFirestore(userDoc);
      print('DEBUG: User data loaded successfully');
      return AuthResult.success(user);
    } on TimeoutException catch (e) {
      print('DEBUG: Login timeout: $e');
      return AuthResult.failure(e.message ?? 'Login timeout. Please try again.');
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('DEBUG: Firebase auth exception: ${e.code} - ${e.message}');
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      print('DEBUG: Unexpected login error: $e');
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // ==================== GOOGLE SIGN-IN ====================

  /// Sign in with Google - returns pending state for new users to show permission screen
  Future<AuthResult> signInWithGoogle() async {
    try {
      print('DEBUG: Starting Google Sign-In');
      
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('DEBUG: Google Sign-In cancelled by user');
        return AuthResult.failure('Google Sign-In cancelled');
      }
      
      print('DEBUG: Google user signed in: ${googleUser.email}');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        return AuthResult.failure('Failed to sign in with Google');
      }
      
      print('DEBUG: Firebase Google sign-in successful, uid: ${firebaseUser.uid}');
      
      // Check if user exists in Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      
      if (!userDoc.exists) {
        // New user - return pending state with Google data for permission screen
        print('DEBUG: New Google user - showing permission screen');
        
        return AuthResult.pending(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? googleUser.email,
          displayName: firebaseUser.displayName ?? googleUser.displayName ?? 'Google User',
          profileImage: firebaseUser.photoURL,
        );
      }
      
      // Update last login for existing user
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
      
      final user = AppUser.fromFirestore(userDoc);
      print('DEBUG: Existing Google user loaded');
      return AuthResult.success(user);
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('DEBUG: Firebase auth exception during Google sign-in: ${e.code} - ${e.message}');
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      print('DEBUG: Unexpected Google sign-in error: $e');
      return AuthResult.failure('Google Sign-In failed: ${e.toString()}');
    }
  }
  
  /// Generate username from email
  String _generateUsernameFromEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'user_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    }
    final base = email.split('@')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return '${base}_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
  }

  // Sign in with phone number
  Future<AuthResult> signInWithPhone({
    required String phoneNumber,
  }) async {
    try {
      // Verify phone number first
      await _verifyPhoneNumber(phoneNumber);
      
      // Note: In phone auth, we'll need to handle this differently after verification
      return AuthResult.failure('Phone login requires OTP verification - coming soon!');
    } catch (e) {
      return AuthResult.failure('Phone login failed: $e');
    }
  }

  // Verify phone number (send OTP)
  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    // Format phone number if needed
    String formattedPhone = phoneNumber;
    if (!phoneNumber.startsWith('+')) {
      formattedPhone = '+91$phoneNumber'; // Default to India country code
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
        // Auto verification completed
        // This will be handled by the UI
      },
      verificationFailed: (firebase_auth.FirebaseAuthException e) {
        throw Exception('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        // Code sent to phone
        // This will be handled by the UI
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Auto retrieval timeout
        // This will be handled by the UI
      },
    );
  }

  // Send OTP to phone number — returns verificationId via callback
  Future<void> sendPhoneOTP({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(firebase_auth.PhoneAuthCredential)? onAutoVerified,
  }) async {
    final formatted = phoneNumber.trim().startsWith('+')
        ? phoneNumber.trim()
        : '+${phoneNumber.trim()}';
    await _auth.verifyPhoneNumber(
      phoneNumber: formatted,
      verificationCompleted: (cred) => onAutoVerified?.call(cred),
      verificationFailed: (e) => onError(e.message ?? 'Verification failed'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // Sign in with phone and OTP
  Future<AuthResult> signInWithPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return AuthResult.failure('User not found');
      }

      final user = AppUser.fromFirestore(userDoc);
      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send Firebase password reset email (legacy)
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred');
    }
  }

  // Get user data
  Future<AppUser?> getUserData(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile image
  Future<AuthResult> updateProfileImage({
    String? displayName,
    String? bio,
    String? profileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user logged in');
      }

      // Validate inputs
      if (displayName != null && displayName.trim().isEmpty) {
        return AuthResult.failure('Display name cannot be empty');
      }
      if (displayName != null && displayName.trim().length < 2) {
        return AuthResult.failure('Display name must be at least 2 characters');
      }
      if (bio != null && bio.length > 150) {
        return AuthResult.failure('Bio must be less than 150 characters');
      }

      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName.trim();
      if (bio != null) updates['bio'] = bio.trim();
      if (profileImage != null) updates['profileImage'] = profileImage;

      // Only update if there are changes
      if (updates.isEmpty) {
        final currentUserDoc = await _firestore.collection('users').doc(user.uid).get();
        final currentUser = AppUser.fromFirestore(currentUserDoc);
        return AuthResult.success(currentUser);
      }

      await _firestore.collection('users').doc(user.uid).update(updates);

      final updatedUserDoc = await _firestore.collection('users').doc(user.uid).get();
      final updatedUser = AppUser.fromFirestore(updatedUserDoc);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.failure('Failed to update profile: $e');
    }
  }

  // Check if phone number is unique
  Future<bool> isPhoneNumberUnique(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check phone number uniqueness: $e');
    }
  }

  // Check if username is unique
  Future<bool> isUsernameUnique(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username uniqueness: $e');
    }
  }

  String _getErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'invalid-phone-number':
        return 'The phone number is not valid.';
      case 'phone-number-already-in-use':
        return 'An account already exists for this phone number.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String bio,
    String? profileImage,
    String? location,
    DateTime? dateOfBirth,
    bool? isPrivate,
    String? phoneNumber,
  }) async {
    try {
      // Validate inputs
      if (displayName.trim().isEmpty) {
        throw Exception('Display name cannot be empty');
      }
      if (displayName.trim().length < 2) {
        throw Exception('Display name must be at least 2 characters');
      }
      if (bio.length > 150) {
        throw Exception('Bio must be less than 150 characters');
      }
      if (location != null && location.length > 50) {
        throw Exception('Location must be less than 50 characters');
      }
      if (dateOfBirth != null) {
        final now = DateTime.now();
        final age = now.year - dateOfBirth.year;
        if (age < 13 || age > 120) {
          throw Exception('Age must be between 13 and 120 years');
        }
      }
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Basic phone number validation
        final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{10,20}$');
        if (!phoneRegex.hasMatch(phoneNumber)) {
          throw Exception('Please enter a valid phone number');
        }
      }

      // Update display name in Firebase Auth
      await _auth.currentUser?.updateDisplayName(displayName);

      String? profileImageUrl = profileImage;

      // If profileImage is a local file path, upload to Storage
      if (profileImage != null && !profileImage.startsWith('http')) {
        profileImageUrl = await _uploadProfileImage(uid, profileImage);
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'displayName': displayName.trim(),
        'bio': bio.trim(),
        'profileImage': profileImageUrl,
        'location': location?.trim().isNotEmpty == true ? location!.trim() : null,
        'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth) : null,
        'isPrivate': isPrivate,
        'phoneNumber': phoneNumber?.trim().isNotEmpty == true ? phoneNumber!.trim() : null,
        'updatedAt': Timestamp.now(),
      };

      // Remove null values
      updateData.removeWhere((key, value) => value == null);

      // Update user document in Firestore
      await _firestore.collection('users').doc(uid).update(updateData);
      
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Retry logic for production-grade operations
Future<T> _retryOperation<T>(Future<T> Function() operation, {int maxRetries = 3}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxRetries - 1) {
        // Last attempt failed, throw the exception
        rethrow;
      }
      
      // Wait before retry with exponential backoff
      final delay = Duration(seconds: 2 * (i + 1));
      print('Operation failed, retrying in ${delay.inSeconds}s... Attempt ${i + 1}/$maxRetries');
      await Future.delayed(delay);
    }
  }
  throw Exception('Operation failed after $maxRetries retries');
}

// Upload profile image to Storage
  Future<String> uploadProfileImage(String uid, String imagePath) async {
    return await _retryOperation(() async {
      try {
        print('Starting profile image upload for user: $uid');
        print('Image path: $imagePath');
        
        final storage = FirebaseService.storage;
        final ref = storage.ref().child('profile_images/$uid.jpg');
        
        print('Uploading to Firebase Storage...');
        
        // Upload file with timeout
        final uploadTask = await ref.putFile(File(imagePath)).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Upload timed out after 30 seconds');
          },
        );
        
        print('Upload completed, getting download URL...');
        
        // Get download URL with timeout
        final downloadUrl = await uploadTask.ref.getDownloadURL().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Failed to get download URL - timeout');
          },
        );
        
        print('Profile image uploaded successfully: $downloadUrl');
        return downloadUrl;
      } catch (e) {
        print('Profile image upload error: $e');
        
        String errorMessage = 'Failed to upload profile image';
        
        if (e.toString().contains('timeout')) {
          errorMessage = 'Upload timed out. Please check your connection and try again.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please check app permissions.';
        } else if (e.toString().contains('file')) {
          errorMessage = 'File error. Please check if the image file is valid.';
        } else if (e.toString().contains('storage') || e.toString().contains('bucket')) {
          errorMessage = 'Storage error. Firebase Storage may not be configured properly.';
        } else if (e.toString().contains('unauthorized') || e.toString().contains('auth')) {
          errorMessage = 'Authentication error. Please login again.';
        }
        
        throw Exception(errorMessage);
      }
    });
  }

  // Upload profile image to Storage (private method)
  Future<String> _uploadProfileImage(String uid, String imagePath) async {
    return await uploadProfileImage(uid, imagePath);
  }

  // Delete user account
  Future<void> deleteAccount(String uid) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user before deletion (Firebase requirement)
      if (user.providerData.any((provider) => provider.providerId == 'password')) {
        // For email/password users, we need to re-authenticate
        // In a real app, you'd ask for password again
        // For now, we'll proceed with the deletion
      }

      // Delete user's Storage files first
      await _deleteUserStorageFiles(uid);

      // Delete user's related Firestore documents
      await _deleteUserFirestoreData(uid);

      // Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete user from Firebase Auth
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Delete user's Storage files
  Future<void> _deleteUserStorageFiles(String uid) async {
    try {
      final storage = FirebaseService.storage;
      
      // Delete profile image
      final profileImageRef = storage.ref().child('profile_images/$uid.jpg');
      await profileImageRef.delete();

      // Delete all user posts
      final postsRef = storage.ref().child('posts/$uid');
      final postsList = await postsRef.listAll();
      for (final item in postsList.items) {
        await item.delete();
      }

      // Delete all user stories
      final storiesRef = storage.ref().child('stories/$uid');
      final storiesList = await storiesRef.listAll();
      for (final item in storiesList.items) {
        await item.delete();
      }
    } catch (e) {
      print('Warning: Failed to delete some storage files: $e');
      // Continue with deletion even if storage cleanup fails
    }
  }

  // Delete user's related Firestore documents
  Future<void> _deleteUserFirestoreData(String uid) async {
    try {
      final batch = _firestore.batch();

      // Delete user's posts
      final postsQuery = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in postsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's comments
      final commentsQuery = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in commentsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's likes
      final likesQuery = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in likesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's follows (both following and followers)
      final followingQuery = await _firestore
          .collection('follows')
          .where('followerId', isEqualTo: uid)
          .get();
      
      for (final doc in followingQuery.docs) {
        batch.delete(doc.reference);
      }

      final followersQuery = await _firestore
          .collection('follows')
          .where('followingId', isEqualTo: uid)
          .get();
      
      for (final doc in followersQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's stories
      final storiesQuery = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in storiesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's notifications
      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();
      
      for (final doc in notificationsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Warning: Failed to delete some Firestore data: $e');
      // Continue with deletion even if some cleanup fails
    }
  }
}

class AuthResult {
  final bool success;
  final AppUser? user;
  final String? error;
  final bool isPending;
  final String? pendingUid;
  final String? pendingEmail;
  final String? pendingDisplayName;
  final String? pendingProfileImage;

  AuthResult({
    required this.success,
    this.user,
    this.error,
    this.isPending = false,
    this.pendingUid,
    this.pendingEmail,
    this.pendingDisplayName,
    this.pendingProfileImage,
  });

  factory AuthResult.success(AppUser? user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String error) {
    return AuthResult(success: false, error: error);
  }

  factory AuthResult.pending({
    required String uid,
    required String email,
    required String displayName,
    String? profileImage,
  }) {
    return AuthResult(
      success: false,
      isPending: true,
      pendingUid: uid,
      pendingEmail: email,
      pendingDisplayName: displayName,
      pendingProfileImage: profileImage,
    );
  }
}

class EmailAuthResult {
  final bool success;
  final String? userId;
  final String? message;
  final String? errorMessage;

  EmailAuthResult({
    required this.success,
    this.userId,
    this.message,
    this.errorMessage,
  });

  factory EmailAuthResult.success({
    String? userId,
    String? message,
  }) {
    return EmailAuthResult(
      success: true,
      userId: userId,
      message: message,
    );
  }

  factory EmailAuthResult.failure(String error) {
    return EmailAuthResult(
      success: false,
      errorMessage: error,
    );
  }
}
