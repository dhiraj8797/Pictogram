import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import {
  sendWelcomeEmail,
  sendOtpEmail,
  sendPasswordResetEmail,
} from "./pictogram_email_service.js";

admin.initializeApp();

const db = admin.firestore();

// Helper: Generate secure random OTP
function generateOtp(length = 6) {
  const digits = "0123456789";
  let otp = "";
  for (let i = 0; i < length; i++) {
    otp += digits[Math.floor(Math.random() * digits.length)];
  }
  return otp;
}

// Helper: Hash value using SHA-256
function hashValue(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

// ==================== AUTH FUNCTIONS ====================

// SIGNUP + SEND OTP (Callable from Flutter)
export const signupWithOtp = functions.https.onCall(async (data, context) => {
  try {
    const { name, username, email, password } = data;

    if (!name || !username || !email || !password) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "All fields are required"
      );
    }

    // Check if user exists in Firebase Auth
    try {
      await admin.auth().getUserByEmail(email.toLowerCase());
      throw new functions.https.HttpsError(
        "already-exists",
        "Email already registered"
      );
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        throw error;
      }
    }

    // Check if username exists in Firestore
    const usernameCheck = await db
      .collection("users")
      .where("username", "==", username.toLowerCase())
      .get();

    if (!usernameCheck.empty) {
      throw new functions.https.HttpsError(
        "already-exists",
        "Username already taken"
      );
    }

    // Generate OTP
    const rawOtp = generateOtp();
    const hashedOtp = hashValue(rawOtp);
    const otpExpires = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000)
    );

    // Create Firebase Auth user
    const userRecord = await admin.auth().createUser({
      email: email.toLowerCase(),
      password,
      displayName: name,
    });

    // Store user data in Firestore
    await db.collection("users").doc(userRecord.uid).set({
      name,
      username: username.toLowerCase(),
      email: email.toLowerCase(),
      isEmailVerified: false,
      emailOtpCode: hashedOtp,
      emailOtpExpiresAt: otpExpires,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send OTP email
    await sendOtpEmail(email.toLowerCase(), name, rawOtp);

    return {
      success: true,
      message: "Account created. Check your email for verification code.",
      userId: userRecord.uid,
    };
  } catch (error) {
    console.error("Signup error:", error);
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Failed to create account"
    );
  }
});

// VERIFY EMAIL + SEND WELCOME (Callable from Flutter)
export const verifyEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp } = data;

    if (!email || !otp) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email and OTP are required"
      );
    }

    const hashedOtp = hashValue(otp);

    // Find user by email and OTP
    const userQuery = await db
      .collection("users")
      .where("email", "==", email.toLowerCase())
      .where("emailOtpCode", "==", hashedOtp)
      .limit(1)
      .get();

    if (userQuery.empty) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid or expired OTP"
      );
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();

    // Check if OTP expired
    if (
      userData.emailOtpExpiresAt &&
      userData.emailOtpExpiresAt.toDate() < new Date()
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "OTP has expired"
      );
    }

    // Update Firestore
    await userDoc.ref.update({
      isEmailVerified: true,
      emailOtpCode: admin.firestore.FieldValue.delete(),
      emailOtpExpiresAt: admin.firestore.FieldValue.delete(),
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send welcome email
    await sendWelcomeEmail(email.toLowerCase(), userData.name);

    // Get Firebase Auth user for token
    const userRecord = await admin.auth().getUserByEmail(email.toLowerCase());

    // Create custom token
    const customToken = await admin.auth().createCustomToken(userRecord.uid);

    return {
      success: true,
      message: "Email verified successfully.",
      token: customToken,
      user: {
        id: userRecord.uid,
        name: userData.name,
        username: userData.username,
        email: userData.email,
        isEmailVerified: true,
      },
    };
  } catch (error) {
    console.error("Verify email error:", error);
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Email verification failed"
    );
  }
});

// RESEND OTP (Callable from Flutter)
export const resendOtp = functions.https.onCall(async (data, context) => {
  try {
    const { email } = data;

    if (!email) {
      throw new functions.https.HttpsError("invalid-argument", "Email is required");
    }

    // Find user
    const userQuery = await db
      .collection("users")
      .where("email", "==", email.toLowerCase())
      .limit(1)
      .get();

    if (userQuery.empty) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();

    if (userData.isEmailVerified) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Email already verified"
      );
    }

    // Generate new OTP
    const rawOtp = generateOtp();
    const hashedOtp = hashValue(rawOtp);
    const otpExpires = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 10 * 60 * 1000)
    );

    // Update Firestore
    await userDoc.ref.update({
      emailOtpCode: hashedOtp,
      emailOtpExpiresAt: otpExpires,
    });

    // Send OTP email
    await sendOtpEmail(email.toLowerCase(), userData.name, rawOtp);

    return {
      success: true,
      message: "New OTP sent to your email.",
    };
  } catch (error) {
    console.error("Resend OTP error:", error);
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Failed to resend OTP"
    );
  }
});

