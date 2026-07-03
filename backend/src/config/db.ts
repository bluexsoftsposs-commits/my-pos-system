import { PrismaClient } from '../../app/generated/prisma';

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['error', 'warn'] : ['error'],
});

let retryAttempt = 0;
const MAX_RETRIES = 3;

function isRetryableError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const msg = error.message ?? '';
  // Neon pool disconnection, TLS drop, or general connection failures
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

prisma.$use(async (params, next) => {
  try {
    retryAttempt = 0;
    return await next(params);
  } catch (error: unknown) {
    if (isRetryableError(error)) {
      while (retryAttempt < MAX_RETRIES) {
        retryAttempt++;
        const backoff = Math.min(1000 * Math.pow(2, retryAttempt), 5000);
        console.warn(
          `[DB] Connection lost, retrying query (attempt ${retryAttempt}/${MAX_RETRIES}) after ${backoff}ms...`,
        );
        await delay(backoff);
        try {
          return await next(params);
        } catch (inner: unknown) {
          if (!isRetryableError(inner)) throw inner;
        }
      }
    }
    throw error;
  }
});

export default prisma;
