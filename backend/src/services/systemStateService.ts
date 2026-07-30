import prisma from '../config/db';
import crypto from 'crypto';

const MAINTENANCE_KEY = 'maintenance_mode';
const JWT_OVERRIDE_KEY = 'jwt_secret_override';

let cachedMaintenanceMode: boolean | null = null;
let cachedJwtOverride: string | null = null;

async function ensureStateRecord(key: string): Promise<void> {
  try {
    await prisma.systemState.upsert({
      where: { key },
      update: {},
      create: { key, value: '' },
    });
  } catch {
  }
}

export async function initSystemState(): Promise<void> {
  await ensureStateRecord(MAINTENANCE_KEY);
  await ensureStateRecord(JWT_OVERRIDE_KEY);

  const rows = await prisma.systemState.findMany({
    where: { key: { in: [MAINTENANCE_KEY, JWT_OVERRIDE_KEY] } },
  });

  for (const row of rows) {
    if (row.key === MAINTENANCE_KEY) {
      cachedMaintenanceMode = row.value === 'true';
    }
    if (row.key === JWT_OVERRIDE_KEY) {
      cachedJwtOverride = row.value || null;
    }
  }

  if (cachedJwtOverride) {
    process.env.JWT_SECRET = cachedJwtOverride;
    console.log('[SystemState] Restored rotated JWT secret from DB');
  }

  console.log(`[SystemState] Initialized. Maintenance: ${cachedMaintenanceMode}, JWT override: ${!!cachedJwtOverride}`);
}

export function isMaintenanceMode(): boolean {
  return cachedMaintenanceMode === true;
}

export async function setMaintenanceMode(enabled: boolean): Promise<void> {
  cachedMaintenanceMode = enabled;
  await prisma.systemState.upsert({
    where: { key: MAINTENANCE_KEY },
    update: { value: enabled ? 'true' : 'false' },
    create: { key: MAINTENANCE_KEY, value: enabled ? 'true' : 'false' },
  });
  console.log(`[SystemState] Maintenance mode set to ${enabled}`);
}

export function getJwtOverride(): string | null {
  return cachedJwtOverride;
}

export function getEffectiveJwtSecret(): string {
  return cachedJwtOverride || process.env.JWT_SECRET || 'fallback-secret';
}

export async function rotateJwtSecret(): Promise<string> {
  const newSecret = crypto.randomBytes(48).toString('hex');
  cachedJwtOverride = newSecret;
  process.env.JWT_SECRET = newSecret;
  await prisma.systemState.upsert({
    where: { key: JWT_OVERRIDE_KEY },
    update: { value: newSecret },
    create: { key: JWT_OVERRIDE_KEY, value: newSecret },
  });
  console.log('[SystemState] JWT secret rotated');
  return newSecret;
}

export async function restoreJwtSecret(): Promise<void> {
  cachedJwtOverride = null;
  process.env.JWT_SECRET = process.env.ORIGINAL_JWT_SECRET || undefined;
  await prisma.systemState.upsert({
    where: { key: JWT_OVERRIDE_KEY },
    update: { value: '' },
    create: { key: JWT_OVERRIDE_KEY, value: '' },
  });
  console.log('[SystemState] JWT secret restored to original');
}
