import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// GET /api/reports/sales?period=daily|weekly|monthly&startDate=&endDate=
export const getSalesReport = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const period = toString(req.query.period || 'daily');
    const startDate = req.query.startDate ? new Date(toString(req.query.startDate)) : null;
    const endDate = req.query.endDate ? new Date(toString(req.query.endDate)) : null;

    // Default to last 30 days if no range provided
    const start = startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = endDate || new Date();

    start.setHours(0, 0, 0, 0);
    end.setHours(23, 59, 59, 999);

    const dateFilter = { gte: start, lte: end };

    const [totalAgg, dailyAgg, topByQty, topByRevenue] = await Promise.all([
      // Total sales sum + count
      prisma.sale.aggregate({
        where: { shopId, status: 'COMPLETED', createdAt: dateFilter },
        _sum: { total: true },
        _count: { id: true },
      }),

      // Breakdown by period
      prisma.$queryRawUnsafe<Array<{ label: string; total: number; count: bigint }>>(
        period === 'daily'
          ? `SELECT TO_CHAR("createdAt", 'YYYY-MM-DD') as label, SUM(total) as total, COUNT(id) as count FROM "Sale" WHERE "shopId" = $1 AND "status" = 'COMPLETED' AND "createdAt" >= $2::timestamp AND "createdAt" <= $3::timestamp GROUP BY label ORDER BY label ASC`
          : period === 'weekly'
            ? `SELECT TO_CHAR("createdAt", 'IYYY-IW') as label, SUM(total) as total, COUNT(id) as count FROM "Sale" WHERE "shopId" = $1 AND "status" = 'COMPLETED' AND "createdAt" >= $2::timestamp AND "createdAt" <= $3::timestamp GROUP BY label ORDER BY label ASC`
            : `SELECT TO_CHAR("createdAt", 'YYYY-MM') as label, SUM(total) as total, COUNT(id) as count FROM "Sale" WHERE "shopId" = $1 AND "status" = 'COMPLETED' AND "createdAt" >= $2::timestamp AND "createdAt" <= $3::timestamp GROUP BY label ORDER BY label ASC`,
        shopId,
        start.toISOString(),
        end.toISOString()
      ),

      // Top 5 by quantity sold
      prisma.saleItem.groupBy({
        by: ['productId'],
        where: { shopId, sale: { status: 'COMPLETED', createdAt: dateFilter } },
        _sum: { quantity: true },
        orderBy: { _sum: { quantity: 'desc' } },
        take: 5,
      }),

      // Top 5 by revenue
      prisma.saleItem.groupBy({
        by: ['productId'],
        where: { shopId, sale: { status: 'COMPLETED', createdAt: dateFilter } },
        _sum: { subtotal: true },
        orderBy: { _sum: { subtotal: 'desc' } },
        take: 5,
      }),
    ]);

    // Resolve product names
    const productIds = [...new Set([
      ...topByQty.map((s) => s.productId),
      ...topByRevenue.map((s) => s.productId),
    ])];

    const products = await prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true, sku: true, price: true },
    });

    const productMap = new Map(products.map((p) => [p.id, p]));

    const breakdown = (dailyAgg || []).map((row) => ({
      label: row.label,
      total: Number(row.total),
      count: Number(row.count),
    }));

    res.json({
      totalSales: totalAgg._sum.total || 0,
      transactionCount: totalAgg._count.id,
      breakdown,
      topByQuantity: topByQty.map((s) => ({
        productId: s.productId,
        name: productMap.get(s.productId)?.name || 'Unknown',
        sku: productMap.get(s.productId)?.sku || '',
        quantity: s._sum.quantity || 0,
      })),
      topByRevenue: topByRevenue.map((s) => ({
        productId: s.productId,
        name: productMap.get(s.productId)?.name || 'Unknown',
        sku: productMap.get(s.productId)?.sku || '',
        revenue: s._sum.subtotal || 0,
      })),
      period,
      startDate: start.toISOString(),
      endDate: end.toISOString(),
    });
  } catch (error) {
    console.error('Get sales report error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
