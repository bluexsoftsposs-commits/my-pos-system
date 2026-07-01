import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../config/db';

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
    console.log('AUTH MIDDLEWARE JWT_SECRET length:', process.env.JWT_SECRET?.length || 'UNDEFINED');
    const secret = process.env.JWT_SECRET || 'fallback-secret';
    const decoded = jwt.verify(token, secret) as AuthPayload;

    // Enforce single session if currentSessionToken is set
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { currentSessionToken: true },
    });

    if (!user) {
      res.status(401).json({ error: 'User not found' });
      return;
    }

    // If currentSessionToken is set, it must match the request token
    if (user.currentSessionToken !== null && user.currentSessionToken !== token) {
      res.status(401).json({ error: 'Session expired — logged in from another device' });
      return;
    }

    // Legacy sessions (null) or matching token are allowed
    req.user = decoded;
    req.shopId = decoded.shopId;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

export const requireAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user || req.user.role !== 'ADMIN') {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
};

export const requireSuperAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user || req.user.role !== 'SUPER_ADMIN') {
    res.status(403).json({ error: 'Super admin access required' });
    return;
  }
  next();
};
