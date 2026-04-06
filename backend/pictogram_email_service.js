import nodemailer from "nodemailer";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

// Brand configuration
const BRAND = {
  name: "Pictogram",
  supportEmail: "support@pictogram.online",
  appUrl: process.env.APP_URL || "https://pictogram.online",
  primaryColor: "#7c3aed",
};

// SMTP Transporter setup (Titan Email)
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || "smtp.titan.email",
  port: parseInt(process.env.EMAIL_PORT || "587", 10),
  secure: process.env.EMAIL_SECURE === "true",
  auth: {
    user: process.env.EMAIL_USER || BRAND.supportEmail,
    pass: process.env.EMAIL_PASS,
  },
  tls: {
    rejectUnauthorized: false,
  },
});

// ==================== EMAIL TEMPLATES ====================

function baseTemplate({ title, previewText, bodyContent }) {
  return {
    subject: title,
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${title}</title>
</head>
<body style="margin:0;padding:0;background:#0b0b14;font-family:Arial,Helvetica,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:#0b0b14;padding:32px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:600px;background:linear-gradient(180deg,#151528 0%,#0f1020 100%);border:1px solid #2d2f55;border-radius:24px;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,0.35);">
          <tr>
            <td style="padding:28px 32px;background:linear-gradient(135deg,#7c3aed 0%,#a855f7 45%,#ec4899 100%);text-align:center;">
              <div style="display:inline-block;padding:10px 18px;border-radius:999px;background:rgba(255,255,255,0.16);color:#fff;font-size:12px;font-weight:700;letter-spacing:1px;text-transform:uppercase;">${BRAND.name}</div>
              <h1 style="margin:18px 0 8px;color:#ffffff;font-size:28px;line-height:1.2;">${title}</h1>
              ${previewText ? `<p style="margin:0;color:#f3e8ff;font-size:15px;line-height:1.7;">${previewText}</p>` : ""}
            </td>
          </tr>
          <tr>
            <td style="padding:36px 32px 12px;">
              ${bodyContent}
            </td>
          </tr>
          <tr>
            <td style="padding:24px 32px 36px;color:#94a3b8;font-size:12px;line-height:1.8;border-top:1px solid #222445;">
              Need help? Reach us at <a href="mailto:${BRAND.supportEmail}" style="color:#c4b5fd;text-decoration:none;">${BRAND.supportEmail}</a><br>
              © 2026 ${BRAND.name}. All rights reserved.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
  };
}

// Welcome Email Template
function welcomeTemplate({ userName }) {
  return baseTemplate({
    title: "Welcome to Pictogram ✨",
    previewText: "Your creative world is ready. Share moments, connect instantly.",
    bodyContent: `
      <p style="margin:0 0 16px;color:#ffffff;font-size:16px;line-height:1.8;">Hi ${userName},</p>
      <p style="margin:0 0 18px;color:#cbd5e1;font-size:15px;line-height:1.9;">Thanks for joining <strong style="color:#ffffff;">Pictogram</strong>. Your account has been created successfully. Start posting, building your profile, and discovering content from people you care about.</p>
      <table role="presentation" cellspacing="0" cellpadding="0" style="margin:28px 0;">
        <tr>
          <td align="center" bgcolor="#8b5cf6" style="border-radius:14px;">
            <a href="${BRAND.appUrl}" style="display:inline-block;padding:14px 26px;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;">Open Pictogram</a>
          </td>
        </tr>
      </table>
      <div style="margin-top:12px;padding:18px 20px;border:1px solid #2d2f55;border-radius:18px;background:#121326;">
        <p style="margin:0 0 10px;color:#ffffff;font-size:14px;font-weight:700;">Quick start</p>
        <p style="margin:0;color:#cbd5e1;font-size:14px;line-height:1.8;">• Complete your profile<br>• Upload your first post<br>• Follow creators and friends<br>• Explore trending content</p>
      </div>
    `,
  });
}