// FORGOT PASSWORD (Callable from Flutter)
export const forgotPassword = functions.https.onCall(async (data, context) => {
  try {
    const { email } = data;

    if (!email) {
      throw new functions.https.HttpsError("invalid-argument", "Email is required");
    }

    // Find user
    const userQuery = await db
      .collection("users")
      .where("email", "==", email.toLowerCase())
      .where("isEmailVerified", "==", true)
      .limit(1)
      .get();

    // Always return success to prevent email enumeration
    if (userQuery.empty) {
      return {
        success: true,
        message: "If that email exists, a reset link has been sent.",
      };
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();

    // Generate reset token
    const rawToken = crypto.randomBytes(32).toString("hex");
    const hashedToken = hashValue(rawToken);
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 60 * 60 * 1000)
    );

    // Store in Firestore
    await userDoc.ref.update({
      passwordResetToken: hashedToken,
      passwordResetExpiresAt: expiresAt,
    });

    const resetLink = `${process.env.APP_URL}/reset-password?token=${rawToken}&email=${encodeURIComponent(
      email.toLowerCase()
    )}`;

    // Send reset email
    await sendPasswordResetEmail(email.toLowerCase(), userData.name, resetLink);

    return {
      success: true,
      message: "If that email exists, a reset link has been sent.",
    };
  } catch (error) {
    console.error("Forgot password error:", error);
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Failed to process forgot password request"
    );
  }
});

// RESET PASSWORD (Callable from Flutter)
export const resetPassword = functions.https.onCall(async (data, context) => {
  try {
    const { email, token, newPassword } = data;

    if (!email || !token || !newPassword) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email, token, and new password are required"
      );
    }

    const hashedToken = hashValue(token);

    // Find user
    const userQuery = await db
      .collection("users")
      .where("email", "==", email.toLowerCase())
      .where("passwordResetToken", "==", hashedToken)
      .limit(1)
      .get();

    if (userQuery.empty) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Invalid or expired reset link"
      );
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();

    // Check if token expired
    if (
      userData.passwordResetExpiresAt &&
      userData.passwordResetExpiresAt.toDate() < new Date()
    ) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Reset link has expired"
      );
    }

    // Update Firebase Auth password
    const userRecord = await admin.auth().getUserByEmail(email.toLowerCase());
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    // Clear reset token from Firestore
    await userDoc.ref.update({
      passwordResetToken: admin.firestore.FieldValue.delete(),
      passwordResetExpiresAt: admin.firestore.FieldValue.delete(),
    });

    return {
      success: true,
      message: "Password reset successful.",
    };
  } catch (error) {
    console.error("Reset password error:", error);
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Password reset failed"
    );
  }
});

// Trigger: Send welcome email when user is verified
export const onUserVerified = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Only send if just verified
    if (!before.isEmailVerified && after.isEmailVerified) {
      try {
        await sendWelcomeEmail(after.email, after.name);
        console.log(`Welcome email sent to ${after.email}`);
      } catch (error) {
        console.error("Failed to send welcome email:", error);
      }
    }
  });

/*
Flutter Integration Example:

import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  final _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> signup({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final callable = _functions.httpsCallable('signupWithOtp');
    final result = await callable.call({
      'name': name,
      'username': username,
      'email': email,
      'password': password,
    });
    return result.data;
  }

  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final callable = _functions.httpsCallable('verifyEmail');
    final result = await callable.call({
      'email': email,
      'otp': otp,
    });
    return result.data;
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    final callable = _functions.httpsCallable('resendOtp');
    final result = await callable.call({'email': email});
    return result.data;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final callable = _functions.httpsCallable('forgotPassword');
    final result = await callable.call({'email': email});
    return result.data;
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final callable = _functions.httpsCallable('resetPassword');
    final result = await callable.call({
      'email': email,
      'token': token,
      'newPassword': newPassword,
    });
    return result.data;
  }
}
*/
