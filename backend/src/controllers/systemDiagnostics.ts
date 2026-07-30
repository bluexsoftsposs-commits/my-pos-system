import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../config/db';
import {
  isMaintenanceMode,
  setMaintenanceMode,
  rotateJwtSecret,
  restoreJwtSecret,
} from '../services/systemStateService';
import { runBackup, executeBackupCycle } from '../services/backup-scheduler';
import fs from 'fs';
import path from 'path';
import nodemailer from 'nodemailer';

const AUDIT_LOG_DIR = path.resolve(__dirname, '..', '..', 'backups');
const AUDIT_LOG_FILE = path.join(AUDIT_LOG_DIR, 'system_diagnostics_audit.log');

function getSystemDiagnosticsJwtSecret(): string {
  return process.env.EMERGENCY_JWT_SECRET || process.env.JWT_SECRET || 'fallback-secret';
}

function auditLog(message: string): void {
  const ts = new Date().toISOString();
  const line = `[${ts}] ${message}`;
  console.log(line);
  try {
    if (!fs.existsSync(AUDIT_LOG_DIR)) {
      fs.mkdirSync(AUDIT_LOG_DIR, { recursive: true });
    }
    fs.appendFileSync(AUDIT_LOG_FILE, line + '\n');
  } catch {
  }
}

async function sendAlert(subject: string, body: string): Promise<void> {
  const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  const recipient = process.env.SMTP_USER || '';
  if (!recipient) {
    console.error('[Alert] No SMTP_USER configured — cannot send email alert');
    return;
  }

  try {
    await transporter.sendMail({
      from: `"BluexSofts POS Alert" <${process.env.SMTP_FROM || process.env.SMTP_USER}>`,
      to: recipient,
      subject: `[ALERT] ${subject}`,
      text: body,
      html: `<pre style="font-family: monospace; background: #1a1a2e; color: #e94560; padding: 20px; border-radius: 8px;">${body}</pre>`,
    });
    console.log('[Alert] Email sent successfully');
  } catch (error: any) {
    console.error('[Alert] Failed to send email:', error.message);
  }
}

export async function systemDiagnosticsLogin(req: Request, res: Response): Promise<void> {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      res.status(400).json({ error: 'Email and password are required' });
      return;
    }

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const roleMap: Record<string, string> = {
      'SUPER_ADMIN': 'SuperAdmin',
      'ADMIN': 'Admin',
      'SUB_ADMIN': 'SubAdmin',
      'SUPPLIER': 'Supplier',
    };
    const normalizedRole = roleMap[user.role] || user.role;

    if (normalizedRole !== 'SuperAdmin') {
      res.status(403).json({ error: 'Super admin access required' });
      return;
    }

    const token = jwt.sign(
      { userId: user.id, shopId: user.shopId, role: user.role, email: user.email },
      getSystemDiagnosticsJwtSecret(),
      { expiresIn: '1h' },
    );

    res.json({ token, name: user.name });
  } catch (error: any) {
    console.error('[SystemDiagnosticsLogin] Error:', error.message);
    res.status(500).json({ error: 'Internal server error' });
  }
}

export async function systemDiagnosticsStatus(_req: Request, res: Response): Promise<void> {
  res.json({
    maintenanceMode: isMaintenanceMode(),
    timestamp: new Date().toISOString(),
  });
}

export async function softLock(req: Request, res: Response): Promise<void> {
  try {
    auditLog(`SOFT LOCK initiated by user ${req.user?.email} from IP ${req.ip}`);

    try {
      const backupResult = await runBackup();
      auditLog(`Pre-lock backup created: ${backupResult.filename} (${backupResult.sizeMb} MB)`);
    } catch (backupErr: any) {
      auditLog(`Pre-lock backup failed (non-fatal): ${backupErr.message}`);
    }

    await rotateJwtSecret();

    await prisma.user.updateMany({
      data: { currentSessionToken: null },
    });

    await setMaintenanceMode(true);

    auditLog('SOFT LOCK completed — all sessions invalidated, maintenance mode enabled');

    await sendAlert(
      'Soft Lock Activated',
      [
        `Action: Soft Lock (Maintenance Mode)`,
        `Timestamp: ${new Date().toISOString()}`,
        `Initiated by: ${req.user?.email}`,
        `Source IP: ${req.ip}`,
        ``,
        `All user sessions have been invalidated.`,
        `Maintenance mode is now enabled — all API requests are blocked.`,
        `Use the emergency panel to disable maintenance mode when ready.`,
      ].join('\n'),
    );

    res.json({ success: true, message: 'Soft lock activated. All sessions invalidated, maintenance mode enabled.' });
  } catch (error: any) {
    console.error('[SoftLock] Error:', error.message);
    auditLog(`SOFT LOCK FAILED: ${error.message}`);
    res.status(500).json({ error: 'Soft lock failed' });
  }
}

