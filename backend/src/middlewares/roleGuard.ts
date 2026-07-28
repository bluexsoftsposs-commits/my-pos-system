import { Request, Response, NextFunction } from 'express';
import prisma from '../config/db';

export const requireSubAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user) {
    res.status(401).json({ error: 'Authentication required' });
    return;
  }
  if (req.user.role !== 'SubAdmin') {
    res.status(403).json({ error: 'Sub-admin access required' });
    return;
  }
  next();
};

export const requireSupplier = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user) {
    res.status(401).json({ error: 'Authentication required' });
    return;
  }
  if (req.user.role !== 'Supplier') {
    res.status(403).json({ error: 'Supplier access required' });
    return;
  }
  next();
};

export const requireSuperAdminOrSubAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user) {
    res.status(401).json({ error: 'Authentication required' });
    return;
  }
  if (req.user.role !== 'SuperAdmin' && req.user.role !== 'SubAdmin') {
    res.status(403).json({ error: 'Admin access required' });
    return;
  }
  next();
};

export const requireRole = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }
    if (!roles.includes(req.user.role)) {
      res.status(403).json({ error: `Access restricted to: ${roles.join(', ')}` });
      return;
    }
    next();
  };
};

// For Cashier: check if they have canAccessSuppliers enabled
export const requireCashierSupplierAccess = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  if (!req.user) {
    res.status(401).json({ error: 'Authentication required' });
    return;
  }
  if (req.user.role === 'Admin' || req.user.role === 'SuperAdmin') {
    next();
    return;
  }
  if (req.user.role === 'CASHIER') {
    try {
      const user = await prisma.user.findUnique({
        where: { id: req.user.userId },
        select: { canAccessSuppliers: true },
      });
      if (!user || !user.canAccessSuppliers) {
        res.status(403).json({ error: 'Supplier access not granted. Ask your admin to enable it.' });
        return;
      }
      next();
    } catch (error) {
      console.error('requireCashierSupplierAccess error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
    return;
  }
  res.status(403).json({ error: 'Access denied' });
};

// Check if the authenticated sub-admin has a specific permission in their array
export const requirePermission = (permission: string) => {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        res.status(401).json({ error: 'Authentication required' });
        return;
      }
      if (req.user.role !== 'SubAdmin') {
        next();
        return;
      }
      const subAdmin = await prisma.subAdmin.findUnique({ where: { userId: req.user.userId } });
      if (!subAdmin) {
        res.status(403).json({ error: 'Sub-admin profile not found' });
        return;
      }
      const perms = subAdmin.permissions as string[];
      if (!perms.includes(permission)) {
        res.status(403).json({ error: `Missing required permission: ${permission}` });
        return;
      }
      next();
    } catch (error) {
      console.error('requirePermission error:', error);
      res.status(500).json({ error: 'Internal server error' });
    }
  };
};
