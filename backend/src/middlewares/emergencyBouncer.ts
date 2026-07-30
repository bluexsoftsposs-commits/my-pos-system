import { Request, Response, NextFunction } from 'express';

const IP_TRUST_PROXIES = 1;

export function emergencyBouncer(req: Request, res: Response, next: NextFunction): void {
  const allowedRaw = process.env.EMERGENCY_ALLOWED_IPS || '';
  if (!allowedRaw) {
    res.status(404).json({ error: 'Route not found' });
    return;
  }

  const allowed = allowedRaw.split(',').map(s => s.trim()).filter(Boolean);
  if (allowed.length === 0) {
    res.status(404).json({ error: 'Route not found' });
    return;
  }

  const forwarded = req.headers['x-forwarded-for'];
  let clientIp: string;
  if (forwarded && typeof forwarded === 'string') {
    const parts = forwarded.split(',').map(s => s.trim());
    clientIp = parts[0];
  } else {
    clientIp = req.socket.remoteAddress || req.ip || '';
  }

  if (clientIp.startsWith('::ffff:')) {
    clientIp = clientIp.slice(7);
  }
  if (clientIp === '::1') {
    clientIp = '127.0.0.1';
  }

  if (!allowed.includes(clientIp)) {
    res.status(404).json({ error: 'Route not found' });
    return;
  }

  next();
}
