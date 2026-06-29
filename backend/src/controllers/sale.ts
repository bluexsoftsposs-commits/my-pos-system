import { Request, Response } from 'express';
import prisma from '../config/db';

// GET /api/sales
export const getSales = async (req: Request, res: Response): Promise<void> => {
  try {
    const { from, to, limit } = req.query;

    const sales = await prisma.sale.findMany({
      where: {
        shopId: req.shopId,
        ...(from || to
          ? {
              createdAt: {
                ...(from ? { gte: new Date(from as string) } : {}),
                ...(to ? { lte: new Date(to as string) } : {}),
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
      take: limit ? parseInt(limit as string) : 100,
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
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Generate daily sales for last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 6);
    sevenDaysAgo.setHours(0, 0, 0, 0);

    const recentSales = await prisma.sale.findMany({
      where: {
        shopId: req.shopId,
        status: 'COMPLETED',
        createdAt: { gte: sevenDaysAgo },
      },
      select: { total: true, createdAt: true },
      orderBy: { createdAt: 'asc' },
    });

    // Build daily map
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
        where: { shopId: req.shopId, createdAt: { gte: today }, status: 'COMPLETED' },
        _sum: { total: true },
        _count: { id: true },
      }),
      prisma.sale.aggregate({
        where: { shopId: req.shopId, status: 'COMPLETED' },
        _sum: { total: true },
        _count: { id: true },
      }),
      prisma.saleItem.groupBy({
        by: ['productId'],
        where: { shopId: req.shopId },
        _sum: { quantity: true },
        orderBy: { _sum: { quantity: 'desc' } },
        take: 5,
      }),
    ]);

    // Get product names for top products
    const productIds = topProducts.map((p) => p.productId);
    const products = await prisma.product.findMany({
      where: { id: { in: productIds } },
      select: { id: true, name: true },
    });
    const productMap = Object.fromEntries(products.map((p) => [p.id, p.name]));

    res.json({
      today: {
        total: todaySales._sum.total || 0,
        count: todaySales._count.id,
      },
      allTime: {
        total: totalSales._sum.total || 0,
        count: totalSales._count.id,
      },
      dailySales,
      topProducts: topProducts.map((p) => ({
        productId: p.productId,
        name: productMap[p.productId] || 'Unknown',
        quantity: p._sum.quantity || 0,
      })),
    });
  } catch (error) {
    console.error('Get summary error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/sales/:id
export const getSale = async (req: Request, res: Response): Promise<void> => {
  try {
    const sale = await prisma.sale.findFirst({
      where: { id: req.params.id, shopId: req.shopId },
      include: {
        saleItems: {
          include: { product: true },
        },
        user: { select: { name: true, email: true } },
      },
    });

    if (!sale) {
      res.status(404).json({ error: 'Sale not found' });
      return;
    }

    res.json(sale);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/sales
export const createSale = async (req: Request, res: Response): Promise<void> => {
  try {
    const { items, paymentMethod, notes, tax, discount, createdAt } = req.body;

    if (!items || !Array.isArray(items) || items.length === 0) {
      res.status(400).json({ error: 'items array is required' });
      return;
    }

    // Verify all products belong to this shop and have enough stock
    const productIds = items.map((i: any) => i.productId);
    const products = await prisma.product.findMany({
      where: { id: { in: productIds }, shopId: req.shopId, isActive: true },
    });

    if (products.length !== productIds.length) {
      res.status(400).json({ error: 'One or more products not found or inactive' });
      return;
    }

    const productMap = Object.fromEntries(products.map((p) => [p.id, p]));

    // Check stock
    for (const item of items) {
      const product = productMap[item.productId];
      if (product.stock < item.quantity) {
        res.status(400).json({
          error: `Insufficient stock for ${product.name}. Available: ${product.stock}`,
        });
        return;
      }
    }

    // Calculate totals
    const subtotal = items.reduce(
      (sum: number, item: any) => sum + productMap[item.productId].price * item.quantity,
      0
    );
    const taxAmount = tax ? parseFloat(tax) : 0;
    const discountAmount = discount ? parseFloat(discount) : 0;
    const total = subtotal + taxAmount - discountAmount;

    // Create sale in transaction
    const sale = await prisma.$transaction(async (tx) => {
      const newSale = await tx.sale.create({
        data: {
          shopId: req.shopId!,
          userId: req.user!.userId,
          subtotal,
          tax: taxAmount,
          discount: discountAmount,
          total,
          paymentMethod: paymentMethod || 'CASH',
          notes: notes || '',
          status: 'COMPLETED',
          ...(createdAt ? { createdAt: new Date(createdAt) } : {}),
        },
      });

      // Create sale items
      await tx.saleItem.createMany({
        data: items.map((item: any) => ({
          shopId: req.shopId!,
          saleId: newSale.id,
          productId: item.productId,
          quantity: item.quantity,
          price: productMap[item.productId].price,
          subtotal: productMap[item.productId].price * item.quantity,
        })),
      });

      // Decrement stock for each product
      for (const item of items) {
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: { decrement: item.quantity } },
        });
      }

      return newSale;
    });

    const fullSale = await prisma.sale.findUnique({
      where: { id: sale.id },
      include: {
        saleItems: { include: { product: { select: { name: true, sku: true } } } },
        user: { select: { name: true } },
      },
    });

    res.status(201).json(fullSale);
  } catch (error) {
    console.error('Create sale error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/sales/bulk-sync (for offline sync)
export const bulkSyncSales = async (req: Request, res: Response): Promise<void> => {
  try {
    const { sales } = req.body;

    if (!Array.isArray(sales)) {
      res.status(400).json({ error: 'sales array is required' });
      return;
    }

    const results = [];
    for (const saleData of sales) {
      try {
        // Simulate single sale creation for each item in bulk
        const fakeReq = { ...req, body: saleData };
        // Instead we directly process:
        const { items, paymentMethod, notes, tax, discount, createdAt: saleCreatedAt } = saleData;
        if (!items || !Array.isArray(items) || items.length === 0) continue;

        const productIds = items.map((i: any) => i.productId);
        const products = await prisma.product.findMany({
          where: { id: { in: productIds }, shopId: req.shopId },
        });

        const productMap = Object.fromEntries(products.map((p) => [p.id, p]));
        const subtotal = items.reduce(
          (sum: number, item: any) =>
            sum + (productMap[item.productId]?.price || 0) * item.quantity,
          0
        );
        const taxAmt = parseFloat(tax) || 0;
        const discountAmt = parseFloat(discount) || 0;
        const total = subtotal + taxAmt - discountAmt;

        const sale = await prisma.$transaction(async (tx) => {
          const newSale = await tx.sale.create({
            data: {
              shopId: req.shopId!,
              userId: req.user!.userId,
              subtotal,
              tax: taxAmt,
              discount: discountAmt,
              total,
              paymentMethod: paymentMethod || 'CASH',
              notes: notes || '',
              status: 'COMPLETED',
              ...(saleCreatedAt ? { createdAt: new Date(saleCreatedAt) } : {}),
            },
          });

          await tx.saleItem.createMany({
            data: items.map((item: any) => ({
              shopId: req.shopId!,
              saleId: newSale.id,
              productId: item.productId,
              quantity: item.quantity,
              price: productMap[item.productId]?.price || 0,
              subtotal: (productMap[item.productId]?.price || 0) * item.quantity,
            })),
          });

          return newSale;
        });

        results.push({ success: true, saleId: sale.id, offlineId: saleData.offlineId });
      } catch (err) {
        results.push({ success: false, offlineId: saleData.offlineId, error: String(err) });
      }
    }

    res.json({ synced: results.filter((r) => r.success).length, results });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
