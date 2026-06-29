import 'dotenv/config';
import nodemailer from 'nodemailer';

console.log('=== NODEMAILER TEST SCRIPT ===');
console.log('SMTP_HOST:', process.env.SMTP_HOST || '(not set)');
console.log('SMTP_PORT:', process.env.SMTP_PORT || '(not set)');
console.log('SMTP_SECURE:', process.env.SMTP_SECURE || '(not set)');
const user = process.env.SMTP_USER || '(not set)';
console.log('SMTP_USER:', user === '(not set)' ? '(not set)' : user.substring(0, 5) + '...@' + user.split('@')[1]);
console.log('SMTP_PASS set:', process.env.SMTP_PASS ? 'YES (' + process.env.SMTP_PASS.length + ' chars)' : 'NO');
console.log('SMTP_FROM:', process.env.SMTP_FROM || '(not set)');
console.log('');

// Test 1: Verify transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

console.log('Test 1: Verifying SMTP connection...');
transporter.verify((err) => {
  if (err) {
    console.log('FAILED:', err.message);
    console.log('Response code:', (err as any).responseCode);
    console.log('Response:', (err as any).response);
    console.log('');
    console.log('Common causes:');
    console.log('  1. SMTP_USER is not your real Gmail address (still placeholder)');
    console.log('  2. SMTP_PASS is not a valid 16-char App Password');
    console.log('  3. 2FA is not enabled on your Google account (App Passwords require 2FA)');
    console.log('  4. The App Password was revoked or expired');
    console.log('');
    console.log('Fix: Edit backend/.env and set your real Gmail + App Password, then restart the server.');
    return;
  }
  console.log('PASSED! Transporter is ready.');

  // Test 2: Send a test email
  console.log('');
  console.log('Test 2: Sending a test email to ' + process.env.SMTP_USER + '...');
  transporter.sendMail({
    from: `"BluexSofts POS Test" <${process.env.SMTP_USER}>`,
    to: process.env.SMTP_USER,
    subject: 'Test email from BluexSofts POS',
    text: 'If you receive this, nodemailer is working correctly!',
  }, (err2, info) => {
    if (err2) {
      console.log('FAILED:', err2.message);
      return;
    }
    console.log('PASSED! Email sent. Message ID:', info.messageId);
  });
});
