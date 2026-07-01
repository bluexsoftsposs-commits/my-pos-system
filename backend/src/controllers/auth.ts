import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import prisma from '../config/db';
import { sendVerificationEmail, sendPasswordResetEmail } from '../services/email';

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

    // Validate email format (must be @gmail.com)
    const gmailRegex = /^[a-zA-Z0-9._%+-]+@gmail\.com$/;
    if (!gmailRegex.test(email)) {
      res.status(400).json({ error: 'Invalid email format' });
      return;
    }

    // Check if email already exists globally
    const existingEmail = await prisma.user.findUnique({ where: { email } });
    if (existingEmail) {
      res.status(409).json({ error: 'Email or Shop Name already registered' });
      return;
    }

    // Check if shop name already taken
    const existingShop = await prisma.shop.findUnique({ where: { shopName } });
    if (existingShop) {
      res.status(409).json({ error: 'Email or Shop Name already registered' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const verificationToken = crypto.randomBytes(32).toString('hex');

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
          verificationToken,
        },
      });

      // Seed 5 demo products for the new shop
      const demoProducts = [
        { name: 'Premium Basmati Rice 5kg', description: 'Aged extra-long grain basmati rice, perfect for biryani and pulao.', price: 1850, stock: 50, category: 'Groceries', sku: `DEMO-${shop.id.slice(0,4)}-001` },
        { name: 'Fresh Chicken Breast 1kg', description: 'Hormone-free, farm-fresh chicken breast cuts.', price: 920, stock: 30, category: 'Meat & Poultry', sku: `DEMO-${shop.id.slice(0,4)}-002` },
        { name: 'Shan Biryani Masala 60g', description: 'Authentic blend of spices for delicious homemade biryani.', price: 145, stock: 120, category: 'Spices & Condiments', sku: `DEMO-${shop.id.slice(0,4)}-003` },
        { name: 'Nestle Fruita Vitals Chaunsa Mango Juice 1L', description: '100% pure chaunsa mango juice with no added preservatives.', price: 310, stock: 80, category: 'Beverages', sku: `DEMO-${shop.id.slice(0,4)}-004` },
        { name: 'Dawn Bread Large White', description: 'Soft and fluffy large white bread loaf, baked fresh daily.', price: 180, stock: 40, category: 'Bakery', sku: `DEMO-${shop.id.slice(0,4)}-005` },
      ];

      for (const product of demoProducts) {
        await tx.product.create({ data: { shopId: shop.id, ...product } });
      }

      return { shop, user };
    });

    // Send verification email (don't block registration on email failure)
    sendVerificationEmail(email, verificationToken).catch((err) =>
      console.error('Failed to send verification email:', err)
    );

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

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({ message: 'Email and password required' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { email },
      include: { shop: true }
    });

    if (!user) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    const validPassword = await bcrypt.compare(password, user.passwordHash);
    if (!validPassword) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    console.log('JWT_SECRET length:', process.env.JWT_SECRET?.length || 'UNDEFINED');
    console.log('Signing token for userId:', user.id, 'role:', user.role);
    const token = jwt.sign(
      { userId: user.id, role: user.role, shopId: user.shopId },
      process.env.JWT_SECRET || 'fallback-secret',
      { expiresIn: '7d' }
    );

    res.status(200).json({
      token,
      user: { id: user.id, email: user.email, name: user.name, role: user.role, shopId: user.shopId, shop: user.shop }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};

// POST /api/auth/logout
export const logout = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    await prisma.user.update({
      where: { id: userId },
      data: { currentSessionToken: null },
    });

    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/auth/me
export const getMe = async (req: Request, res: Response): Promise<void> => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      select: { id: true, name: true, email: true, role: true, shopId: true, emailVerified: true, createdAt: true },
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

// GET /api/auth/verify-email?token=xxx
export const verifyEmail = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token } = req.query;

    if (!token || typeof token !== 'string') {
      res.status(400).json({ error: 'Verification token is required' });
      return;
    }

    const user = await prisma.user.findFirst({
      where: { verificationToken: token },
    });

    if (!user) {
      res.status(400).json({ error: 'Invalid or expired verification token' });
      return;
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true, verificationToken: null },
    });

    res.json({ message: 'Email verified successfully' });
  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/auth/resend-verification
export const resendVerification = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, shopId } = req.body;

    if (!email || !shopId) {
      res.status(400).json({ error: 'Email and shopId are required' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { shopId_email: { shopId, email } },
    });

    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    if (user.emailVerified) {
      res.status(400).json({ error: 'Email already verified' });
      return;
    }

    const verificationToken = crypto.randomBytes(32).toString('hex');
    await prisma.user.update({
      where: { id: user.id },
      data: { verificationToken },
    });

    await sendVerificationEmail(email, verificationToken);

    res.json({ message: 'Verification email sent' });
  } catch (error) {
    console.error('Resend verification error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/auth/forgot-password
export const forgotPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, shopName } = req.body;
    console.log('Forgot password request received for:', email);

    if (!email || !shopName) {
      res.status(400).json({ error: 'Email and shopName are required' });
      return;
    }

    const shop = await prisma.shop.findUnique({ where: { shopName } });
    if (!shop) {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { shopId_email: { shopId: shop.id, email } },
    });

    if (!user) {
      res.status(404).json({ error: 'User not found with this email and shop' });
      return;
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

    await prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        token: resetToken,
        expiresAt,
      },
    });

    await sendPasswordResetEmail(email, resetToken);

    res.json({ message: 'Password reset email sent' });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/auth/reset-password
export const resetPassword = async (req: Request, res: Response): Promise<void> => {
  try {
    const { token, password } = req.body;

    if (!token || !password) {
      res.status(400).json({ error: 'Token and new password are required' });
      return;
    }

    if (password.length < 6) {
      res.status(400).json({ error: 'Password must be at least 6 characters' });
      return;
    }

    const resetRecord = await prisma.passwordResetToken.findUnique({
      where: { token },
    });

    if (!resetRecord) {
      res.status(400).json({ error: 'Invalid reset token' });
      return;
    }

    if (resetRecord.usedAt) {
      res.status(400).json({ error: 'Reset token has already been used' });
      return;
    }

    if (new Date() > resetRecord.expiresAt) {
      res.status(400).json({ error: 'Reset token has expired' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    await prisma.$transaction([
      prisma.user.update({
        where: { id: resetRecord.userId },
        data: { passwordHash },
      }),
      prisma.passwordResetToken.update({
        where: { id: resetRecord.id },
        data: { usedAt: new Date() },
      }),
    ]);

    res.json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
