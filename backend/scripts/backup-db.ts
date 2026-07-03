import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

const BACKUP_DIR = path.resolve(__dirname, '..', 'backups');
const RETENTION_DAYS = 14;

function getTimestamp(): string {
  const d = new Date();
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const h = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  return `${y}-${m}-${day}_${h}-${min}`;
}

async function main() {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error('FATAL: DATABASE_URL environment variable is not set.');
    process.exit(1);
  }

  if (!fs.existsSync(BACKUP_DIR)) {
    fs.mkdirSync(BACKUP_DIR, { recursive: true });
  }

  const filename = `backup_${getTimestamp()}.sql`;
  const filepath = path.join(BACKUP_DIR, filename);

  console.log(`Starting backup...`);
  console.log(`  Output: ${filepath}`);

  try {
    execSync(`pg_dump "${dbUrl}" --no-owner --no-acl -f "${filepath}"`, {
      stdio: 'inherit',
      timeout: 300_000,
    });
  } catch (err) {
    console.error('Backup failed.');
    process.exit(1);
  }

  const stats = fs.statSync(filepath);
  const sizeMb = (stats.size / 1024 / 1024).toFixed(2);
  console.log(`Backup complete: ${filename} (${sizeMb} MB)`);

  const cutoff = Date.now() - RETENTION_DAYS * 24 * 60 * 60 * 1000;
  let deletedCount = 0;

  for (const file of fs.readdirSync(BACKUP_DIR)) {
    if (!file.startsWith('backup_') || !file.endsWith('.sql')) continue;
    const filepath = path.join(BACKUP_DIR, file);
    const mtime = fs.statSync(filepath).mtimeMs;
    if (mtime < cutoff) {
      fs.unlinkSync(filepath);
      deletedCount++;
      console.log(`  Pruned: ${file}`);
    }
  }

  if (deletedCount > 0) {
    console.log(`Cleaned up ${deletedCount} old backup(s) (retention: ${RETENTION_DAYS} days).`);
  } else {
    console.log('No old backups to prune.');
  }
}

main();