export async function hardDelete(req: Request, res: Response): Promise<void> {
  try {
    const clientIp = req.ip || req.socket.remoteAddress || 'unknown';
    auditLog(`HARD DELETE initiated by user ${req.user?.email} from IP ${clientIp}`);

    await sendAlert(
      'HARD DELETE Initiated',
      [
        `Action: Hard Delete (Database Wipe)`,
        `Timestamp: ${new Date().toISOString()}`,
        `Initiated by: ${req.user?.email}`,
        `Source IP: ${clientIp}`,
        ``,
        `WARNING: All data is being permanently deleted.`,
        `A final backup is being created.`,
      ].join('\n'),
    );

    try {
      const result = await executeBackupCycle();
      auditLog(`Final backup completed before wipe. Cloudinary: ${result.cloudinaryUrl || 'N/A'}, email sent: ${result.emailSent}`);
    } catch (backupErr: any) {
      auditLog(`Final backup before wipe FAILED: ${backupErr.message}`);
    }

    const tableOrder = [
      'PasswordResetToken',
      'PendingApproval',
      'SubAdmin',
      'SupplierTransaction',
      'Supplier',
      'OnlineOrderItem',
      'OnlineOrder',
      'LedgerEntry',
      'SaleItem',
      'Invoice',
      'Sale',
      'AuditLog',
      'Customer',
      'Branch',
      'Product',
      'User',
      'Payment',
      'ShopSubscription',
      'Shop',
      'Plan',
    ];

    for (const table of tableOrder) {
      try {
        const model = (prisma as any)[table.charAt(0).toLowerCase() + table.slice(1)];
        if (model && typeof model.deleteMany === 'function') {
          const result = await model.deleteMany({ where: {} });
          auditLog(`  Cleared ${table}: ${result.count} rows deleted`);
        }
      } catch (tableErr: any) {
        auditLog(`  Failed to clear ${table}: ${tableErr.message}`);
      }
    }

    await setMaintenanceMode(false);

    await sendAlert(
      'HARD DELETE Completed — All Data Wiped',
      [
        `Action: Hard Delete (Database Wipe)`,
        `Timestamp: ${new Date().toISOString()}`,
        `Initiated by: ${req.user?.email}`,
        `Source IP: ${clientIp}`,
        ``,
        `ALL DATA HAS BEEN PERMANENTLY DELETED.`,
        `A final backup was created before deletion (check Cloudinary + email).`,
        `Maintenance mode has been disabled so the app can still function with an empty DB.`,
      ].join('\n'),
    );

    res.json({ success: true, message: 'Hard delete completed. All data has been permanently deleted.' });
  } catch (error: any) {
    console.error('[HardDelete] Error:', error.message);
    auditLog(`HARD DELETE FAILED: ${error.message}`);
    res.status(500).json({ error: 'Hard delete failed' });
  }
}

export async function disableMaintenance(req: Request, res: Response): Promise<void> {
  try {
    await restoreJwtSecret();
    await setMaintenanceMode(false);

    auditLog(`Maintenance mode disabled by ${req.user?.email} from IP ${req.ip}`);

    await sendAlert(
      'Maintenance Mode Disabled',
      [
        `Action: Disable Maintenance Mode`,
        `Timestamp: ${new Date().toISOString()}`,
        `Initiated by: ${req.user?.email}`,
        `Source IP: ${req.ip}`,
        ``,
        `The system has been restored to normal operation.`,
        `All API requests are now accepted. Users will need to log in again.`,
      ].join('\n'),
    );

    res.json({ success: true, message: 'Maintenance mode disabled. System恢复正常.' });
  } catch (error: any) {
    console.error('[DisableMaintenance] Error:', error.message);
    res.status(500).json({ error: 'Failed to disable maintenance mode' });
  }
}