// OTP Verification Template
function otpTemplate({ userName, otpCode }) {
  return baseTemplate({
    title: "Verify Your Account 🔐",
    previewText: "Use the code below to complete your verification",
    bodyContent: `
      <p style="margin:0 0 24px;color:#cbd5e1;font-size:15px;line-height:1.8;text-align:center;">Hi ${userName},<br>Here is your one-time verification code:</p>
      <div style="text-align:center;">
        <div style="display:inline-block;padding:24px 40px;background:linear-gradient(135deg,#1a1a2e 0%,#16162a 100%);border:2px solid #7c3aed;border-radius:16px;margin:16px 0;">
          <span style="font-size:42px;font-weight:700;letter-spacing:8px;color:#ffffff;font-family:'Courier New',monospace;">${otpCode}</span>
        </div>
        <p style="margin:24px 0 0;color:#94a3b8;font-size:13px;line-height:1.6;">This code expires in <strong style="color:#c4b5fd;">10 minutes</strong><br>If you didn't request this, please ignore this email.</p>
      </div>
      <div style="margin-top:28px;padding:18px 20px;border:1px solid #2d2f55;border-radius:18px;background:#121326;">
        <p style="margin:0 0 10px;color:#ffffff;font-size:14px;font-weight:700;">🔒 Security Tips</p>
        <p style="margin:0;color:#cbd5e1;font-size:13px;line-height:1.8;">• Never share your verification code<br>• Pictogram will never ask for your password via email<br>• Enable two-factor authentication in app settings</p>
      </div>
    `,
  });
}

// Password Reset Template
function passwordResetTemplate({ userName, resetLink }) {
  return baseTemplate({
    title: "Password Reset 🔑",
    previewText: "We received a request to reset your password",
    bodyContent: `
      <p style="margin:0 0 16px;color:#ffffff;font-size:16px;line-height:1.8;">Hi ${userName},</p>
      <p style="margin:0 0 18px;color:#cbd5e1;font-size:15px;line-height:1.9;">Someone (hopefully you) requested a password reset for your Pictogram account. Click the button below to set a new password. This link expires in <strong style="color:#ffffff;">1 hour</strong>.</p>
      <table role="presentation" cellspacing="0" cellpadding="0" style="margin:28px 0;width:100%;">
        <tr>
          <td align="center" bgcolor="#8b5cf6" style="border-radius:14px;">
            <a href="${resetLink}" style="display:inline-block;padding:14px 26px;color:#ffffff;text-decoration:none;font-weight:700;font-size:15px;">Reset Password</a>
          </td>
        </tr>
      </table>
      <p style="margin:20px 0 0;color:#94a3b8;font-size:13px;line-height:1.6;">Can't click the button? Copy and paste this link into your browser:</p>
      <p style="margin:8px 0 24px;color:#c4b5fd;font-size:12px;word-break:break-all;">${resetLink}</p>
      <div style="padding:18px 20px;border:1px solid #dc2626;border-radius:18px;background:#450a0a;margin-top:12px;">
        <p style="margin:0 0 8px;color:#fca5a5;font-size:14px;font-weight:700;">⚠️ Didn't request this?</p>
        <p style="margin:0;color:#cbd5e1;font-size:13px;line-height:1.6;">If you didn't request a password reset, please <a href="mailto:${BRAND.supportEmail}" style="color:#c4b5fd;">contact support</a> immediately and secure your account by changing your password.</p>
      </div>
    `,
  });
}

// Login Alert Template
function loginAlertTemplate({ userName, loginTime, deviceName, location }) {
  return baseTemplate({
    title: "New Login Detected",
    previewText: "We noticed a login from a new device",
    bodyContent: `
      <p style="margin:0 0 14px;color:#ffffff;font-size:16px;">Hi ${userName},</p>
      <p style="margin:0 0 18px;color:#cbd5e1;font-size:15px;line-height:1.9;">We noticed a login to your Pictogram account from a new device or browser.</p>
      <div style="padding:18px 20px;background:#0b0d1a;border:1px solid #31355f;border-radius:18px;">
        <p style="margin:0 0 8px;color:#ffffff;font-size:14px;font-weight:700;">Login details</p>
        <p style="margin:0;color:#cbd5e1;font-size:14px;line-height:1.8;">Time: ${loginTime}<br>Device: ${deviceName}<br>Location: ${location}</p>
      </div>
      <p style="margin:18px 0 0;color:#cbd5e1;font-size:14px;line-height:1.8;">If this was you, no action is needed. If not, reset your password immediately.</p>
      <table role="presentation" cellspacing="0" cellpadding="0" style="margin:26px 0 0;">
        <tr>
          <td bgcolor="#ef4444" style="border-radius:14px;">
            <a href="${BRAND.appUrl}/reset-password" style="display:inline-block;padding:14px 24px;color:#ffffff;text-decoration:none;font-size:15px;font-weight:700;">Secure My Account</a>
          </td>
        </tr>
      </table>
    `,
  });
}

