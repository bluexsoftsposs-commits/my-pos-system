import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import prisma from '../config/db';

// GET /api/users
export const getUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const users = await prisma.user.findMany({
      where: { shopId: req.shopId as string },
      select: { id: true, name: true, email: true, role: true, isActive: true, canAccessSuppliers: true, createdAt: true },
      orderBy: { name: 'asc' },
    });
    res.json(users);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/users
export const createUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      res.status(400).json({ error: 'name, email, and password are required' });
      return;
    }

    const shopId = req.shopId as string;

    const existing = await prisma.user.findUnique({
      where: {
        shopId_email: {
          shopId,
          email,
        },
      },
    });

    if (existing) {
      res.status(409).json({ error: 'User with this email already exists' });
      return;
    }

    // Enforce sales points limit from subscription plan
    const subscription = await prisma.shopSubscription.findFirst({
      where: { shopId, status: 'active' },
      include: { plan: { select: { name: true, salesPointsLimit: true } } },
      orderBy: { createdAt: 'desc' },
    });

    if (subscription) {
      const limit = subscription.plan.salesPointsLimit;
      const currentCount = await prisma.user.count({
        where: { shopId, isActive: true },
      });

      if (currentCount >= limit) {
        res.status(403).json({
          error: `Sales point limit reached. Your ${subscription.plan.name} plan allows ${limit} sales point(s). You have ${currentCount}/${limit}.`,
        });
        return;
      }
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await prisma.user.create({
      data: {
        shopId: req.shopId as string,
        name,
        email,
        passwordHash,
        role: role || 'CASHIER',
        canAccessSuppliers: role === 'CASHIER' ? false : undefined,
      },
      select: { id: true, name: true, email: true, role: true, createdAt: true },
    });

    res.status(201).json(user);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// PUT /api/users/:id
export const updateUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.params.id as string;

    const existing = await prisma.user.findFirst({
      where: { id: userId, shopId: req.shopId as string },
    });

    if (!existing) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    const { name, role, isActive, password, canAccessSuppliers } = req.body;

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(name !== undefined && { name }),
        ...(role !== undefined && { role }),
        ...(isActive !== undefined && { isActive }),
        ...(canAccessSuppliers !== undefined && { canAccessSuppliers }),
        ...(password ? { passwordHash: await bcrypt.hash(password, 12) } : {}),
      },
      select: { id: true, name: true, email: true, role: true, isActive: true, canAccessSuppliers: true },
    });

    res.json(user);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// DELETE /api/users/:id
export const deleteUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.params.id as string;
    // req.user ko access karne ke liye 'any' ka use kiya hai jo type errors hatata hai
    const currentUserId = (req as any).user?.userId;

    if (userId === currentUserId) {
      res.status(400).json({ error: 'Cannot delete your own account' });
      return;
    }

    const existing = await prisma.user.findFirst({
      where: { id: userId, shopId: req.shopId as string },
    });

    if (!existing) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    await prisma.user.update({
      where: { id: userId },
      data: { isActive: false },
    });

    res.json({ message: 'User deactivated successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};