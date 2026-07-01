import { Request, Response } from 'express';
import prisma from '../config/db';

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
        invoice: true,
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

    const [todaySales, totalSales, topProducts, dailySales] = await Promise.all([
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
      prisma.$queryRawUnsafe<Array<{ date: string; total: number }>>(
        `SELECT DATE("createdAt") as date, SUM(total) as total FROM "Sale" WHERE "shopId" = $1 AND "status" = 'COMPLETED' AND "createdAt" >= $2 GROUP BY DATE("createdAt") ORDER BY date ASC`,
        shopId, sevenDaysAgo
      ),
    ]);
    const dailyMap: Record<string, number> = {};
    if (dailySales) {
      for (const row of dailySales) {
        const d = new Date(row.date).toISOString().split('T')[0];
        dailyMap[d] = Number(row.total);
      }
    }
    res.json({
      today: { total: todaySales._sum.total || 0, count: todaySales._count.id },
      allTime: { total: totalSales._sum.total || 0, count: totalSales._count.id },
      dailySales: dailyMap,
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
      include: { saleItems: { include: { product: true } }, user: { select: { name: true, email: true } }, invoice: true },
    });
    if (!sale) { res.status(404).json({ error: 'Sale not found' }); return; }
    res.json(sale);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Generate unique invoice number INV-YYYY-TIMESTAMP-UUID
async function generateInvoiceNumber(): Promise<string> {
  const { randomUUID } = await import('crypto');
  const timestamp = Date.now();
  const shortId = randomUUID().split('-')[0].toUpperCase();
  const year = new Date().getFullYear();
  return `INV-${year}-${timestamp}-${shortId}`;
}

// POST /api/sales
export const createSale = async (req: Request, res: Response): Promise<void> => {
  try {
    const { items, paymentMethod, notes, tax, discount } = req.body;
    const shopId = req.shopId as string;
    const userId = (req as any).user?.userId;

    if (!items || !Array.isArray(items) || items.length === 0) {
      res.status(400).json({ error: 'Items array is required' });
      return;
    }

    const newSale = await prisma.$transaction(async (tx: any) => {
      let subtotal = 0;
      const saleItemData = [];

      for (const item of items) {
        const product = await tx.product.findUnique({ where: { id: item.productId } });
        if (!product || product.shopId !== shopId) {
          throw new Error(`Product ${item.productId} not found`);
        }
        if (product.stock < item.quantity) {
          throw new Error(`Insufficient stock for ${product.name}`);
        }
        const itemSubtotal = product.price * item.quantity;
        subtotal += itemSubtotal;
        saleItemData.push({
          shopId,
          productId: item.productId,
          quantity: item.quantity,
          price: product.price,
          subtotal: itemSubtotal,
        });
      }

      const taxAmount = parseFloat(tax) || 0;
      const discountAmount = parseFloat(discount) || 0;
      const total = subtotal + taxAmount - discountAmount;

      const sale = await tx.sale.create({
        data: {
          shopId,
          userId,
          subtotal,
          tax: taxAmount,
          discount: discountAmount,
          total,
          paymentMethod: paymentMethod || 'CASH',
          status: 'COMPLETED',
          notes: notes || '',
        },
      });

      for (const itemData of saleItemData) {
        await tx.saleItem.create({
          data: {
            ...itemData,
            saleId: sale.id,
          },
        });
        await tx.product.update({
          where: { id: itemData.productId },
          data: { stock: { decrement: itemData.quantity } },
        });
      }

      // Generate invoice
      const invoiceNumber = await generateInvoiceNumber();
      await tx.invoice.create({
        data: {
          invoiceNumber,
          saleId: sale.id,
          shopId,
          userId,
          subtotal,
          tax: taxAmount,
          discount: discountAmount,
          total,
          paymentMethod: paymentMethod || 'CASH',
        },
      });

      return sale.id;
    }, { timeout: 60000, maxWait: 60000 });

    const sale = await prisma.sale.findUnique({
      where: { id: newSale },
      include: {
        saleItems: { include: { product: { select: { name: true, sku: true } } } },
        user: { select: { name: true, email: true } },
        invoice: true,
      },
    });

    res.status(201).json(sale);
  } catch (error: any) {
    console.error('Create sale error:', error);
    if (error.message && (error.message.includes('not found') || error.message.includes('Insufficient'))) {
      res.status(400).json({ error: error.message });
      return;
    }
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/sales/bulk-sync
export const bulkSyncSales = async (req: Request, res: Response): Promise<void> => {
  try {
    const { sales } = req.body;
    if (!Array.isArray(sales)) { res.status(400).json({ error: 'Array required' }); return; }
    const results = [];
    for (const saleData of sales) {
      try {
        const result = await prisma.$transaction(async (tx: any) => {
          const items = saleData.items || [];
          let subtotal = 0;
          const saleItemData = [];
          for (const item of items) {
            const product = await tx.product.findUnique({ where: { id: item.productId } });
            if (!product || product.shopId !== req.shopId) throw new Error(`Product ${item.productId} not found`);
            const itemSubtotal = product.price * item.quantity;
            subtotal += itemSubtotal;
            saleItemData.push({
              shopId: req.shopId as string,
              productId: item.productId,
              quantity: item.quantity,
              price: product.price,
              subtotal: itemSubtotal,
            });
          }
          const taxAmount = saleData.tax || 0;
          const discountAmount = saleData.discount || 0;
          const total = subtotal + taxAmount - discountAmount;
          const newSale = await tx.sale.create({
            data: {
              shopId: req.shopId,
              userId: (req as any).user?.userId,
              subtotal,
              tax: taxAmount,
              discount: discountAmount,
              total,
              paymentMethod: saleData.paymentMethod || 'CASH',
              status: 'COMPLETED',
              notes: saleData.notes || '',
            },
          });
          for (const itemData of saleItemData) {
            await tx.saleItem.create({ data: { ...itemData, saleId: newSale.id } });
            await tx.product.update({
              where: { id: itemData.productId },
              data: { stock: { decrement: itemData.quantity } },
            });
          }
          const invoiceNumber = await generateInvoiceNumber();
          await tx.invoice.create({
            data: {
              invoiceNumber,
              saleId: newSale.id,
              shopId: req.shopId as string,
              userId: (req as any).user?.userId,
              subtotal,
              tax: taxAmount,
              discount: discountAmount,
              total,
              paymentMethod: saleData.paymentMethod || 'CASH',
            },
          });
          return newSale.id;
        }, { timeout: 60000, maxWait: 60000 });
        results.push({ synced: true, id: result });
      } catch (e: any) {
        results.push({ synced: false, error: e.message });
      }
    }
    res.json({ synced: results.filter((r: any) => r.synced).length, results });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
