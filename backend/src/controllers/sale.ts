import { Request, Response } from 'express';
import prisma from '../config/db';

// Helper function to force string type
const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// GET /api/sales
export const getSales = async (req: Request, res: Response): Promise<void> => {
  try {
    const { from, to, limit } = req.query;

    const sales = await prisma.sale.findMany({
      where: {
        shopId: req.shopId as string,
        ...(from || to
          ? {
            createdAt: {
              ...(from ? { gte: new Date(toString(from)) } : {}),
              ...(to ? { lte: new Date(toString(to)) } : {}),
            },
          }
          : {}),
      },
      include: {
        saleItems: {
          include: { product: { select: { name: true, sku: true } } },
        },
        user: { select: { name: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit ? parseInt(toString(limit)) : 100,
    });

    res.json(sales);
  } catch (error) {
    console.error('Get sales error:', error);
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

    const recentSales = await prisma.sale.findMany({
      where: { shopId, status: 'COMPLETED', createdAt: { gte: sevenDaysAgo } },
      select: { total: true, createdAt: true },
      orderBy: { createdAt: 'asc' },
    });

    const dailySales: Record<string, number> = {};
    for (let i = 0; i < 7; i++) {
      const d = new Date(sevenDaysAgo);
      d.setDate(d.getDate() + i);
      const key = d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
      dailySales[key] = 0;
    }
    for (const sale of recentSales) {
      const key = sale.createdAt.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
      dailySales[key] = (dailySales[key] || 0) + Number(sale.total);
    }

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

    const productIds = topProducts.map((p) => p.productId);
    const products = await prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true },
    });
    const productMap = Object.fromEntries(products.map((p) => [p.id, p.name]));

    res.json({
      today: { total: todaySales._sum.total || 0, count: todaySales._count.id },
      allTime: { total: totalSales._sum.total || 0, count: totalSales._count.id },
      dailySales,
      topProducts: topProducts.map((p) => ({
        productId: p.productId,
        name: productMap[p.productId] || 'Unknown',
        quantity: p._sum.quantity || 0,
      })),
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/sales/:id
export const getSale = async (req: Request, res: Response): Promise<void> => {
  try {
    const sale = await prisma.sale.findFirst({
      where: { id: toString(req.params.id), shopId: req.shopId as string },
      include: {
        saleItems: { include: { product: true } },
        user: { select: { name: true, email: true } },
      },
    });

    if (!sale) { res.status(404).json({ error: 'Sale not found' }); return; }
    res.json(sale);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/sales (Baaki functions mein bhi `toString(id)` use karein)
// ... (CreateSale aur BulkSync mein bhi yahi pattern use karein)