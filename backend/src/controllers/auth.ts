import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../config/db';

const JWT_SECRET = process.env.JWT_SECRET || 'fallback-secret';
const JWT_EXPIRES_IN = '7d';

// POST /api/auth/register
export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { shopName, email, password, name } = req.body;

    if (!shopName || !email || !password || !name) {
      res.status(400).json({ error: 'shopName, email, password, and name are required' });
      return;
    }

    // Check if shop name already taken
    const existingShop = await prisma.shop.findUnique({ where: { shopName } });
    if (existingShop) {
      res.status(409).json({ error: 'Shop name already registered' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    // Create shop and admin user in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const shop = await tx.shop.create({
        data: { shopName, subscriptionPlan: 'NONE', subscriptionStatus: 'NONE' },
      });

      const user = await tx.user.create({
        data: {
          shopId: shop.id,
          email,
          passwordHash,
          name,
          role: 'ADMIN',
        },
      });

      return { shop, user };
    });

    const token = jwt.sign(
      {
        userId: result.user.id,
        shopId: result.shop.id,
        role: result.user.role,
        email: result.user.email,
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(201).json({
      token,
      user: {
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        role: result.user.role,
      },
      shop: {
        id: result.shop.id,
        shopName: result.shop.shopName,
        subscriptionPlan: result.shop.subscriptionPlan,
        subscriptionStatus: result.shop.subscriptionStatus,
      },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/auth/login
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { shopName, email, password } = req.body;

    if (!shopName || !email || !password) {
      res.status(400).json({ error: 'shopName, email, and password are required' });
      return;
    }

    const shop = await prisma.shop.findUnique({ where: { shopName } });
    if (!shop || !shop.isActive) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { shopId_email: { shopId: shop.id, email } },
    });

    if (!user || !user.isActive) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      res.status(401).json({ error: 'Invalid credentials' });
      return;
    }

    const token = jwt.sign(
      {
        userId: user.id,
        shopId: shop.id,
        role: user.role,
        email: user.email,
      },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
      shop: {
        id: shop.id,
        shopName: shop.shopName,
        subscriptionPlan: shop.subscriptionPlan,
        subscriptionStatus: shop.subscriptionStatus,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/auth/me
export const getMe = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      select: { id: true, name: true, email: true, role: true, shopId: true, createdAt: true },
    });

    const shop = await prisma.shop.findUnique({
      where: { id: req.shopId },
      select: { id: true, shopName: true, subscriptionPlan: true, subscriptionStatus: true, subscriptionEndsAt: true, isActive: true },
    });

    res.json({ user, shop });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
