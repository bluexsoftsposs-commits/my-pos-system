import { Request, Response, NextFunction } from 'express';
import prisma from '../config/db';

export const requireSubscription = (req: Request, res: Response, next: NextFunction): void => {
  checkSubscription(req, res, next, false);
};

export const requireActiveSubscription = (req: Request, res: Response, next: NextFunction): void => {
  checkSubscription(req, res, next, true);
};

async function checkSubscription(req: Request, res: Response, next: NextFunction, requireActive: boolean): Promise<void> {
  try {
    const shopId = req.shopId;
    if (!shopId) {
      res.status(401).json({ error: 'Authentication required' });
      return;
    }

    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      select: { subscriptionPlan: true, subscriptionStatus: true, subscriptionEndsAt: true },
    });

    if (!shop) {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    if (shop.subscriptionStatus === 'PENDING') {
      res.status(402).json({
        error: 'Payment pending. Please complete your payment.',
        subscriptionStatus: 'PENDING',
        requiresPayment: true,
      });
      return;
    }

    if (shop.subscriptionStatus !== 'ACTIVE') {
      res.status(402).json({
        error: 'No active subscription. Please purchase a plan to continue.',
        subscriptionStatus: shop.subscriptionStatus,
        requiresPayment: true,
      });
      return;
    }

    if (shop.subscriptionEndsAt && new Date(shop.subscriptionEndsAt) < new Date()) {
      res.status(402).json({
        error: 'Your subscription has expired. Please renew to continue.',
        subscriptionStatus: 'EXPIRED',
        requiresPayment: true,
      });
      return;
    }

    if (requireActive) {
      const maxUsers = shop.subscriptionPlan === 'PREMIUM' ? 999 : shop.subscriptionPlan === 'PLATINUM' ? 5 : 1;
      const userCount = await prisma.user.count({ where: { shopId, isActive: true } });
      if (userCount > maxUsers) {
        res.status(402).json({
          error: `User limit exceeded. Your ${shop.subscriptionPlan} plan allows ${maxUsers} active users.`,
          requiresUpgrade: true,
        });
        return;
      }
    }

    next();
  } catch (error) {
    console.error('Subscription check error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}
