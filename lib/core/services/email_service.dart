import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Email Service for Pictogram
/// Handles all email sending through Firebase Functions
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  final _functions = FirebaseFunctions.instance;

  /// Send OTP verification email
  Future<bool> sendOtpEmail({
    required String email,
    required String otpCode,
    String? userName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendOtpEmail');
      final result = await callable.call({
        'email': email,
        'otpCode': otpCode,
        'userName': userName ?? 'there',
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending OTP email: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail({
    required String email,
    required String resetLink,
    String? userName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendPasswordResetEmail');
      final result = await callable.call({
        'email': email,
        'resetLink': resetLink,
        'userName': userName ?? 'there',
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  /// Send login alert (security notification)
  Future<bool> sendLoginAlert({
    required String email,
    required String loginTime,
    required String deviceName,
    required String location,
    String? userName,
    String? resetLink,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendLoginAlertEmail');
      final result = await callable.call({
        'email': email,
        'userName': userName ?? 'there',
        'loginTime': loginTime,
        'deviceName': deviceName,
        'location': location,
        'resetLink': resetLink ?? 'https://pictogram.app/reset-password',
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending login alert: $e');
      return false;
    }
  }

  /// Send support ticket acknowledgement
  Future<bool> sendSupportAcknowledgement({
    required String email,
    required String ticketId,
    required String ticketSubject,
    String? userName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendSupportAcknowledgement');
      final result = await callable.call({
        'email': email,
        'ticketId': ticketId,
        'ticketSubject': ticketSubject,
        'userName': userName ?? 'there',
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending support acknowledgement: $e');
      return false;
    }
  }

  /// Send new follower notification
  Future<bool> sendNewFollowerNotification({
    required String toEmail,
    required String followerName,
    required String followerHandle,
    required String followerAvatar,
    required String profileUrl,
    required int totalFollowers,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNewFollowerEmail');
      final result = await callable.call({
        'toEmail': toEmail,
        'followerName': followerName,
        'followerHandle': followerHandle,
        'followerAvatar': followerAvatar,
        'profileUrl': profileUrl,
        'totalFollowers': totalFollowers.toString(),
        'followDate': DateTime.now().toIso8601String(),
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending new follower email: $e');
      return false;
    }
  }

  /// Send content reported notification
  Future<bool> sendContentReportedNotification({
    required String email,
    required String contentType,
    required String contentPreview,
    required String reportReason,
    String? userName,
    String? reportDate,
    String? viewContentUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendContentReportedEmail');
      final result = await callable.call({
        'email': email,
        'userName': userName ?? 'there',
        'contentType': contentType,
        'contentPreview': contentPreview,
        'reportReason': reportReason,
        'reportDate': reportDate ?? DateTime.now().toIso8601String(),
        'viewContentUrl': viewContentUrl ?? 'https://pictogram.app',
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending content reported email: $e');
      return false;
    }
  }

  /// Admin only: Send account suspension email
  Future<bool> sendAccountSuspendedEmail({
    required String email,
    required String suspensionReason,
    String? userName,
    String? suspensionDuration,
    String? appealUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendAccountSuspendedEmail');
      final result = await callable.call({
        'email': email,
        'userName': userName ?? 'User',
        'suspensionReason': suspensionReason,
        'suspensionDuration': suspensionDuration ?? 'Indefinite',
        'appealUrl': appealUrl ?? 'https://pictogram.app/appeal',
      });
      return result.data['success'] == true;
    } catch (e) {
      print('Error sending suspension email: $e');
      return false;
    }
  }

  /// Track login for security alerts
  /// Call this when user logs in to trigger alert if suspicious
  Future<void> trackLogin({
    required String email,
    required String deviceName,
    required String location,
  }) async {
    try {
      // Store login info for comparison
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final callable = _functions.httpsCallable('trackLoginForAlert');
      await callable.call({
        'userId': user.uid,
        'email': email,
        'deviceName': deviceName,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error tracking login: $e');
    }
  }
}

// Global instance
final emailService = EmailService();