export async function serveEmergencyPanel(_req: Request, res: Response): Promise<void> {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Emergency Control</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Courier New', monospace; background: #0a0a0f; color: #e0e0e0; min-height: 100vh; display: flex; align-items: center; justify-content: center; }
  .container { background: #12121a; border: 1px solid #2a2a3a; border-radius: 12px; padding: 40px; width: 520px; box-shadow: 0 0 60px rgba(233,69,96,0.1); }
  h1 { color: #e94560; font-size: 20px; text-align: center; margin-bottom: 8px; letter-spacing: 2px; text-transform: uppercase; }
  .subtitle { text-align: center; color: #666; font-size: 12px; margin-bottom: 32px; }
  .form-group { margin-bottom: 16px; }
  label { display: block; font-size: 12px; color: #888; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 1px; }
  input { width: 100%; padding: 10px 14px; background: #1a1a2e; border: 1px solid #2a2a3a; border-radius: 6px; color: #e0e0e0; font-family: 'Courier New', monospace; font-size: 14px; }
  input:focus { outline: none; border-color: #e94560; }
  .btn { width: 100%; padding: 12px; border: none; border-radius: 6px; font-family: 'Courier New', monospace; font-size: 13px; font-weight: bold; cursor: pointer; text-transform: uppercase; letter-spacing: 1px; margin-top: 8px; transition: all 0.2s; }
  .btn:disabled { opacity: 0.4; cursor: not-allowed; }
  .btn-soft { background: #e67e22; color: #fff; }
  .btn-soft:hover:not(:disabled) { background: #d35400; }
  .btn-hard { background: #c0392b; color: #fff; }
  .btn-hard:hover:not(:disabled) { background: #922b21; }
  .btn-disable { background: #27ae60; color: #fff; }
  .btn-disable:hover:not(:disabled) { background: #1e8449; }
  .btn-login { background: #6C5CE7; color: #fff; }
  .btn-login:hover:not(:disabled) { background: #5a4bd1; }
  .status { margin-top: 20px; padding: 12px; background: #1a1a2e; border-radius: 6px; font-size: 12px; color: #888; }
  .status.on { border-left: 3px solid #e94560; color: #e94560; }
  .status.off { border-left: 3px solid #27ae60; color: #27ae60; }
  .msg { margin-top: 12px; padding: 10px; border-radius: 6px; font-size: 12px; display: none; }
  .msg.error { display: block; background: #2c0a0a; border: 1px solid #e94560; color: #e94560; }
  .msg.success { display: block; background: #0a2c0a; border: 1px solid #27ae60; color: #27ae60; }
  .confirm-text { color: #e94560; font-size: 11px; margin-top: 6px; }
  .section { margin-top: 24px; padding-top: 24px; border-top: 1px solid #2a2a3a; }
  .hidden { display: none; }
  .loading { text-align: center; color: #666; font-size: 12px; margin-top: 10px; }
</style>
</head>
<body>
<div class="container" id="app">
  <h1>EMERGENCY CONTROL</h1>
  <p class="subtitle">Disaster Recovery — Authorized Personnel Only</p>

  <div id="login-view">
    <div class="form-group">
      <label>Email</label>
      <input type="email" id="email" placeholder="superadmin email" autocomplete="off">
    </div>
    <div class="form-group">
      <label>Password</label>
      <input type="password" id="password" placeholder="password" autocomplete="off">
    </div>
    <button class="btn btn-login" id="login-btn" onclick="login()">Authenticate</button>
    <div id="login-error" class="msg error"></div>
    <div class="loading" id="login-loading" style="display:none;">Verifying...</div>
  </div>

  <div id="panel-view" class="hidden">
    <div class="status off" id="status-bar">Checking status...</div>

    <div class="section">
      <button class="btn btn-soft" id="soft-lock-btn" onclick="confirmSoftLock()">🔒 Soft Lock — Maintenance Mode</button>
      <div id="soft-lock-confirm" class="hidden" style="margin-top:12px;">
        <p style="color:#e67e22;font-size:12px;margin-bottom:8px;">This will log out ALL users and block ALL API access. Continue?</p>
        <button class="btn btn-soft" onclick="executeSoftLock()" style="font-size:11px;">Yes, Activate Soft Lock</button>
        <button class="btn" onclick="cancelSoftLock()" style="background:#444;font-size:11px;">Cancel</button>
      </div>
    </div>

    <div class="section">
      <div class="form-group">
        <label>Type confirmation phrase to enable Hard Delete</label>
        <input type="text" id="confirm-phrase" placeholder="DELETE EVERYTHING" oninput="checkHardDeleteReady()" autocomplete="off">
      </div>
      <button class="btn btn-hard" id="hard-delete-btn" disabled onclick="confirmHardDelete()">💀 Hard Delete — Wipe All Data</button>
      <div id="hard-delete-confirm" class="hidden" style="margin-top:12px;">
        <p style="color:#c0392b;font-size:12px;margin-bottom:8px;">⚠️ FINAL WARNING: This is IRREVERSIBLE. All data will be permanently destroyed. A final backup will be taken first.</p>
        <button class="btn btn-hard" onclick="executeHardDelete()" style="font-size:11px;">Yes, Destroy Everything</button>
        <button class="btn" onclick="cancelHardDelete()" style="background:#444;font-size:11px;">Cancel</button>
      </div>
    </div>

    <div class="section">
      <button class="btn btn-disable" id="disable-btn" onclick="executeDisableMaintenance()">✅ Disable Maintenance Mode</button>
    </div>

    <div id="action-msg" class="msg"></div>
    <div class="loading" id="action-loading" style="display:none;">Processing...</div>
  </div>
</div>

<script>
let token = '';
const API_BASE = window.location.pathname.replace(/\\/+$/, '');

async function api(method, path, body) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = 'Bearer ' + token;
  const res = await fetch(API_BASE + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const data = await res.json();
  if (!res.ok) throw new Error(data.error || 'Request failed');
  return data;
}

function showMsg(el, text, type) {
  el.textContent = text;
  el.className = 'msg ' + type;
}

async function login() {
  const email = document.getElementById('email').value;
  const password = document.getElementById('password').value;
  const btn = document.getElementById('login-btn');
  const loading = document.getElementById('login-loading');
  const errEl = document.getElementById('login-error');
  if (!email || !password) { showMsg(errEl, 'Email and password required', 'error'); return; }
  btn.disabled = true;
  loading.style.display = 'block';
  errEl.className = 'msg';
  try {
    const data = await api('POST', '/login', { email, password });
    token = data.token;
    document.getElementById('login-view').classList.add('hidden');
    document.getElementById('panel-view').classList.remove('hidden');
    refreshStatus();
  } catch (e) {
    showMsg(errEl, e.message, 'error');
  } finally {
    btn.disabled = false;
    loading.style.display = 'none';
  }
}

async function refreshStatus() {
  try {
    const data = await api('GET', '/status');
    const bar = document.getElementById('status-bar');
    bar.textContent = data.maintenanceMode ? 'MAINTENANCE MODE: ON' : 'System: Normal';
    bar.className = 'status ' + (data.maintenanceMode ? 'on' : 'off');
  } catch {}
}

function checkHardDeleteReady() {
  const phrase = document.getElementById('confirm-phrase').value;
  document.getElementById('hard-delete-btn').disabled = phrase !== 'DELETE EVERYTHING';
}

function confirmSoftLock() {
  document.getElementById('soft-lock-confirm').classList.remove('hidden');
}
function cancelSoftLock() {
  document.getElementById('soft-lock-confirm').classList.add('hidden');
}
function confirmHardDelete() {
  document.getElementById('hard-delete-confirm').classList.remove('hidden');
}
function cancelHardDelete() {
  document.getElementById('hard-delete-confirm').classList.add('hidden');
}

async function executeSoftLock() {
  const loading = document.getElementById('action-loading');
  const msg = document.getElementById('action-msg');
  loading.style.display = 'block';
  msg.className = 'msg';
  document.getElementById('soft-lock-confirm').classList.add('hidden');
  try {
    const data = await api('POST', '/soft-lock');
    showMsg(msg, data.message, 'success');
    refreshStatus();
  } catch (e) {
    showMsg(msg, e.message, 'error');
  } finally {
    loading.style.display = 'none';
  }
}

async function executeHardDelete() {
  const loading = document.getElementById('action-loading');
  const msg = document.getElementById('action-msg');
  loading.style.display = 'block';
  msg.className = 'msg';
  document.getElementById('hard-delete-confirm').classList.add('hidden');
  try {
    const data = await api('POST', '/hard-delete');
    showMsg(msg, data.message + ' The page will reload.', 'success');
    setTimeout(() => location.reload(), 3000);
  } catch (e) {
    showMsg(msg, e.message, 'error');
  } finally {
    loading.style.display = 'none';
  }
}

async function executeDisableMaintenance() {
  const loading = document.getElementById('action-loading');
  const msg = document.getElementById('action-msg');
  loading.style.display = 'block';
  msg.className = 'msg';
  try {
    const data = await api('POST', '/disable-maintenance');
    showMsg(msg, data.message, 'success');
    refreshStatus();
  } catch (e) {
    showMsg(msg, e.message, 'error');
  } finally {
    loading.style.display = 'none';
  }
}
</script>
</body>
</html>`);
}
