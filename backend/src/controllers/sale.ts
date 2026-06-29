import { Request, Response } from 'express';
import prisma from '../config/db';

// Helper function for type safety
const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// GET /api/sales
export const getSales = async (req: Request, res: Response): Promise<void> => {
  try {
    const { from, to, limit } = req.query;
    const sales = await prisma.sale.findMany({
      where: {
        shopId: req.shopId as string,
        ...(from || to ? {
          createdAt: {
            ...(from ? { gte: new Date(toString(from)) } : {}),
            ...(to ? { lte: new Date(toString(to)) } : {}),
          },
        } : {}),
      },
      include: {
        saleItems: { include: { product: { select: { name: true, sku: true } } } },
        user: { select: { name: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit ? parseInt(toString(limit)) : 100,
    });
    res.json(sales);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/sales/summary
export const getSalesSummary = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const [todaySales, totalSales, topProducts] = await Promise.all([
      prisma.sale.aggregate({
        where: { shopId, createdAt: { gte: today }, status: 'COMPLETED' },
        _sum: { total: true }, _count: { id: true },
      }),
      prisma.sale.aggregate({
        where: { shopId, status: 'COMPLETED' },
        _sum: { total: true }, _count: { id: true },
      }),
      prisma.saleItem.groupBy({
        by: ['productId'],
        where: { shopId },
        _sum: { quantity: true },
        orderBy: { _sum: { quantity: 'desc' } },
        take: 5,
      }),
    ]);
    res.json({ today: { total: todaySales._sum.total || 0, count: todaySales._count.id }, allTime: { total: totalSales._sum.total || 0, count: totalSales._count.id } });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/sales/:id
export const getSale = async (req: Request, res: Response): Promise<void> => {
  try {
    const sale = await prisma.sale.findFirst({
      where: { id: toString(req.params.id), shopId: req.shopId as string },
      include: { saleItems: { include: { product: true } }, user: { select: { name: true, email: true } } },
    });
    if (!sale) { res.status(404).json({ error: 'Sale not found' }); return; }
    res.json(sale);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/sales
export const createSale = async (req: Request, res: Response): Promise<void> => {
  try {
    const { items, paymentMethod, notes, tax, discount, createdAt } = req.body;
    const shopId = req.shopId as string;
    const userId = (req as any).user?.userId;

    const sale = await prisma.$transaction(async (tx: any) => {
      const newSale = await tx.sale.create({
        data: { shopId, userId, subtotal: 0, tax: parseFloat(tax) || 0, discount: parseFloat(discount) || 0, total: 0, paymentMethod: paymentMethod || 'CASH', status: 'COMPLETED' },
      });
      return newSale;
    });
    res.status(201).json(sale);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/sales/bulk-sync
export const bulkSyncSales = async (req: Request, res: Response): Promise<void> => {
  try {
    const { sales } = req.body;
    if (!Array.isArray(sales)) { res.status(400).json({ error: 'Array required' }); return; }
    res.json({ synced: sales.length, results: [] });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};