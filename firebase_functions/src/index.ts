import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as sgMail from '@sendgrid/mail';
import * as fs from 'fs';
import * as path from 'path';

admin.initializeApp();

// Initialize SendGrid with API key from environment
const SENDGRID_API_KEY = functions.config().sendgrid?.key || process.env.SENDGRID_API_KEY;
if (SENDGRID_API_KEY) {
  sgMail.setApiKey(SENDGRID_API_KEY);
}

const FROM_EMAIL = 'Pictogram <support@pictogram.online>';
const EMAIL_TEMPLATES_PATH = path.join(__dirname, '../email_templates');

// Helper: Load and process email template
function loadTemplate(templateName: string, replacements: Record<string, string>): string {
  const templatePath = path.join(EMAIL_TEMPLATES_PATH, `${templateName}.html`);
  let template = fs.readFileSync(templatePath, 'utf8');
  
  // Replace all placeholders
  Object.entries(replacements).forEach(([key, value]) => {
    template = template.replace(new RegExp(`{{${key}}}`, 'g'), value);
  });
  
  return template;
}

// Helper: Send email via SendGrid
async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  if (!SENDGRID_API_KEY) {
    console.log('SendGrid not configured. Email would have been sent to:', to);
    console.log('Subject:', subject);
    return;
  }

  const msg = {
    to,
    from: FROM_EMAIL,
    subject,
    html,
  };

  await sgMail.send(msg);
  console.log(`Email sent successfully to ${to}`);
}

// ==================== EMAIL FUNCTIONS ====================

// 1. Welcome Email - Triggered on user creation
export const sendWelcomeEmail = functions.auth.user().onCreate(async (user) => {
  if (!user.email) return;

  const html = loadTemplate('welcome_email', {
    userName: user.displayName || 'there',
    appUrl: 'https://pictogram.app'
  });

  await sendEmail(user.email, 'Welcome to Pictogram ✨', html);
  
  // Log to Firestore
  await admin.firestore().collection('emailLogs').add({
    type: 'welcome',
    to: user.email,
    userId: user.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    status: 'sent'
  });
});

// 2. Send OTP Verification - Callable from app
export const sendOtpEmail = functions.https.onCall(async (data, context) => {
  const { email, userName, otpCode } = data;
  
  if (!email || !otpCode) {
    throw new functions.https.HttpsError('invalid-argument', 'Email and OTP code required');
  }

  const html = loadTemplate('otp_verification', {
    userName: userName || 'there',
    otpCode
  });

  await sendEmail(email, 'Your Pictogram Verification Code', html);
  
  return { success: true, message: 'OTP email sent' };
});

// 3. Password Reset
export const sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  const { email, userName, resetLink } = data;
  
  if (!email || !resetLink) {
    throw new functions.https.HttpsError('invalid-argument', 'Email and reset link required');
  }

  const html = loadTemplate('password_reset', {
    userName: userName || 'there',
    resetLink
  });

  await sendEmail(email, 'Reset Your Pictogram Password', html);
  
  return { success: true, message: 'Password reset email sent' };
});

// 4. Account Suspended Notification
export const sendAccountSuspendedEmail = functions.https.onCall(async (data, context) => {
  // Only admins can trigger this
  if (!context.auth?.token?.admin) {
    throw new functions.https.HttpsError('permission-denied', 'Admin access required');
  }

  const { email, userName, suspensionReason, suspensionDuration, appealUrl } = data;
  
  if (!email || !suspensionReason) {
    throw new functions.https.HttpsError('invalid-argument', 'Email and suspension reason required');
  }

  const html = loadTemplate('account_suspended', {
    userName: userName || 'User',
    suspensionReason,
    suspensionDuration: suspensionDuration || 'Indefinite',
    appealUrl: appealUrl || 'https://pictogram.app/appeal'
  });

  await sendEmail(email, 'Account Suspended - Pictogram', html);
  
  return { success: true, message: 'Suspension email sent' };
});

