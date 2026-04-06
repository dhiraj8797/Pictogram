import express from "express";
import bcrypt from "bcryptjs";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import {
  sendWelcomeEmail,
  sendOtpEmail,
  sendPasswordResetEmail,
} from "./pictogram_email_service.js";

const router = express.Router();

// Helper: Generate secure random OTP
function generateOtp(length = 6) {
  const digits = "0123456789";
  let otp = "";
  for (let i = 0; i < length; i++) {
    otp += digits[crypto.randomInt(0, digits.length)];
  }
  return otp;
}

// Helper: Hash value using SHA-256
function hashValue(value) {
  return crypto.createHash("sha256").update(value).digest("hex");
}

// ==================== AUTH ROUTES ====================

// SIGNUP + SEND OTP
router.post("/signup", async (req, res) => {
  try {
    const { name, username, email, password } = req.body;

    if (!name || !username || !email || !password) {
      return res.status(400).json({ message: "All fields are required." });
    }

    // Check if user exists
    const existingUser = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { username: username.toLowerCase() }],
    });

    if (existingUser) {
      return res.status(409).json({
        message: existingUser.email === email.toLowerCase()
          ? "Email already registered."
          : "Username already taken.",
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 12);

    // Generate OTP
    const rawOtp = generateOtp();
    const hashedOtp = hashValue(rawOtp);
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Create user
    const user = await User.create({
      name,
      username: username.toLowerCase(),
      email: email.toLowerCase(),
      password: hashedPassword,
      isEmailVerified: false,
      emailOtpCode: hashedOtp,
      emailOtpExpiresAt: otpExpires,
    });

    // Send OTP email
    await sendOtpEmail(user.email, user.name, rawOtp);

    return res.status(201).json({
      message: "Account created. Check your email for verification code.",
      userId: user._id,
    });
  } catch (error) {
    console.error("Signup error:", error);
    return res.status(500).json({ message: "Failed to create account." });
  }
});

// VERIFY EMAIL + SEND WELCOME
router.post("/verify-email", async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ message: "Email and OTP are required." });
    }

    const hashedOtp = hashValue(otp);

    const user = await User.findOne({
      email: email.toLowerCase(),
      emailOtpCode: hashedOtp,
      emailOtpExpiresAt: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ message: "Invalid or expired OTP." });
    }

    // Verify email
    user.isEmailVerified = true;
    user.emailOtpCode = undefined;
    user.emailOtpExpiresAt = undefined;
    await user.save();

    // Send welcome email
    await sendWelcomeEmail(user.email, user.name);

    // Generate JWT
    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.status(200).json({
      message: "Email verified successfully.",
      token,
      user: {
        id: user._id,
        name: user.name,
        username: user.username,
        email: user.email,
        isEmailVerified: true,
      },
    });
  } catch (error) {
    console.error("Verify email error:", error);
    return res.status(500).json({ message: "Email verification failed." });
  }
});

// RESEND OTP
router.post("/resend-otp", async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required." });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      return res.status(404).json({ message: "User not found." });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: "Email already verified." });
    }

    // Generate new OTP
    const rawOtp = generateOtp();
    const hashedOtp = hashValue(rawOtp);
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000);

    user.emailOtpCode = hashedOtp;
    user.emailOtpExpiresAt = otpExpires;
    await user.save();

    // Send OTP email
    await sendOtpEmail(user.email, user.name, rawOtp);

    return res.status(200).json({ message: "New OTP sent to your email." });
  } catch (error) {
    console.error("Resend OTP error:", error);
    return res.status(500).json({ message: "Failed to resend OTP." });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required." });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ message: "Invalid email or password." });
    }

    if (!user.isEmailVerified) {
      return res.status(403).json({
        message: "Please verify your email first.",
        needsVerification: true,
      });
    }

    const token = jwt.sign(
      { userId: user._id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.status(200).json({
      message: "Login successful.",
      token,
      user: {
        id: user._id,
        name: user.name,
        username: user.username,
        email: user.email,
        isEmailVerified: true,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    return res.status(500).json({ message: "Login failed." });
  }
});

// FORGOT PASSWORD
router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required." });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    // Always return success to prevent email enumeration
    if (!user || !user.isEmailVerified) {
      return res.status(200).json({
        message: "If that email exists, a reset link has been sent.",
      });
    }

    // Generate reset token
    const rawToken = crypto.randomBytes(32).toString("hex");
    const hashedToken = hashValue(rawToken);
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    user.passwordResetToken = hashedToken;
    user.passwordResetExpiresAt = expiresAt;
    await user.save();

    const resetLink = `${process.env.APP_URL}/reset-password?token=${rawToken}&email=${encodeURIComponent(user.email)}`;

    await sendPasswordResetEmail(user.email, user.name, resetLink);

    return res.status(200).json({
      message: "If that email exists, a reset link has been sent.",
    });
  } catch (error) {
    console.error("Forgot password error:", error);
    return res.status(500).json({
      message: "Failed to process forgot password request.",
    });
  }
});

// RESET PASSWORD
router.post("/reset-password", async (req, res) => {
  try {
    const { email, token, newPassword } = req.body;

    if (!email || !token || !newPassword) {
      return res.status(400).json({
        message: "Email, token, and new password are required.",
      });
    }

    const hashedToken = hashValue(token);

    const user = await User.findOne({
      email: email.toLowerCase(),
      passwordResetToken: hashedToken,
      passwordResetExpiresAt: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ message: "Invalid or expired reset link." });
    }

    user.password = await bcrypt.hash(newPassword, 12);
    user.passwordResetToken = undefined;
    user.passwordResetExpiresAt = undefined;
    await user.save();

    return res.status(200).json({ message: "Password reset successful." });
  } catch (error) {
    console.error("Reset password error:", error);
    return res.status(500).json({ message: "Password reset failed." });
  }
});

export default router;

/*
Example User schema fields needed:

name: String,
username: { type: String, unique: true },
email: { type: String, unique: true },
password: String,
isEmailVerified: { type: Boolean, default: false },
emailOtpCode: String,
emailOtpExpiresAt: Date,
passwordResetToken: String,
passwordResetExpiresAt: Date,

How to mount:
import authRoutes from "./pictogram_auth_email_integration.js";
app.use("/api/auth", authRoutes);

Recommended env vars:
JWT_SECRET=your_jwt_secret
APP_URL=https://pictogram.online
EMAIL_HOST=smtp.titan.email
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=support@pictogram.online
EMAIL_PASS=your_email_password
EMAIL_FROM="Pictogram <support@pictogram.online>"
*/
