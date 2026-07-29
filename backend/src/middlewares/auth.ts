import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../config/db';
import { retryDbCall, DatabaseUnavailableError } from '../utils/retryDbCall';

export interface AuthPayload {
  userId: string;
  shopId: string;
  role: string;
  email: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthPayload;
      shopId?: string;
    }
  }
}

export const authenticate = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Authorization token is required' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'fallback-secret') as AuthPayload;

    const user = await retryDbCall(
      () => prisma.user.findUnique({
        where: { id: decoded.userId },
        select: { id: true },
      }),
      { context: 'authenticate' }
    );

    if (!user) {
      res.status(401).json({ error: 'User not found' });
      return;
    }

    // Normalize role from DB format (e.g. SUPER_ADMIN -> SuperAdmin) to match middleware checks
    const roleMap: Record<string, string> = {
      'SUPER_ADMIN': 'SuperAdmin',
      'ADMIN': 'Admin',
      'SUB_ADMIN': 'SubAdmin',
      'SUPPLIER': 'Supplier',
    };
    decoded.role = roleMap[decoded.role] || decoded.role;

    req.user = decoded;
    req.shopId = decoded.shopId;
    next();
  } catch (err) {
    if (err instanceof DatabaseUnavailableError) {
      res.status(503).json({ error: 'Service temporarily unavailable, please retry' });
      return;
    }
    if (err instanceof jwt.JsonWebTokenError || err instanceof jwt.TokenExpiredError) {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

export const requireAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user || req.user.role !== 'Admin') {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
};

export const requireSuperAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user || req.user.role !== 'SuperAdmin') {
    res.status(403).json({ error: 'Super admin access required' });
    return;
  }
  next();
};
