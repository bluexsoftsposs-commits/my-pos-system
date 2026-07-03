import { PrismaClient } from '../../app/generated/prisma';

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});

const MAX_RETRIES = 3;
const KEEPALIVE_INTERVAL_MS = 55_000;

function isRetryableError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const msg = error.message ?? '';
  return (
    msg.includes('Closed') ||
    msg.includes('connection') ||
    msg.includes('Connection') ||
    msg.includes('ECONNRESET') ||
    msg.includes('ETIMEDOUT') ||
    msg.includes('socket') ||
    msg.includes('timeout') ||
    (error as any)?.code === 'P1001' ||
    (error as any)?.code === 'P1002' ||
    (error as any)?.code === 'P1008' ||
    (error as any)?.code === 'P1017'
  );
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Reset the Prisma connection pool so stale handles don't poison retries.
 */
async function resetPool(): Promise<void> {
  try {
    await prisma.$disconnect();
  } catch {
    // ignore disconnect errors
  }
  await prisma.$connect();
}

prisma.$use(async (params, next) => {
  for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
    try {
      return await next(params);
    } catch (error: unknown) {
      if (!isRetryableError(error)) throw error;
      if (attempt === MAX_RETRIES) throw error;
      const backoff = Math.min(1000 * Math.pow(2, attempt), 5000);
      console.warn(
        `[DB] Connection lost, resetting pool and retrying query (attempt ${attempt}/${MAX_RETRIES}) after ${backoff}ms...`,
      );
      await delay(backoff);
      await resetPool();
    }
  }
});

// Periodic keepalive to prevent Neon from closing idle connections
let keepaliveTimer: ReturnType<typeof setInterval> | null = null;

function startKeepalive(): void {
  if (keepaliveTimer) return;
  keepaliveTimer = setInterval(async () => {
    try {
      await prisma.$queryRaw`SELECT 1`;
    } catch {
      // keepalive failures are non-fatal; pool reset will happen on next real query
    }
  }, KEEPALIVE_INTERVAL_MS);
}

startKeepalive();

// Graceful shutdown
process.on('SIGINT', async () => {
  if (keepaliveTimer) clearInterval(keepaliveTimer);
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  if (keepaliveTimer) clearInterval(keepaliveTimer);
  await prisma.$disconnect();
  process.exit(0);
});

export default prisma;
