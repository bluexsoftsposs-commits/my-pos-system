import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// GET /api/branches
export const getBranches = async (req: Request, res: Response): Promise<void> => {
  try {
    const branches = await prisma.branch.findMany({
      where: { shopId: req.shopId as string },
      orderBy: { name: 'asc' },
    });
    res.json(branches);
  } catch (error) {
    console.error('Get branches error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/branches
export const createBranch = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, address, phone } = req.body;
    if (!name || !name.trim()) {
      res.status(400).json({ error: 'Branch name is required' });
      return;
    }
    const branch = await prisma.branch.create({
      data: {
        shopId: req.shopId as string,
        name: name.trim(),
        address: address || '',
        phone: phone || '',
      },
    });
    res.status(201).json(branch);
  } catch (error: any) {
    if (error.code === 'P2002') {
      res.status(409).json({ error: 'A branch with this name already exists' });
      return;
    }
    console.error('Create branch error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// DELETE /api/branches/:id
export const deleteBranch = async (req: Request, res: Response): Promise<void> => {
  try {
    const branchId = toString(req.params.id);
    const existing = await prisma.branch.findFirst({
      where: { id: branchId, shopId: req.shopId as string },
    });
    if (!existing) {
      res.status(404).json({ error: 'Branch not found' });
      return;
    }
    await prisma.branch.delete({ where: { id: branchId } });
    res.json({ message: 'Branch deleted' });
  } catch (error) {
    console.error('Delete branch error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/branches/:branchId/report
export const getBranchReport = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const branchId = toString(req.params.branchId);

    const branch = await prisma.branch.findFirst({
      where: { id: branchId, shopId },
    });
    if (!branch) {
      res.status(404).json({ error: 'Branch not found' });
      return;
    }

    const where = { shopId, branchId, status: 'COMPLETED' } as any;
    const [totalSales, saleCount, recentSales] = await Promise.all([
      prisma.sale.aggregate({ where, _sum: { total: true } }),
      prisma.sale.count({ where }),
      prisma.sale.findMany({
        where: { shopId, branchId } as any,
        orderBy: { createdAt: 'desc' },
        take: 10,
        include: {
          saleItems: { include: { product: { select: { name: true } } } },
          user: { select: { name: true } },
        },
      }),
    ]);

    res.json({
      branch: { id: branch.id, name: branch.name, address: branch.address, phone: branch.phone },
      totalRevenue: totalSales._sum.total || 0,
      transactionCount: saleCount,
      recentSales: (recentSales as any[]).map((s: any) => ({
        id: s.id,
        total: s.total,
        paymentMethod: s.paymentMethod,
        createdAt: s.createdAt,
        user: s.user?.name || 'Unknown',
        items: (s.saleItems || []).map((si: any) => ({
          name: si.product?.name || 'Unknown',
          quantity: si.quantity,
          price: si.price,
        })),
      })),
    });
  } catch (error) {
    console.error('Get branch report error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
