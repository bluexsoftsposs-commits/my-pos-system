import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

export const getDashboardStats = async (_req: Request, res: Response): Promise<void> => {
  try {
    const [totalShops, activeShops, totalUsers, totalAdmins, totalCashiers, totalSales, totalRevenue] = await Promise.all([
      prisma.shop.count({ where: { shopName: { not: '__super_admin__' } } }),
      prisma.shop.count({ where: { isActive: true, shopName: { not: '__super_admin__' } } }),
      prisma.user.count({ where: { shop: { shopName: { not: '__super_admin__' } } } }),
      prisma.user.count({ where: { role: 'ADMIN', shop: { shopName: { not: '__super_admin__' } } } }),
      prisma.user.count({ where: { role: 'CASHIER', shop: { shopName: { not: '__super_admin__' } } } }),
      prisma.sale.count(),
      prisma.sale.aggregate({ _sum: { total: true } }),
    ]);

    const planBreakdown = await prisma.shop.groupBy({
      by: ['subscriptionPlan'],
      _count: { id: true },
      where: { shopName: { not: '__super_admin__' } },
    });

    const statusBreakdown = await prisma.shop.groupBy({
      by: ['subscriptionStatus'],
      _count: { id: true },
      where: { shopName: { not: '__super_admin__' } },
    });

    res.json({
      totalShops,
      activeShops,
      totalUsers,
      totalAdmins,
      totalCashiers,
      totalSales,
      totalRevenue: totalRevenue._sum.total || 0,
      planBreakdown: planBreakdown.map(p => ({ plan: p.subscriptionPlan, count: p._count.id })),
      statusBreakdown: statusBreakdown.map(s => ({ status: s.subscriptionStatus, count: s._count.id })),
    });
  } catch (error) {
    console.error('Super admin stats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const listShops = async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 20;
    const search = toString(req.query.search) || '';
    const plan = toString(req.query.plan);

    const conditions: Record<string, unknown> = {};
    if (search) conditions.shopName = { contains: search } as any;
    if (plan) conditions.subscriptionPlan = plan;

    const [shops, total] = await Promise.all([
      prisma.shop.findMany({
        where: { shopName: { not: '__super_admin__' }, ...conditions } as any,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { users: true, sales: true } },
          payments: { take: 1, orderBy: { createdAt: 'desc' }, select: { amount: true, paymentMethod: true, createdAt: true } },
        },
      }),
      prisma.shop.count({ where: { shopName: { not: '__super_admin__' }, ...conditions } as any }),
    ]);

    res.json({ shops, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('List shops error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const listUsers = async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 20;
    const search = toString(req.query.search) || '';

    const conditions: Record<string, unknown> = {};
    if (search) {
      conditions.OR = [
        { name: { contains: search } },
        { email: { contains: search } },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where: { shop: { shopName: { not: '__super_admin__' } }, ...conditions } as any,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          email: true,
          role: true,
          isActive: true,
          createdAt: true,
          shop: { select: { id: true, shopName: true, subscriptionPlan: true } },
        },
      }),
      prisma.user.count({ where: { shop: { shopName: { not: '__super_admin__' } }, ...conditions } as any }),
    ]);

    res.json({ users, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('List users error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const toggleShopStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const shop = await prisma.shop.findUnique({ where: { id } });

    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    const updated = await prisma.shop.update({
      where: { id },
      data: { isActive: !shop.isActive },
    });

    res.json({ success: true, isActive: updated.isActive });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const deleteUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const user = await prisma.user.findUnique({
      where: { id },
      include: { shop: { select: { shopName: true } } },
    });

    if (!user || (user as any).shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    await prisma.user.update({
      where: { id },
      data: { isActive: false },
    });

    res.json({ success: true, message: 'User deactivated' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const createShopUser = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, email, password, role } = req.body;
    const shopId = req.body.shopId as string;

    if (!shopId || !name || !email || !password) {
      res.status(400).json({ error: 'shopId, name, email, and password are required' });
      return;
    }

    const shop = await prisma.shop.findUnique({ where: { id: shopId } });
    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    const existing = await prisma.user.findUnique({
      where: { shopId_email: { shopId, email } },
    });
    if (existing) {
      res.status(409).json({ error: 'User with this email already exists in this shop' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const user = await prisma.user.create({
      data: { shopId, name, email, passwordHash, role: role || 'CASHIER' },
      select: { id: true, name: true, email: true, role: true, isActive: true, createdAt: true },
    });

    res.status(201).json({ success: true, user });
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const extendSubscription = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const { days, plan } = req.body;

    const shop = await prisma.shop.findUnique({ where: { id } });
    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    const extraDays = days || 30;
    const newEnd = shop.subscriptionEndsAt && shop.subscriptionEndsAt > new Date()
      ? new Date(shop.subscriptionEndsAt.getTime() + extraDays * 24 * 60 * 60 * 1000)
      : new Date(Date.now() + extraDays * 24 * 60 * 60 * 1000);

    const updateData: Record<string, unknown> = {
      subscriptionEndsAt: newEnd,
      subscriptionStatus: 'ACTIVE',
    };
    if (plan) updateData.subscriptionPlan = plan;

    await prisma.shop.update({ where: { id }, data: updateData as any });

    res.json({ success: true, message: `Subscription extended by ${extraDays} days`, endsAt: newEnd });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
