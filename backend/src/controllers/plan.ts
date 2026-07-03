import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

/** GET /api/plans — list all active plans */
export const listPlans = async (_req: Request, res: Response): Promise<void> => {
  try {
    const plans = await prisma.plan.findMany({
      where: { isActive: true },
      orderBy: [{ name: 'asc' }, { billingCycle: 'asc' }],
    });
    res.json(plans);
  } catch (error) {
    console.error('listPlans error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/** GET /api/shop/:shopId/subscription — current plan + live usage */
export const getShopSubscription = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = toString(req.params.shopId);

    const sub = await prisma.shopSubscription.findFirst({
      where: { shopId, status: 'active' },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    const [productsUsed, usersCount] = await Promise.all([
      prisma.product.count({ where: { shopId, isActive: true } }),
      prisma.user.count({ where: { shopId, isActive: true } }),
    ]);

    res.json({
      subscription: sub
        ? {
            id: sub.id,
            plan: sub.plan,
            startDate: sub.startDate,
            endDate: sub.endDate,
            status: sub.status,
          }
        : null,
      usage: {
        productsUsed,
        productsLimit: sub?.plan.productsLimit ?? 0,
        salesPointsUsed: usersCount,
        salesPointsLimit: sub?.plan.salesPointsLimit ?? 0,
      },
    });
  } catch (error) {
    console.error('getShopSubscription error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
