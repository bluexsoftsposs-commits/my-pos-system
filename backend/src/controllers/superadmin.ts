import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import prisma from '../config/db';
import { sendBackupEmail } from '../services/email';
import { generateSlug } from '../utils/slug';

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

    const [shopRows, total] = await Promise.all([
      prisma.shop.findMany({
        where: { shopName: { not: '__super_admin__' }, ...conditions } as any,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { users: true, sales: true, branches: true } },
          users: {
            select: { id: true, name: true, email: true, role: true, createdAt: true, isActive: true },
            orderBy: { createdAt: 'asc' },
          },
          payments: { take: 1, orderBy: { createdAt: 'desc' }, select: { amount: true, paymentMethod: true, createdAt: true } },
          subscriptions: {
            include: { plan: { select: { id: true, name: true, billingCycle: true, price: true, productsLimit: true, salesPointsLimit: true } } },
            take: 1,
            orderBy: { createdAt: 'desc' },
          },
        },
      }),
      prisma.shop.count({ where: { shopName: { not: '__super_admin__' }, ...conditions } as any }),
    ]);

    // Attach total revenue per shop
    const shopIds = shopRows.map(s => s.id);
    const revenueRows = await prisma.sale.groupBy({
      by: ['shopId'],
      where: { shopId: { in: shopIds } },
      _sum: { total: true },
    });
    const revenueMap: Record<string, number> = {};
    for (const r of revenueRows) {
      revenueMap[r.shopId] = r._sum.total ?? 0;
    }

    const shops = shopRows.map(s => ({
      ...s,
      totalRevenue: revenueMap[s.id] ?? 0,
    }));

    res.json({ shops, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('List shops error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateShop = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const { shopName, category } = req.body;

    const shop = await prisma.shop.findUnique({ where: { id } });
    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    const updateData: Record<string, unknown> = {};
    if (shopName !== undefined) updateData.shopName = shopName;
    if (category !== undefined) updateData.category = category;

    if (Object.keys(updateData).length === 0) {
      res.status(400).json({ error: 'Nothing to update' });
      return;
    }

    const updated = await prisma.shop.update({
      where: { id },
      data: updateData as any,
    });

    res.json({ success: true, shop: updated });
  } catch (error) {
    console.error('Update shop error:', error);
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
      data: { shopId, name, email, passwordHash, role: role || 'CASHIER' },
      select: { id: true, name: true, email: true, role: true, isActive: true, createdAt: true },
    });

    res.status(201).json({ success: true, user });
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const createAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { shopName, name, email, password } = req.body;

    if (!shopName || !name || !email || !password) {
      res.status(400).json({ error: 'shopName, name, email, and password are required' });
      return;
    }

    const existingEmail = await prisma.user.findUnique({ where: { email } });
    if (existingEmail) {
      res.status(409).json({ error: 'Email already registered' });
      return;
    }

    const existingShop = await prisma.shop.findUnique({ where: { shopName } });
    if (existingShop) {
      res.status(409).json({ error: 'Shop name already taken' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    // Generate unique slug
    let slug = generateSlug(shopName);
    let slugExists = await prisma.shop.findUnique({ where: { slug } });
    if (slugExists) slug = `${slug}-${Date.now().toString(36)}`;

    const result = await prisma.$transaction(async (tx) => {
      const shop = await tx.shop.create({
        data: { shopName, slug, subscriptionPlan: 'NONE', subscriptionStatus: 'NONE' },
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

    res.status(201).json({
      success: true,
      message: 'Admin account created successfully',
      admin: {
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        role: result.user.role,
        shop: {
          id: result.shop.id,
          shopName: result.shop.shopName,
        },
      },
    });
  } catch (error) {
    console.error('CREATE ADMIN ERROR:', error);
    res.status(500).json({
      message: 'Admin not created',
      error: error instanceof Error ? error.message : String(error),
    });
  }
};

export const toggleAdminStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const user = await prisma.user.findUnique({
      where: { id },
      include: { shop: { select: { shopName: true } } },
    });

    if (!user || !user.shop || user.shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Admin not found' });
      return;
    }

    const updated = await prisma.user.update({
      where: { id },
      data: { isActive: !user.isActive },
      select: { id: true, isActive: true, name: true, email: true, role: true },
    });

    // Also toggle the shop status
    if (user.role === 'ADMIN') {
      await prisma.shop.update({
        where: { id: user.shopId },
        data: { isActive: !user.isActive },
      });
    }

    res.json({ success: true, user: updated });
  } catch (error) {
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

// ── Plan Management ───────────────────────────────────────────────

export const createPlan = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, billingCycle, price, setupFee, originalSetupFee, salesPointsLimit, productsLimit, fbrConnect, techSupport, onlineStore, updates } = req.body;

    if (!name || !billingCycle || price === undefined || setupFee === undefined || salesPointsLimit === undefined || productsLimit === undefined) {
      res.status(400).json({ error: 'Missing required fields: name, billingCycle, price, setupFee, salesPointsLimit, productsLimit' });
      return;
    }

    const existing = await prisma.plan.findUnique({
      where: { name_billingCycle: { name, billingCycle } },
    });
    if (existing) {
      res.status(409).json({ error: `Plan "${name}" with billing cycle "${billingCycle}" already exists` });
      return;
    }

    const plan = await prisma.plan.create({
      data: { name, billingCycle, price, setupFee, originalSetupFee, salesPointsLimit, productsLimit, fbrConnect: fbrConnect ?? false, techSupport: techSupport ?? false, onlineStore: onlineStore ?? false, updates: updates ?? false },
    });

    res.status(201).json({ success: true, plan });
  } catch (error) {
    console.error('createPlan error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updatePlan = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const updates = req.body;

    const existing = await prisma.plan.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ error: 'Plan not found' });
      return;
    }

    const allowedFields = ['name', 'billingCycle', 'price', 'setupFee', 'originalSetupFee', 'salesPointsLimit', 'productsLimit', 'fbrConnect', 'techSupport', 'onlineStore', 'updates', 'isActive'];
    const data: Record<string, unknown> = {};
    for (const field of allowedFields) {
      if (updates[field] !== undefined) data[field] = updates[field];
    }

    if (Object.keys(data).length === 0) {
      res.status(400).json({ error: 'No valid fields to update' });
      return;
    }

    const plan = await prisma.plan.update({ where: { id }, data: data as any });

    res.json({ success: true, plan });
  } catch (error) {
    console.error('updatePlan error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const deactivatePlan = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const existing = await prisma.plan.findUnique({ where: { id } });
    if (!existing) {
      res.status(404).json({ error: 'Plan not found' });
      return;
    }

    const plan = await prisma.plan.update({ where: { id }, data: { isActive: !existing.isActive } });

    res.json({ success: true, plan, message: `Plan "${plan.name}" ${plan.isActive ? 'activated' : 'deactivated'}` });
  } catch (error) {
    console.error('deactivatePlan error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const listShopsSubscriptions = async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 20;
    const search = toString(req.query.search) || '';

    const where: Record<string, unknown> = { shopName: { not: '__super_admin__' } };
    if (search) where.shopName = { contains: search } as any;

    const [shops, total] = await Promise.all([
      prisma.shop.findMany({
        where: where as any,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          shopName: true,
          subscriptionPlan: true,
          subscriptionStatus: true,
          subscriptionEndsAt: true,
          isActive: true,
          _count: { select: { products: true, users: true } },
          subscriptions: {
            where: { status: 'active' },
            include: { plan: { select: { id: true, name: true, billingCycle: true, price: true, productsLimit: true, salesPointsLimit: true } } },
            take: 1,
            orderBy: { createdAt: 'desc' },
          },
        },
      }),
      prisma.shop.count({ where: where as any }),
    ]);

    res.json({ shops, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('listShopsSubscriptions error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const changeShopSubscription = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = toString(req.params.shopId);
    const { planId } = req.body;

    if (!planId) {
      res.status(400).json({ error: 'planId is required' });
      return;
    }

    const shop = await prisma.shop.findUnique({ where: { id: shopId } });
    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    const plan = await prisma.plan.findUnique({ where: { id: planId } });
    if (!plan) {
      res.status(404).json({ error: 'Plan not found' });
      return;
    }

    // Deactivate any existing active subscriptions for this shop
    await prisma.shopSubscription.updateMany({
      where: { shopId, status: 'active' },
      data: { status: 'expired' },
    });

    // Create new subscription
    const sub = await prisma.shopSubscription.create({
      data: { shopId, planId, status: 'active' },
    });

    // Update legacy Shop fields
    const endDate = plan.billingCycle === 'MONTHLY'
      ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      : plan.billingCycle === 'ANNUAL'
      ? new Date(Date.now() + 365 * 24 * 60 * 60 * 1000)
      : null;

    await prisma.shop.update({
      where: { id: shopId },
      data: {
        subscriptionPlan: plan.name,
        subscriptionStatus: 'ACTIVE',
        subscriptionEndsAt: endDate,
      },
    });

    res.json({ success: true, subscription: sub, plan, endsAt: endDate });
  } catch (error) {
    console.error('changeShopSubscription error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const deleteAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = toString(req.params.userId);
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { shop: { select: { id: true, shopName: true } } },
    });

    if (!user || user.shop?.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Admin not found' });
      return;
    }

    if (user.role !== 'ADMIN') {
      res.status(400).json({ error: 'User is not an admin' });
      return;
    }

    const adminEmail = user.email;
    if (adminEmail === 'superadmin@pos.com') {
      res.status(403).json({ error: 'Cannot delete the super admin' });
      return;
    }

    // Unassign the admin's shops by deactivating the user and shop
    await prisma.$transaction(async (tx) => {
      await tx.shop.update({
        where: { id: user.shopId },
        data: { isActive: false },
      });
      await tx.user.update({
        where: { id: userId },
        data: { isActive: false },
      });
    });

    console.log(`Admin ${user.name} (${user.email}) soft-deleted by superadmin`);
    res.json({ success: true, message: 'Admin deactivated' });
  } catch (error) {
    console.error('deleteAdmin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const deleteShop = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = toString(req.params.shopId);
    const shop = await prisma.shop.findUnique({ where: { id: shopId } });

    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Shop not found' });
      return;
    }

    // Cascade delete — schema has onDelete: Cascade for all child relations
    await prisma.shop.delete({ where: { id: shopId } });

    console.log(`Shop "${shop.shopName}" (${shopId}) permanently deleted by superadmin`);
    res.json({ success: true, message: 'Shop and all associated data permanently deleted' });
  } catch (error) {
    console.error('deleteShop error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const triggerBackup = async (req: Request, res: Response): Promise<void> => {
  try {
    const cronKey = req.query.key as string;
    const expectedKey = process.env.CRON_SECRET;
    if (cronKey && expectedKey && cronKey !== expectedKey) {
      res.status(403).json({ error: 'Invalid cron key' });
      return;
    }

    const dbUrl = process.env.DATABASE_URL;
    if (!dbUrl) {
      res.status(500).json({ error: 'DATABASE_URL not configured' });
      return;
    }

    const backupDir = path.resolve(__dirname, '..', '..', 'backups');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }

    const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    const filename = `backup_${ts}.sql`;
    const filepath = path.join(backupDir, filename);

    execSync(`pg_dump "${dbUrl}" --no-owner --no-acl -f "${filepath}"`, {
      timeout: 300_000,
    });

    const sizeMb = (fs.statSync(filepath).size / 1024 / 1024).toFixed(2);

    const cutoff = Date.now() - 14 * 24 * 60 * 60 * 1000;
    let pruned = 0;
    for (const file of fs.readdirSync(backupDir)) {
      if (!file.startsWith('backup_') || !file.endsWith('.sql')) continue;
      if (fs.statSync(path.join(backupDir, file)).mtimeMs < cutoff) {
        fs.unlinkSync(path.join(backupDir, file));
        pruned++;
      }
    }

    await sendBackupEmail(filepath, filename);

    res.json({ success: true, filename, sizeMb, pruned });
  } catch (error) {
    console.error('Backup error:', error);
    res.status(500).json({ error: 'Backup failed' });
  }
};
