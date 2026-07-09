const MAX_RETRIES = 3;
const BASE_DELAY_MS = 200;

export class DatabaseUnavailableError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'DatabaseUnavailableError';
  }
}

function isConnectionError(error: unknown): boolean {
  if (!(error instanceof Error)) return false;
  const msg = error.message ?? '';
  return (
    msg.includes('Can\'t reach database server') ||
    msg.includes('Closed') ||
    msg.includes('connection') ||
    msg.includes('Connection') ||
    msg.includes('ECONNRESET') ||
    msg.includes('ETIMEDOUT') ||
    msg.includes('socket') ||
    msg.includes('timeout') ||
    msg.includes('Transaction not found') ||
    msg.includes('already closed') ||
    msg.includes('already been closed') ||
    (error as any)?.code === 'P1001' ||
    (error as any)?.code === 'P1002' ||
    (error as any)?.code === 'P1008' ||
    (error as any)?.code === 'P1017' ||
    (error as any)?.code === 'P2028'
  );
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function retryDbCall<T>(
  fn: () => Promise<T>,
  options?: { retries?: number; context?: string }
): Promise<T> {
  const maxRetries = options?.retries ?? MAX_RETRIES;
  let lastError: unknown;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error: unknown) {
      lastError = error;
      if (!isConnectionError(error)) throw error;
      if (attempt === maxRetries) break;
      const backoff = BASE_DELAY_MS * Math.pow(2, attempt - 1);
      console.warn(
        `[DB Retry]${options?.context ? ` [${options.context}]` : ''} Connection error attempt ${attempt}/${maxRetries} — retrying in ${backoff}ms`
      );
      await delay(backoff);
    }
  }

  throw new DatabaseUnavailableError(
    `Database unavailable after ${maxRetries} retries${options?.context ? ` (${options.context})` : ''}`
  );
}
