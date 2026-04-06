# Pictogram Backend Email Service

Simple Node.js email service using Nodemailer + Titan Email (or any SMTP provider).

## 🚀 Quick Start

```bash
cd backend

# Install dependencies
npm install nodemailer

# Copy environment file
cp .env.example .env

# Edit .env with your credentials
# EMAIL_PASS=your_actual_password

# Test email service
node -e "
import { verifyEmailTransport, sendWelcomeEmail } from './pictogram_email_service.js';
await verifyEmailTransport();
await sendWelcomeEmail('test@example.com', 'Test User');
"
```

## 📧 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `EMAIL_HOST` | SMTP server host | `smtp.titan.email` |
| `EMAIL_PORT` | SMTP port | `587` |
| `EMAIL_SECURE` | Use TLS | `false` |
| `EMAIL_USER` | SMTP username | `support@pictogram.online` |
| `EMAIL_PASS` | SMTP password | **Required** |
| `EMAIL_FROM` | From name/email | `Pictogram <support@pictogram.online>` |
| `APP_URL` | Your app URL | `https://pictogram.online` |

## 🔌 API Functions

```javascript
import {
  sendWelcomeEmail,
  sendOtpEmail,
  sendPasswordResetEmail,
  sendLoginAlertEmail,
  sendSupportAckEmail,
  verifyEmailTransport,
} from "./pictogram_email_service.js";

// Test connection
await verifyEmailTransport();

// Send emails
await sendWelcomeEmail("user@example.com", "Dhiraj");
await sendOtpEmail("user@example.com", "Dhiraj", "482193");
await sendPasswordResetEmail("user@example.com", "Dhiraj", "https://pictogram.online/reset?token=abc");
await sendLoginAlertEmail("user@example.com", {
  userName: "Dhiraj",
  loginTime: new Date().toLocaleString(),
  deviceName: "iPhone 15 Pro",
  location: "Mumbai, India"
});
await sendSupportAckEmail("user@example.com", {
  userName: "Dhiraj",
  ticketId: "#TICK-12345",
  ticketSubject: "Cannot upload photos"
});
```

## 🔄 Integration with Firebase Functions

If you want to use this in Firebase Functions instead:

```javascript
// In your Firebase Function
import { sendWelcomeEmail } from "./pictogram_email_service.js";

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  if (user.email) {
    await sendWelcomeEmail(user.email, user.displayName || "there");
  }
});
```

## 📨 Email Templates Included

1. **Welcome Email** - Onboarding new users
2. **OTP Verification** - 6-digit codes with 10-min expiry
3. **Password Reset** - Secure reset links with 1-hour expiry
4. **Login Alert** - Security notifications for new devices
5. **Support Acknowledgement** - Ticket confirmation

## 🛡️ Security Notes

- Never commit `.env` to git
- Use app-specific passwords for email accounts
- Enable 2FA on your email provider
- Rate limit email sending in production
- Log all sent emails for audit trail

## 💡 Alternative SMTP Providers

| Provider | Host | Notes |
|----------|------|-------|
| **Titan Email** | `smtp.titan.email` | Included with Namecheap domains |
| **Gmail** | `smtp.gmail.com` | Use App Password, not login password |
| **Outlook** | `smtp.office365.com` | Modern auth required |
| **Zoho** | `smtp.zoho.com` | Free tier available |

---

**Ready to send emails!** 📧