// Support Acknowledgement Template
function supportAckTemplate({ userName, ticketId, ticketSubject }) {
  return baseTemplate({
    title: "We've received your request",
    previewText: "Our team will review it soon",
    bodyContent: `
      <p style="margin:0 0 14px;color:#ffffff;font-size:16px;">Hi ${userName},</p>
      <p style="margin:0 0 18px;color:#cbd5e1;font-size:15px;line-height:1.9;">Thanks for contacting Pictogram Support. Your request has been received and our team will review it soon.</p>
      <div style="padding:16px 18px;background:#0b0d1a;border:1px solid #31355f;border-radius:18px;">
        <p style="margin:0;color:#cbd5e1;font-size:14px;line-height:1.8;">Ticket ID: <strong style="color:#ffffff;">${ticketId}</strong><br>Subject: ${ticketSubject}</p>
      </div>
      <p style="margin:18px 0 0;color:#94a3b8;font-size:13px;line-height:1.8;">For urgent issues, reply directly to this email.</p>
    `,
  });
}

// ==================== CORE EMAIL FUNCTIONS ====================

export async function sendEmail({ to, subject, html, text, cc, bcc }) {
  const info = await transporter.sendMail({
    from: process.env.EMAIL_FROM || `Pictogram <${BRAND.supportEmail}>`,
    to,
    cc,
    bcc,
    subject,
    html,
    text,
  });

  console.log(`Email sent: ${info.messageId}`);
  return info;
}

export async function sendWelcomeEmail(to, userName) {
  const { subject, html } = welcomeTemplate({ userName });
  return sendEmail({ to, subject, html, text: `Welcome to Pictogram, ${userName}!` });
}

export async function sendOtpEmail(to, userName, otpCode) {
  const { subject, html } = otpTemplate({ userName, otpCode });
  return sendEmail({ to, subject, html, text: `Your Pictogram verification code is ${otpCode}` });
}

export async function sendPasswordResetEmail(to, userName, resetLink) {
  const { subject, html } = passwordResetTemplate({ userName, resetLink });
  return sendEmail({ to, subject, html, text: `Reset your Pictogram password: ${resetLink}` });
}

export async function sendLoginAlertEmail(to, payload) {
  const { userName, loginTime, deviceName, location } = payload;
  const { subject, html } = loginAlertTemplate({ userName, loginTime, deviceName, location });
  return sendEmail({ to, subject, html, text: `New login detected for your Pictogram account at ${loginTime} from ${deviceName} in ${location}.` });
}

export async function sendSupportAckEmail(to, payload) {
  const { userName, ticketId, ticketSubject } = payload;
  const { subject, html } = supportAckTemplate({ userName, ticketId, ticketSubject });
  return sendEmail({ to, subject, html, text: `We received your request${ticketId ? ` (${ticketId})` : ""}.` });
}

export async function verifyEmailTransport() {
  return transporter.verify();
}

/*
Example usage:

import {
  sendWelcomeEmail,
  sendOtpEmail,
  sendPasswordResetEmail,
  verifyEmailTransport,
} from "./pictogram_email_service.js";

await verifyEmailTransport();
await sendWelcomeEmail("user@example.com", "Dhiraj");
await sendOtpEmail("user@example.com", "Dhiraj", "482193");
await sendPasswordResetEmail(
  "user@example.com",
  "Dhiraj",
  "https://pictogram.online/reset-password?token=abc123"
);
*/