// 5. New Follower Notification
export const sendNewFollowerEmail = functions.https.onCall(async (data, context) => {
  const { toEmail, followerName, followerHandle, followerAvatar, profileUrl, totalFollowers, followDate } = data;
  
  if (!toEmail || !followerName) {
    throw new functions.https.HttpsError('invalid-argument', 'Required fields missing');
  }

  const html = loadTemplate('new_follower', {
    followerName,
    followerHandle: followerHandle || followerName.toLowerCase().replace(/\s/g, ''),
    followerAvatar: followerAvatar || '',
    profileUrl: profileUrl || 'https://pictogram.app',
    totalFollowers: totalFollowers || '1',
    followDate: followDate || new Date().toLocaleDateString()
  });

  await sendEmail(toEmail, 'New Follower on Pictogram!', html);
  
  return { success: true, message: 'New follower email sent' };
});

// 6. Content Reported Notification
export const sendContentReportedEmail = functions.https.onCall(async (data, context) => {
  const { email, userName, contentType, contentPreview, reportReason, reportDate, viewContentUrl } = data;
  
  if (!email || !contentType) {
    throw new functions.https.HttpsError('invalid-argument', 'Required fields missing');
  }

  const html = loadTemplate('content_reported', {
    userName: userName || 'there',
    contentType,
    contentPreview: contentPreview || 'Your content',
    reportReason: reportReason || 'Violation of Community Guidelines',
    reportDate: reportDate || new Date().toLocaleDateString(),
    viewContentUrl: viewContentUrl || 'https://pictogram.app'
  });

  await sendEmail(email, 'Content Reported - Pictogram', html);
  
  return { success: true, message: 'Content reported email sent' };
});

// 7. Login Alert (Security)
export const sendLoginAlertEmail = functions.https.onCall(async (data, context) => {
  const { email, userName, loginTime, deviceName, location, resetLink } = data;
  
  if (!email || !loginTime) {
    throw new functions.https.HttpsError('invalid-argument', 'Required fields missing');
  }

  const html = loadTemplate('login_alert', {
    userName: userName || 'there',
    loginTime,
    deviceName: deviceName || 'Unknown Device',
    location: location || 'Unknown Location',
    resetLink: resetLink || 'https://pictogram.app/reset-password'
  });

  await sendEmail(email, 'New Login Detected - Pictogram', html);
  
  return { success: true, message: 'Login alert email sent' };
});

// 8. Support Acknowledgement
export const sendSupportAcknowledgement = functions.https.onCall(async (data, context) => {
  const { email, userName, ticketId, ticketSubject } = data;
  
  if (!email || !ticketId) {
    throw new functions.https.HttpsError('invalid-argument', 'Email and ticket ID required');
  }

  const html = loadTemplate('support_acknowledgement', {
    userName: userName || 'there',
    ticketId,
    ticketSubject: ticketSubject || 'Support Request'
  });

  await sendEmail(email, 'We Received Your Request - Pictogram Support', html);
  
  return { success: true, message: 'Support acknowledgement sent' };
});

// ==================== SCHEDULED FUNCTIONS ====================

// Send weekly digest emails (optional)
export const sendWeeklyDigest = functions.pubsub.schedule('every sunday 09:00').onRun(async (context) => {
  // This would send weekly activity summaries to users
  console.log('Weekly digest job triggered');
  return null;
});

// Cleanup old email logs (run monthly)
export const cleanupEmailLogs = functions.pubsub.schedule('1 of month 00:00').onRun(async (context) => {
  const thirtyDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  );
  
  const oldLogs = await admin.firestore()
    .collection('emailLogs')
    .where('timestamp', '<', thirtyDaysAgo)
    .limit(500)
    .get();
  
  const batch = admin.firestore().batch();
  oldLogs.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  
  console.log(`Cleaned up ${oldLogs.size} old email logs`);
  return null;
});
