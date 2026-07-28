import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

export const getAuditLogs = async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 50;
    const action = toString(req.query.action);
    const entityType = toString(req.query.entityType);

    const where: Record<string, unknown> = {};
    if (action) where.action = action;
    if (entityType) where.entityType = entityType;

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where: where as any,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, email: true, role: true } },
        },
      }),
      prisma.auditLog.count({ where: where as any }),
    ]);

    res.json({ success: true, logs, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('getAuditLogs error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getPendingApprovals = async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 20;

    const [approvals, total] = await Promise.all([
      prisma.pendingApproval.findMany({
        where: { status: 'PENDING' },
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          subAdmin: { select: { id: true, name: true, email: true } },
        },
      }),
      prisma.pendingApproval.count({ where: { status: 'PENDING' } }),
    ]);

    res.json({ success: true, approvals, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('getPendingApprovals error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const approveOrReject = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const { status, reviewNote } = req.body;

    if (!status || !['APPROVED', 'REJECTED'].includes(status)) {
      res.status(400).json({ error: 'status must be APPROVED or REJECTED' });
      return;
    }

    const approval = await prisma.pendingApproval.findUnique({ where: { id } });
    if (!approval) {
      res.status(404).json({ error: 'Approval request not found' });
      return;
    }

    if (approval.status !== 'PENDING') {
      res.status(400).json({ error: `Already ${approval.status.toLowerCase()}` });
      return;
    }

    const payload = approval.payload as Record<string, any> | null;

    if (status === 'APPROVED') {
      switch (approval.action) {
        case 'CREATE_ADMIN': {
          if (payload) {
            const { shopName, name, email, password, slug } = payload;
            const passwordHash = await (await import('bcryptjs')).hash(password, 12);

            await prisma.$transaction(async (tx) => {
              const shop = await tx.shop.create({
                data: {
                  shopName,
                  slug,
                  category: payload.category || 'OTHER',
                  subscriptionPlan: 'NONE',
                  subscriptionStatus: 'NONE',
                  managedBySubAdminId: approval.subAdminId,
                },
              });

              await tx.user.create({
                data: {
                  shopId: shop.id,
                  email,
                  passwordHash,
                  name,
                  role: 'Admin',
                },
              });

              // Seed demo products
              const demoProducts = [
                { name: 'Premium Basmati Rice 5kg', description: 'Aged extra-long grain basmati rice.', price: 1850, stock: 50, category: 'Groceries', sku: `DEMO-${shop.id.slice(0,4)}-001` },
                { name: 'Fresh Chicken Breast 1kg', description: 'Hormone-free, farm-fresh chicken breast.', price: 920, stock: 30, category: 'Meat & Poultry', sku: `DEMO-${shop.id.slice(0,4)}-002` },
                { name: 'Shan Biryani Masala 60g', description: 'Authentic blend of spices.', price: 145, stock: 120, category: 'Spices & Condiments', sku: `DEMO-${shop.id.slice(0,4)}-003` },
                { name: 'Nestle Fruita Vitals Chaunsa Mango Juice 1L', description: '100% pure mango juice.', price: 310, stock: 80, category: 'Beverages', sku: `DEMO-${shop.id.slice(0,4)}-004` },
                { name: 'Dawn Bread Large White', description: 'Soft and fluffy white bread.', price: 180, stock: 40, category: 'Bakery', sku: `DEMO-${shop.id.slice(0,4)}-005` },
              ];

              for (const product of demoProducts) {
                await tx.product.create({ data: { shopId: shop.id, ...product } });
              }
            });
          }
          break;
        }

        case 'EDIT_ADMIN': {
          if (payload && approval.entityId) {
            const updateData: Record<string, unknown> = {};
            if (payload.name) updateData.name = payload.name;
            if (payload.email) updateData.email = payload.email;
            if (Object.keys(updateData).length > 0) {
              await prisma.user.update({ where: { id: approval.entityId }, data: updateData as any });
            }
          }
          break;
        }

        case 'CHANGE_PLAN': {
          if (payload) {
            const { shopId, planId } = payload;
            const plan = await prisma.plan.findUnique({ where: { id: planId } });
            if (plan) {
              await prisma.shopSubscription.updateMany({
                where: { shopId, status: 'active' },
                data: { status: 'expired' },
              });

              await prisma.shopSubscription.create({
                data: { shopId, planId, status: 'active' },
              });

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
            }
          }
          break;
        }
      }
    }

    // Update approval status
    await prisma.pendingApproval.update({
      where: { id },
      data: {
        status,
        reviewedBy: req.user!.userId,
        reviewNote: reviewNote || null,
        reviewedAt: new Date(),
      },
    });

    // Audit log
    await prisma.auditLog.create({
      data: {
        userId: req.user!.userId,
        action: status === 'APPROVED' ? `APPROVE_${approval.action}` : `REJECT_${approval.action}`,
        entityType: 'PendingApproval',
        entityId: id,
        changes: { action: approval.action, status },
        ipAddress: req.ip || null,
      },
    });

    res.json({ success: true, message: `Request ${status.toLowerCase()} successfully` });
  } catch (error) {
    console.error('approveOrReject error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
