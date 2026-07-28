import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import prisma from '../config/db';
import { sendApprovalEmail } from '../services/email';
import { generateSlug } from '../utils/slug';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// ── Super Admin manages Sub-Admins ─────────────────────────────────

export const createSubAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, email, password, title, region, permissions } = req.body;
    if (!name || !email || !password) {
      res.status(400).json({ error: 'name, email, and password are required' });
      return;
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      res.status(409).json({ error: 'Email already registered' });
      return;
    }

    const superAdminShop = await prisma.shop.findUnique({ where: { shopName: '__super_admin__' } });
    if (!superAdminShop) {
      res.status(500).json({ error: 'Super admin shop not found' });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          shopId: superAdminShop.id,
          email,
          passwordHash,
          name,
          role: 'SubAdmin',
        },
      });

      const subAdmin = await tx.subAdmin.create({
        data: {
          userId: user.id,
          title: title || null,
          region: region || null,
          permissions: permissions || ['create_admin', 'edit_admin', 'manage_shops', 'change_plan', 'view_reports', 'manage_suppliers'],
        },
      });

      return { user, subAdmin };
    });

    res.status(201).json({
      success: true,
      subAdmin: {
        id: result.subAdmin.id,
        userId: result.user.id,
        name: result.user.name,
        email: result.user.email,
        title: result.subAdmin.title,
        region: result.subAdmin.region,
        permissions: result.subAdmin.permissions,
      },
    });
  } catch (error) {
    console.error('createSubAdmin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const listSubAdmins = async (_req: Request, res: Response): Promise<void> => {
  try {
    const subAdmins = await prisma.subAdmin.findMany({
      include: {
        user: {
          select: { id: true, name: true, email: true, isActive: true, createdAt: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({
      success: true,
      subAdmins: subAdmins.map((sa) => ({
        id: sa.id,
        userId: sa.user.id,
        name: sa.user.name,
        email: sa.user.email,
        isActive: sa.user.isActive,
        title: sa.title,
        region: sa.region,
        permissions: sa.permissions,
        createdAt: sa.createdAt,
      })),
    });
  } catch (error) {
    console.error('listSubAdmins error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateSubAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const { title, region, isActive, permissions } = req.body;

    const subAdmin = await prisma.subAdmin.findUnique({ where: { id } });
    if (!subAdmin) {
      res.status(404).json({ error: 'Sub-admin not found' });
      return;
    }

    const updateData: Record<string, unknown> = {};
    if (title !== undefined) updateData.title = title;
    if (region !== undefined) updateData.region = region;
    if (permissions !== undefined) updateData.permissions = permissions;

    await prisma.subAdmin.update({ where: { id }, data: updateData });

    if (isActive !== undefined) {
      await prisma.user.update({
        where: { id: subAdmin.userId },
        data: { isActive },
      });
    }

    res.json({ success: true, message: 'Sub-admin updated' });
  } catch (error) {
    console.error('updateSubAdmin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const deleteSubAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const subAdmin = await prisma.subAdmin.findUnique({ where: { id } });
    if (!subAdmin) {
      res.status(404).json({ error: 'Sub-admin not found' });
      return;
    }

    await prisma.$transaction([
      prisma.user.update({ where: { id: subAdmin.userId }, data: { isActive: false } }),
      prisma.subAdmin.delete({ where: { id } }),
    ]);

    res.json({ success: true, message: 'Sub-admin deleted' });
  } catch (error) {
    console.error('deleteSubAdmin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSubAdminShops = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const subAdmin = await prisma.subAdmin.findUnique({ where: { id } });
    if (!subAdmin) {
      res.status(404).json({ error: 'Sub-admin not found' });
      return;
    }

    const shops = await prisma.shop.findMany({
      where: { managedBySubAdminId: subAdmin.userId },
      include: {
        _count: { select: { users: true, sales: true } },
        users: {
          select: { id: true, name: true, email: true, role: true },
          where: { role: 'Admin' },
          take: 1,
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, shops });
  } catch (error) {
    console.error('getSubAdminShops error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ── Sub-Admin Actions (need approval) ──────────────────────────────

export const subAdminCreateAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { shopName, name, email, password, category } = req.body;
    const subAdminUserId = req.user!.userId;

    if (!shopName || !name || !email || !password) {
      res.status(400).json({ error: 'shopName, name, email, and password are required' });
      return;
    }

    const subAdmin = await prisma.subAdmin.findUnique({ where: { userId: subAdminUserId } });
    if (!subAdmin) {
      res.status(403).json({ error: 'Sub-admin profile not found' });
      return;
    }

    const slug = generateSlug(shopName);
    const finalSlug = (await prisma.shop.findUnique({ where: { slug } }))
      ? `${slug}-${Date.now().toString(36)}`
      : slug;

    // Create pending approval
    const approval = await prisma.pendingApproval.create({
      data: {
        subAdminId: subAdminUserId,
        action: 'CREATE_ADMIN',
        entityType: 'User',
        payload: { shopName, name, email, password, slug: finalSlug, category: category || 'OTHER' },
      },
    });

    // Send email to super admin
    const superAdmin = await prisma.user.findFirst({ where: { role: 'SuperAdmin' } });
    if (superAdmin) {
      sendApprovalEmail({
        to: superAdmin.email,
        subAdminName: req.user!.email,
        action: 'Created new Admin',
        details: `Admin Name: ${name}\nEmail: ${email}\nShop: ${shopName}`,
        approvalId: approval.id,
      }).catch((err) => console.error('Email send failed:', err));
    }

    res.status(201).json({
      success: true,
      message: 'Admin creation request submitted for approval. Super admin has been notified.',
      approvalId: approval.id,
    });
  } catch (error) {
    console.error('subAdminCreateAdmin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const subAdminEditAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = toString(req.params.id);
    const { name, email } = req.body;
    const subAdminUserId = req.user!.userId;

    const subAdmin = await prisma.subAdmin.findUnique({ where: { userId: subAdminUserId } });
    if (!subAdmin || !(subAdmin.permissions as string[]).includes('edit_admin')) {
      res.status(403).json({ error: 'Not authorized to edit admins' });
      return;
    }

    const targetUser = await prisma.user.findUnique({ where: { id: userId } });
    if (!targetUser || targetUser.role !== 'Admin') {
      res.status(404).json({ error: 'Admin not found' });
      return;
    }

    const approval = await prisma.pendingApproval.create({
      data: {
        subAdminId: subAdminUserId,
        action: 'EDIT_ADMIN',
        entityType: 'User',
        entityId: userId,
        payload: { name, email, previousValues: { name: targetUser.name, email: targetUser.email } },
      },
    });

    const superAdmin = await prisma.user.findFirst({ where: { role: 'SuperAdmin' } });
    if (superAdmin) {
      sendApprovalEmail({
        to: superAdmin.email,
        subAdminName: req.user!.email,
        action: `Edit Admin: ${targetUser.name}`,
        details: `Changes requested:\nName: ${targetUser.name} → ${name || '(unchanged)'}\nEmail: ${targetUser.email} → ${email || '(unchanged)'}`,
        approvalId: approval.id,
      }).catch((err) => console.error('Email send failed:', err));
    }

    res.json({ success: true, message: 'Edit request submitted for approval', approvalId: approval.id });
  } catch (error) {
    console.error('subAdminEditAdmin error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const subAdminListAdmins = async (req: Request, res: Response): Promise<void> => {
  try {
    const subAdminUserId = req.user!.userId;
    const subAdmin = await prisma.subAdmin.findUnique({ where: { userId: subAdminUserId } });
    if (!subAdmin) {
      res.status(403).json({ error: 'Sub-admin profile not found' });
      return;
    }

    const shops = await prisma.shop.findMany({
      where: { managedBySubAdminId: subAdminUserId },
      select: { id: true },
    });
    const shopIds = shops.map((s) => s.id);

    const admins = await prisma.user.findMany({
      where: { shopId: { in: shopIds }, role: 'Admin' },
      select: {
        id: true, name: true, email: true, isActive: true, createdAt: true,
        shop: { select: { id: true, shopName: true, category: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json({ success: true, admins });
  } catch (error) {
    console.error('subAdminListAdmins error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const subAdminCreateShop = async (req: Request, res: Response): Promise<void> => {
  try {
    const { shopName, category } = req.body;
    const subAdminUserId = req.user!.userId;

    if (!shopName) {
      res.status(400).json({ error: 'shopName is required' });
      return;
    }

    const existingShop = await prisma.shop.findUnique({ where: { shopName } });
    if (existingShop) {
      res.status(409).json({ error: 'Shop name already taken' });
      return;
    }

    const slug = generateSlug(shopName);
    const finalSlug = (await prisma.shop.findUnique({ where: { slug } }))
      ? `${slug}-${Date.now().toString(36)}`
      : slug;

    const shop = await prisma.shop.create({
      data: {
        shopName,
        slug: finalSlug,
        category: category || 'OTHER',
        managedBySubAdminId: subAdminUserId,
        subscriptionPlan: 'NONE',
        subscriptionStatus: 'NONE',
      },
    });

    // Audit log
    await prisma.auditLog.create({
      data: {
        userId: subAdminUserId,
        action: 'CREATE_SHOP',
        entityType: 'Shop',
        entityId: shop.id,
        changes: { shopName, category },
        ipAddress: req.ip || null,
      },
    });

    // Notify super admin
    const superAdmin = await prisma.user.findFirst({ where: { role: 'SuperAdmin' } });
    if (superAdmin) {
      sendApprovalEmail({
        to: superAdmin.email,
        subAdminName: req.user!.email,
        action: 'Created new Shop',
        details: `Shop: ${shopName}\nCategory: ${category || 'OTHER'}`,
      }).catch((err) => console.error('Email send failed:', err));
    }

    res.status(201).json({ success: true, shop, message: 'Shop created. Super admin notified.' });
  } catch (error) {
    console.error('subAdminCreateShop error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const subAdminEditShop = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = toString(req.params.id);
    const { shopName, category } = req.body;
    const subAdminUserId = req.user!.userId;

    const shop = await prisma.shop.findUnique({ where: { id: shopId } });
    if (!shop || shop.managedBySubAdminId !== subAdminUserId) {
      res.status(404).json({ error: 'Shop not found or not managed by you' });
      return;
    }

    const updateData: Record<string, unknown> = {};
    if (shopName !== undefined) updateData.shopName = shopName;
    if (category !== undefined) updateData.category = category;

    const updated = await prisma.shop.update({ where: { id: shopId }, data: updateData as any });

    await prisma.auditLog.create({
      data: {
        userId: subAdminUserId,
        action: 'EDIT_SHOP',
        entityType: 'Shop',
        entityId: shopId,
        changes: { before: { shopName: shop.shopName, category: shop.category }, after: updateData } as any,
        ipAddress: req.ip || null,
      },
    });

    res.json({ success: true, shop: updated });
  } catch (error) {
    console.error('subAdminEditShop error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const subAdminListShops = async (req: Request, res: Response): Promise<void> => {
  try {
    const subAdminUserId = req.user!.userId;
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 20;

    const [shops, total] = await Promise.all([
      prisma.shop.findMany({
        where: { managedBySubAdminId: subAdminUserId },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          _count: { select: { users: true, products: true, sales: true } },
        },
      }),
      prisma.shop.count({ where: { managedBySubAdminId: subAdminUserId } }),
    ]);

    res.json({ success: true, shops, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('subAdminListShops error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ── Sub-Admin Plan Management ──────────────────────────────────────

export const subAdminChangePlan = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = toString(req.params.shopId);
    const { planId } = req.body;
    const subAdminUserId = req.user!.userId;

    if (!planId) {
      res.status(400).json({ error: 'planId is required' });
      return;
    }

    const shop = await prisma.shop.findUnique({ where: { id: shopId } });
    if (!shop || shop.managedBySubAdminId !== subAdminUserId) {
      res.status(404).json({ error: 'Shop not found or not managed by you' });
      return;
    }

    const oldPlan = shop.subscriptionPlan;
    const plan = await prisma.plan.findUnique({ where: { id: planId } });
    if (!plan) {
      res.status(404).json({ error: 'Plan not found' });
      return;
    }

    const approval = await prisma.pendingApproval.create({
      data: {
        subAdminId: subAdminUserId,
        action: 'CHANGE_PLAN',
        entityType: 'Shop',
        entityId: shopId,
        payload: { shopId, planId, oldPlan, newPlan: plan.name },
      },
    });

    const superAdmin = await prisma.user.findFirst({ where: { role: 'SuperAdmin' } });
    if (superAdmin) {
      sendApprovalEmail({
        to: superAdmin.email,
        subAdminName: req.user!.email,
        action: `Plan change: ${shop.shopName}`,
        details: `Shop: ${shop.shopName}\nOld Plan: ${oldPlan}\nNew Plan: ${plan.name}\nBilling: ${plan.billingCycle}`,
        approvalId: approval.id,
      }).catch((err) => console.error('Email send failed:', err));
    }

    res.json({
      success: true,
      message: 'Plan change request submitted for approval',
      approvalId: approval.id,
    });
  } catch (error) {
    console.error('subAdminChangePlan error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ── Sub-Admin Reports ──────────────────────────────────────────────

export const subAdminReports = async (req: Request, res: Response): Promise<void> => {
  try {
    const subAdminUserId = req.user!.userId;

    const shops = await prisma.shop.findMany({
      where: { managedBySubAdminId: subAdminUserId },
      select: { id: true },
    });
    const shopIds = shops.map((s) => s.id);

    const [totalRevenue, totalShops, totalUsers, categoryBreakdown] = await Promise.all([
      prisma.sale.aggregate({ where: { shopId: { in: shopIds } }, _sum: { total: true } }),
      prisma.shop.count({ where: { id: { in: shopIds } } }),
      prisma.user.count({ where: { shopId: { in: shopIds }, role: { not: 'SuperAdmin' } } }),
      prisma.shop.groupBy({
        by: ['category'],
        where: { id: { in: shopIds } },
        _count: { id: true },
      }),
    ]);

    res.json({
      success: true,
      totalRevenue: totalRevenue._sum.total || 0,
      totalShops,
      totalUsers,
      categoryBreakdown: categoryBreakdown.map((c) => ({ category: c.category, count: c._count.id })),
    });
  } catch (error) {
    console.error('subAdminReports error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
