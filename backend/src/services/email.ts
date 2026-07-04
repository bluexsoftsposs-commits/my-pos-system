import nodemailer from 'nodemailer';
import * as fs from 'fs';
import * as zlib from 'zlib';
import { promisify } from 'util';

const gzip = promisify(zlib.gzip);

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

export async function sendInvoiceEmail(
  toEmail: string,
  saleDetails: {
    shopName: string;
    invoiceNumber: string;
    items: { name: string; qty: number; price: number }[];
    subtotal: number;
    tax: number;
    discount: number;
    total: number;
    paymentMethod: string;
    date: string;
  }
): Promise<void> {
  const itemRows = saleDetails.items
    .map(
      (i) =>
        `<tr style="border-bottom:1px solid #eee;">
          <td style="padding:8px 4px">${i.name}</td>
          <td style="padding:8px 4px;text-align:center">${i.qty}</td>
          <td style="padding:8px 4px;text-align:right">PKR ${i.price.toFixed(2)}</td>
          <td style="padding:8px 4px;text-align:right">PKR ${(i.price * i.qty).toFixed(2)}</td>
        </tr>`
    )
    .join('');

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background:#6C5CE7;padding:20px;text-align:center;border-radius:12px 12px 0 0;">
        <h1 style="color:#fff;margin:0;font-size:22px;">${saleDetails.shopName}</h1>
        <p style="color:#C6BFFF;margin:4px 0 0;">Invoice #${saleDetails.invoiceNumber}</p>
      </div>
      <div style="background:#f8f9fd;padding:24px;border-radius:0 0 12px 12px;">
        <p style="color:#666;font-size:14px;">Date: ${saleDetails.date}</p>
        <p style="color:#666;font-size:14px;">Payment: ${saleDetails.paymentMethod}</p>
        <table style="width:100%;border-collapse:collapse;margin-top:16px;">
          <thead>
            <tr style="background:#6C5CE7;color:#fff;">
              <th style="padding:8px 4px;text-align:left;">Item</th>
              <th style="padding:8px 4px;">Qty</th>
              <th style="padding:8px 4px;text-align:right;">Price</th>
              <th style="padding:8px 4px;text-align:right;">Total</th>
            </tr>
          </thead>
          <tbody>${itemRows}</tbody>
        </table>
        <hr style="border:none;border-top:2px solid #6C5CE7;margin:16px 0;" />
        <div style="text-align:right;">
          ${saleDetails.tax > 0 ? `<p style="margin:4px 0;">Subtotal: PKR ${saleDetails.subtotal.toFixed(2)}</p>` : ''}
          ${saleDetails.tax > 0 ? `<p style="margin:4px 0;">Tax: PKR ${saleDetails.tax.toFixed(2)}</p>` : ''}
          ${saleDetails.discount > 0 ? `<p style="margin:4px 0;color:#e74c3c;">Discount: -PKR ${saleDetails.discount.toFixed(2)}</p>` : ''}
          <h2 style="margin:8px 0;color:#6C5CE7;">Total: PKR ${saleDetails.total.toFixed(2)}</h2>
        </div>
        <p style="color:#999;font-size:12px;text-align:center;margin-top:24px;">Thank you for your business!</p>
      </div>
    </div>`;

  try {
    const info = await transporter.sendMail({
      from: `"BluexSofts POS" <${process.env.SMTP_FROM || process.env.SMTP_USER}>`,
      to: toEmail,
      subject: `Invoice #${saleDetails.invoiceNumber} — ${saleDetails.shopName}`,
      html,
    });
    console.log('[Email] Invoice sent successfully:', info.messageId);
  } catch (error: any) {
    console.error('[Email] Failed to send invoice:', error.message);
  }
}

export async function sendBackupEmail(filepath: string, filename: string): Promise<void> {
  const recipient = process.env.BACKUP_EMAIL_TO || process.env.SMTP_USER || '';
  if (!recipient) {
    console.error('[BackupEmail] No recipient configured (BACKUP_EMAIL_TO or SMTP_USER)');
    return;
  }

  let rawBuffer: Buffer;
  try {
    rawBuffer = fs.readFileSync(filepath);
  } catch {
    console.error(`[BackupEmail] File not found: ${filepath}`);
    return;
  }

  const rawSizeMb = (rawBuffer.length / 1024 / 1024).toFixed(2);
  const compressed = await gzip(rawBuffer);
  const compressedSizeMb = (compressed.length / 1024 / 1024).toFixed(2);
  const ratio = rawBuffer.length > 0 ? ((1 - compressed.length / rawBuffer.length) * 100).toFixed(0) : '0';
  const dateStr = new Date().toISOString().slice(0, 10);
  const gzFilename = filename.replace(/\.sql$/, '') + '.sql.gz';

  if (compressed.length < 20 * 1024 * 1024) {
    console.log(`[BackupEmail] Sending compressed backup (${rawSizeMb} MB → ${compressedSizeMb} MB, ${ratio}% reduction) to ${recipient}...`);
    try {
      const info = await transporter.sendMail({
        from: `"BluexSofts POS" <${process.env.SMTP_FROM || process.env.SMTP_USER}>`,
        to: recipient,
        subject: `BluexSofts POS - Daily Backup - ${dateStr} - Success`,
        text: [
          `Database backup completed successfully.`,
          ``,
          `File: ${gzFilename}`,
          `Raw size: ${rawSizeMb} MB`,
          `Compressed size: ${compressedSizeMb} MB (${ratio}% reduction)`,
          `Date: ${dateStr}`,
          ``,
          `Uncompress locally with: gunzip ${gzFilename}`,
          `Then restore with: npm run db:restore ${filename}`,
        ].join('\n'),
        attachments: [{ filename: gzFilename, content: compressed }],
      });
      console.log(`[BackupEmail] Sent successfully: ${info.messageId}`);
    } catch (error: any) {
      console.error('[BackupEmail] Failed to send:', error.message);
    }
  } else {
    console.log(`[BackupEmail] Compressed backup still too large (${compressedSizeMb} MB) — sending warning.`);
    try {
      const info = await transporter.sendMail({
        from: `"BluexSofts POS" <${process.env.SMTP_FROM || process.env.SMTP_USER}>`,
        to: recipient,
        subject: `BluexSofts POS - Daily Backup - ${dateStr} - Oversized`,
        text: [
          `WARNING: Backup completed but compressed file (${compressedSizeMb} MB) still exceeds 20MB email limit.`,
          ``,
          `Raw file: ${filename} (${rawSizeMb} MB)`,
          `Compressed: ${gzFilename} (${compressedSizeMb} MB, ${ratio}% reduction)`,
          `Date: ${dateStr}`,
          ``,
          `The backup file was saved locally on Render's disk but could not be emailed.`,
          `Manually retrieve it before the next deploy wipes it.`,
          ``,
          `To download: use Render Shell or SFTP to fetch: backups/${filename}`,
        ].join('\n'),
      });
      console.log(`[BackupEmail] Warning sent: ${info.messageId}`);
    } catch (error: any) {
      console.error('[BackupEmail] Failed to send warning:', error.message);
    }
  }
}
