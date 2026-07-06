import cron from 'node-cron';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import cloudinary from 'cloudinary';
import { sendBackupEmail } from './email';

const BACKUP_DIR = path.resolve(__dirname, '..', '..', 'backups');

// Retention: 336 backups = 7 days at 30-min intervals (48/day)
// 7 days gives a full week of point-in-time recovery, which is more useful
// than 24h for investigating issues that surfaced days later.
const RETENTION_COUNT = 336;

cloudinary.v2.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

function getTimestamp(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const h = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  const sec = String(d.getSeconds()).padStart(2, '0');
  return `${y}-${m}-${day}_${h}-${min}-${sec}`;
}

export async function runBackup(): Promise<{ filename: string; filepath: string; sizeMb: string }> {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    throw new Error('[BackupScheduler] DATABASE_URL not configured');
  }

  if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
  }

  const filename = `backup_${getTimestamp()}.sql`;
  const filepath = path.join(BACKUP_DIR, filename);

  console.log(`[BackupScheduler] Starting pg_dump...`);
  execSync(`pg_dump "${dbUrl}" --no-owner --no-acl -f "${filepath}"`, {
    timeout: 300_000,
  });

  const stats = fs.statSync(filepath);
  const sizeMb = (stats.size / 1024 / 1024).toFixed(2);
  console.log(`[BackupScheduler] Dump complete: ${filename} (${sizeMb} MB)`);

  return { filename, filepath, sizeMb };
}

export async function uploadToCloudinary(filepath: string, filename: string): Promise<string> {
  const publicId = `db-backups/${filename.replace(/\.sql$/, '')}`;

  const result = await cloudinary.v2.uploader.upload(filepath, {
    resource_type: 'raw',
    public_id: publicId,
    overwrite: false,
  });

  console.log(`[BackupScheduler] Uploaded to Cloudinary: ${result.secure_url}`);
  return result.secure_url;
}

export async function pruneOldCloudinaryBackups(): Promise<number> {
  try {
    const result = await cloudinary.v2.api.resources({
      type: 'upload',
      prefix: 'db-backups/',
      resource_type: 'raw',
      max_results: 500,
    });

    const resources = result.resources || [];
    resources.sort(
      (a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    );

    if (resources.length <= RETENTION_COUNT) {
      return 0;
    }

    const toDelete = resources.slice(0, resources.length - RETENTION_COUNT);
    const publicIds = toDelete.map((r) => r.public_id);

    if (publicIds.length === 0) return 0;

    await cloudinary.v2.api.delete_resources(publicIds, { resource_type: 'raw' });
    console.log(`[BackupScheduler] Pruned ${publicIds.length} old backup(s) from Cloudinary`);
    return publicIds.length;
  } catch (err: any) {
    console.error(`[BackupScheduler] Failed to prune old backups: ${err.message}`);
    return 0;
  }
}

export async function executeBackupCycle(): Promise<{ cloudinaryUrl?: string; emailSent: boolean; pruned: number }> {
  const result = { cloudinaryUrl: undefined as string | undefined, emailSent: false, pruned: 0 };

  try {
    const { filename, filepath, sizeMb } = await runBackup();

    try {
      result.cloudinaryUrl = await uploadToCloudinary(filepath, filename);
      result.pruned = await pruneOldCloudinaryBackups();
    } catch (uploadErr: any) {
      console.error(`[BackupScheduler] Cloudinary upload failed: ${uploadErr.message}`);
    }

    try {
      await sendBackupEmail(filepath, filename);
      result.emailSent = true;
    } catch (emailErr: any) {
      console.error(`[BackupScheduler] Backup email failed: ${emailErr.message}`);
    }

    try {
      if (fs.existsSync(filepath)) {
        fs.unlinkSync(filepath);
        console.log(`[BackupScheduler] Deleted local temp file: ${filename}`);
      }
    } catch (cleanupErr: any) {
      console.error(`[BackupScheduler] Failed to delete temp file: ${cleanupErr.message}`);
    }
  } catch (err: any) {
    console.error(`[BackupScheduler] Backup cycle failed: ${err.message}`);
  }

  return result;
}

export function startBackupScheduler(): void {
  cron.schedule('*/30 * * * *', () => {
    console.log(`[BackupScheduler] Cron trigger at ${new Date().toISOString()}`);
    executeBackupCycle();
  });

  console.log('[BackupScheduler] Scheduled: every 30 minutes (cron: */30 * * * *)');
}
