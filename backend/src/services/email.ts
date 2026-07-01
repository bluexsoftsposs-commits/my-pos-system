import nodemailer from 'nodemailer';

console.log('[Email] SMTP_USER:', process.env.SMTP_USER ? process.env.SMTP_USER.substring(0, 5) + '...' : 'NOT SET');
console.log('[Email] SMTP_PASS:', process.env.SMTP_PASS ? '*** set (' + process.env.SMTP_PASS.length + ' chars) ***' : 'NOT SET');
console.log('[Email] SMTP_HOST:', process.env.SMTP_HOST);
console.log('[Email] SMTP_PORT:', process.env.SMTP_PORT);

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

transporter.verify((err) => {
  if (err) {
    console.error('[Email] Transporter verification FAILED:', err.message);
    console.error('[Email] Check your SMTP_USER and SMTP_PASS in .env');
  } else {
    console.log('[Email] Transporter is ready to send emails');
  }
});

export async function sendVerificationEmail(email: string, token: string): Promise<void> {
  const verifyUrl = `${process.env.APP_URL || 'https://my-pos-system-2.onrender.com'}/api/auth/verify-email?token=${token}`;

  console.log(`[Email] Sending verification to: ${email}`);
  console.log(`[Email] Token: ${token.substring(0, 16)}...`);
  console.log(`[Email] Verify URL: ${verifyUrl}`);

  try {
    const info = await transporter.sendMail({
      from: `"BluexSofts POS" <${process.env.SMTP_FROM || process.env.SMTP_USER}>`,
      to: email,
      subject: 'Verify your email address',
      html: `
        <h2>Welcome to BluexSofts POS!</h2>
        <p>Please verify your email address by clicking the link below:</p>
        <a href="${verifyUrl}" style="display:inline-block;padding:12px 24px;background:#4F46E5;color:#fff;text-decoration:none;border-radius:6px;">Verify Email</a>
        <p>Or copy this link: <a href="${verifyUrl}">${verifyUrl}</a></p>
        <p>This link expires in 24 hours.</p>
      `,
    });
    console.log('[Email] Verification sent successfully:', info.messageId);
  } catch (error: any) {
    console.error('[Email] Failed to send verification:', error.message);
    console.error('[Email] Full error:', error);
    throw error;
  }
}

export async function sendPasswordResetEmail(email: string, token: string): Promise<void> {
  const resetUrl = `${process.env.APP_URL || 'https://my-pos-system-2.onrender.com'}/reset-password?token=${token}`;

  console.log(`[Email] Sending password reset to: ${email}`);
  console.log(`[Email] Token: ${token.substring(0, 16)}...`);
  console.log(`[Email] Reset URL: ${resetUrl}`);

  try {
    const info = await transporter.sendMail({
      from: `"BluexSofts POS" <${process.env.SMTP_FROM || process.env.SMTP_USER}>`,
      to: email,
      subject: 'Reset your password',
      html: `
        <h2>Password Reset Request</h2>
        <p>Click the link below to reset your password:</p>
        <a href="${resetUrl}" style="display:inline-block;padding:12px 24px;background:#4F46E5;color:#fff;text-decoration:none;border-radius:6px;">Reset Password</a>
        <p>Or copy this link: <a href="${resetUrl}">${resetUrl}</a></p>
        <p>Your reset token: <strong>${token}</strong></p>
        <p>This link expires in 1 hour.</p>
        <p>If you did not request this, please ignore this email.</p>
      `,
    });
    console.log('[Email] Password reset sent successfully:', info.messageId);
  } catch (error: any) {
    console.error('[Email] Failed to send password reset:', error.message);
    console.error('[Email] Full error:', error);
    throw error;
  }
}
