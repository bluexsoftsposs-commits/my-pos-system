import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// GET /api/invoices
export const getInvoices = async (req: Request, res: Response): Promise<void> => {
  try {
    const { from, to, search, limit } = req.query;
    const where: any = { shopId: req.shopId as string };

    if (from || to) {
      where.createdAt = {};
      if (from) where.createdAt.gte = new Date(toString(from));
      if (to) where.createdAt.lte = new Date(toString(to));
    }

    if (search) {
      where.invoiceNumber = { contains: toString(search) };
    }

    const invoices = await prisma.invoice.findMany({
      where,
      include: {
        sale: {
          include: {
            saleItems: { include: { product: { select: { name: true, sku: true, price: true } } } },
            user: { select: { name: true, email: true } },
          },
        },
        user: { select: { name: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit ? parseInt(toString(limit)) : 100,
    });
    res.json(invoices);
  } catch (error) {
    console.error('Get invoices error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/invoices/:id
export const getInvoice = async (req: Request, res: Response): Promise<void> => {
  try {
    const invoice = await prisma.invoice.findFirst({
      where: { id: toString(req.params.id), shopId: req.shopId as string },
      include: {
        sale: {
          include: {
            saleItems: { include: { product: { select: { name: true, sku: true, price: true } } } },
            user: { select: { name: true, email: true } },
          },
        },
        user: { select: { name: true, email: true } },
      },
    });
    if (!invoice) {
      res.status(404).json({ error: 'Invoice not found' });
      return;
    }
    res.json(invoice);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
