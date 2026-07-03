import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as readline from 'readline';

const BACKUP_DIR = path.resolve(__dirname, '..', 'backups');

function listBackups(): string[] {
  if (!fs.existsSync(BACKUP_DIR)) return [];
  return fs.readdirSync(BACKUP_DIR)
    .filter(f => f.startsWith('backup_') && f.endsWith('.sql'))
    .sort()
    .reverse();
}

function prompt(query: string): Promise<string> {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise(resolve => rl.question(query, answer => { rl.close(); resolve(answer); }));
}

async function main() {
  const dbUrl = process.env.DATABASE_URL;
  if (!dbUrl) {
    console.error('FATAL: DATABASE_URL environment variable is not set.');
    process.exit(1);
  }

  const args = process.argv.slice(2);
  let backupFile: string | undefined;

  if (args.length > 0) {
    backupFile = args[0];
  } else {
    const backups = listBackups();
    if (backups.length === 0) {
      console.error('No backups found in backups/ directory.');
      console.error('Usage: npm run db:restore [backup_filename]');
      process.exit(1);
    }
    console.log('Available backups:');
    backups.forEach((b, i) => console.log(`  ${i + 1}. ${b}`));
    console.log();
    const answer = await prompt('Enter backup filename (or number): ');
    backupFile = /^\d+$/.test(answer) && parseInt(answer) <= backups.length
      ? backups[parseInt(answer) - 1]
      : answer;
  }

  const filepath = path.resolve(backupFile);
  const resolvedPath = fs.existsSync(filepath)
    ? filepath
    : path.join(BACKUP_DIR, backupFile);

  if (!fs.existsSync(resolvedPath)) {
    console.error(`Backup file not found: ${resolvedPath}`);
    process.exit(1);
  }

  const stats = fs.statSync(resolvedPath);
  const sizeMb = (stats.size / 1024 / 1024).toFixed(2);
  console.log(`\nWARNING: You are about to OVERWRITE the database with:`);
  console.log(`  File: ${path.basename(resolvedPath)} (${sizeMb} MB)`);
  console.log(`  Target: ${dbUrl.replace(/\/\/.*@/, '//<credentials>@')}`);
  console.log(`\nThis will DROP existing data and restore from backup.`);
  console.log(`Type "RESTORE" to confirm:`);

  const confirm = await prompt('> ');
  if (confirm !== 'RESTORE') {
    console.log('Restore cancelled.');
    process.exit(0);
  }

  console.log('\nRestoring...');
  try {
    execSync(`psql "${dbUrl}" -f "${resolvedPath}"`, {
      stdio: 'inherit',
      timeout: 600_000,
    });
  } catch (err) {
    console.error('Restore failed.');
    process.exit(1);
  }

  console.log('Restore complete.');
}

main();
