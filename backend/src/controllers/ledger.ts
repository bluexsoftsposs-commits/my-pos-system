import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

// GET /api/ledger/customers
export const getCustomers = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const customers = await prisma.customer.findMany({
      where: { shopId },
      orderBy: { name: 'asc' },
    });
    const result = customers.map((c) => ({
      ...c,
      balance: c.totalOwed - c.totalPaid,
    }));
    res.json(result);
  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/ledger/customers — find or create
export const createCustomer = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, phone } = req.body;
    const shopId = req.shopId as string;

    if (!name || !name.trim()) {
      res.status(400).json({ error: 'Customer name is required' });
      return;
    }

    let customer = await prisma.customer.findFirst({
      where: { shopId, name: name.trim(), phone: phone?.trim() || '' },
    });

    if (!customer) {
      customer = await prisma.customer.create({
        data: {
          shopId,
          name: name.trim(),
          phone: phone?.trim() || '',
        },
      });
    }

    res.json(customer);
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/ledger/customers/:id
export const getCustomer = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const customerId = toString(req.params.id);

    const customer = await prisma.customer.findFirst({
      where: { id: customerId, shopId },
      include: {
        entries: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!customer) {
      res.status(404).json({ error: 'Customer not found' });
      return;
    }

    res.json({
      ...customer,
      balance: customer.totalOwed - customer.totalPaid,
    });
  } catch (error) {
    console.error('Get customer error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/ledger/customers/:id/pay
export const recordPayment = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const customerId = toString(req.params.id);
    const { amount, note } = req.body;

    if (!amount || amount <= 0) {
      res.status(400).json({ error: 'Valid amount is required' });
      return;
    }

    const customer = await prisma.customer.findFirst({
      where: { id: customerId, shopId },
    });
    if (!customer) {
      res.status(404).json({ error: 'Customer not found' });
      return;
    }

    const result = await prisma.$transaction(async (tx: any) => {
      await tx.ledgerEntry.create({
        data: {
          shopId,
          customerId,
          type: 'CREDIT',
          amount,
          note: note || '',
        },
      });

      const updated = await tx.customer.update({
        where: { id: customerId },
        data: {
          totalPaid: { increment: amount },
          lastPaymentAt: new Date(),
        },
      });

      return updated;
    });

    res.json({
      ...result,
      balance: result.totalOwed - result.totalPaid,
    });
  } catch (error) {
    console.error('Record payment error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/ledger/manual-debit
export const createManualDebit = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const { customerId, amount, note } = req.body;

    if (!customerId) {
      res.status(400).json({ error: 'customerId is required' });
      return;
    }
    if (!amount || amount <= 0) {
      res.status(400).json({ error: 'Valid amount is required' });
      return;
    }

    const customer = await prisma.customer.findFirst({
      where: { id: customerId, shopId },
    });
    if (!customer) {
      res.status(404).json({ error: 'Customer not found' });
      return;
    }

    const result = await prisma.$transaction(async (tx: any) => {
      await tx.ledgerEntry.create({
        data: {
          shopId,
          customerId,
          type: 'DEBIT',
          amount,
          saleId: null,
          note: note || '',
        },
      });

      const updated = await tx.customer.update({
        where: { id: customerId },
        data: {
          totalOwed: { increment: amount },
        },
      });

      return updated;
    });

    res.status(201).json({
      ...result,
      balance: result.totalOwed - result.totalPaid,
    });
  } catch (error) {
    console.error('Create manual debit error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/ledger/outstanding
export const getOutstanding = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;

    const result = await prisma.customer.aggregate({
      where: { shopId },
      _sum: {
        totalOwed: true,
        totalPaid: true,
      },
    });

    const totalOwed = result._sum.totalOwed || 0;
    const totalPaid = result._sum.totalPaid || 0;

    res.json({
      totalOutstanding: totalOwed - totalPaid,
      totalOwed,
      totalPaid,
    });
  } catch (error) {
    console.error('Get outstanding error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
