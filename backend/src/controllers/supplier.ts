import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import prisma from '../config/db';
import { sendSupplierTransactionEmail } from '../services/email';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

export const registerSupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const {
      name, email, password, supplierName, businessName, gstNumber, panNumber,
      bankAccountNo, bankName, ifscCode, phone, address, city, state, pincode,
    } = req.body;

    if (!name || !email || !password || !supplierName || !businessName || !phone || !address) {
      res.status(400).json({ error: 'Missing required fields' });
      return;
    }

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      res.status(409).json({ error: 'Email already registered' });
      return;
    }

    const superAdminShop = await prisma.shop.findUnique({ where: { shopName: '__super_admin__' } });
    if (!superAdminShop) {
      res.status(500).json({ error: 'System error: super admin shop not found' });
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
          role: 'Supplier',
        },
      });

      const supplier = await tx.supplier.create({
        data: {
          userId: user.id,
          supplierName,
          businessName,
          gstNumber: gstNumber || null,
          panNumber: panNumber || null,
          bankAccountNo: bankAccountNo || null,
          bankName: bankName || null,
          ifscCode: ifscCode || null,
          phone,
          email,
          address,
          city: city || '',
          state: state || '',
          pincode: pincode || '',
        },
      });

      return { user, supplier };
    });

    res.status(201).json({
      success: true,
      message: 'Supplier registered successfully. Awaiting verification.',
      supplier: {
        id: result.supplier.id,
        supplierName: result.supplier.supplierName,
        businessName: result.supplier.businessName,
        isVerified: result.supplier.isVerified,
      },
    });
  } catch (error) {
    console.error('registerSupplier error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const supplier = await prisma.supplier.findUnique({
      where: { id },
      include: { user: { select: { id: true, name: true, email: true, isActive: true } } },
    });

    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    // If logged in as supplier, only allow viewing own profile
    if (req.user?.role === 'Supplier' && req.user?.userId !== supplier.userId) {
      res.status(403).json({ error: 'Access denied' });
      return;
    }

    res.json({ success: true, supplier });
  } catch (error) {
    console.error('getSupplier error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const updateSupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const updates = req.body;
    const supplier = await prisma.supplier.findUnique({ where: { id } });

    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    if (req.user?.role === 'Supplier' && req.user?.userId !== supplier.userId) {
      res.status(403).json({ error: 'Access denied' });
      return;
    }

    const allowedFields = [
      'supplierName', 'businessName', 'gstNumber', 'panNumber',
      'bankAccountNo', 'bankName', 'ifscCode', 'phone', 'email',
      'address', 'city', 'state', 'pincode',
    ];

    const data: Record<string, unknown> = {};
    for (const field of allowedFields) {
      if (updates[field] !== undefined) data[field] = updates[field];
    }

    if (Object.keys(data).length === 0) {
      res.status(400).json({ error: 'No valid fields to update' });
      return;
    }

    const updated = await prisma.supplier.update({ where: { id }, data: data as any });

    res.json({ success: true, supplier: updated });
  } catch (error) {
    console.error('updateSupplier error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSupplierLedger = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const supplier = await prisma.supplier.findUnique({ where: { id } });

    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    if (req.user?.role === 'Supplier' && req.user?.userId !== supplier.userId) {
      res.status(403).json({ error: 'Access denied' });
      return;
    }

    res.json({
      success: true,
      ledger: {
        totalSalesValue: supplier.totalSalesValue,
        totalPayments: supplier.totalPayments,
        pendingBalance: supplier.pendingBalance,
      },
    });
  } catch (error) {
    console.error('getSupplierLedger error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSupplierTransactions = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 20;
    const type = toString(req.query.type);

    const supplier = await prisma.supplier.findUnique({ where: { id } });
    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    if (req.user?.role === 'Supplier' && req.user?.userId !== supplier.userId) {
      res.status(403).json({ error: 'Access denied' });
      return;
    }

    const where: Record<string, unknown> = { supplierId: id };
    if (type && ['PURCHASE', 'PAYMENT', 'RETURN'].includes(type)) {
      where.type = type;
    }

    const [transactions, total] = await Promise.all([
      prisma.supplierTransaction.findMany({
        where: where as any,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.supplierTransaction.count({ where: where as any }),
    ]);

    res.json({
      success: true,
      transactions,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    });
  } catch (error) {
    console.error('getSupplierTransactions error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const createSupplierTransaction = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const { type, amount, description, referenceNo } = req.body;

    if (!type || amount === undefined) {
      res.status(400).json({ error: 'type and amount are required' });
      return;
    }

    if (!['PURCHASE', 'PAYMENT', 'RETURN'].includes(type)) {
      res.status(400).json({ error: 'type must be PURCHASE, PAYMENT, or RETURN' });
      return;
    }

    const supplier = await prisma.supplier.findUnique({ where: { id } });
    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    const result = await prisma.$transaction(async (tx) => {
      const transaction = await tx.supplierTransaction.create({
        data: {
          supplierId: id,
          type,
          amount,
          description: description || null,
          referenceNo: referenceNo || null,
          createdBy: req.user!.userId,
        },
      });

      let salesDelta = 0;
      let paymentsDelta = 0;
      let balanceDelta = 0;

      if (type === 'PURCHASE') {
        salesDelta = amount;
        balanceDelta = amount;
      } else if (type === 'PAYMENT') {
        paymentsDelta = amount;
        balanceDelta = -amount;
      } else if (type === 'RETURN') {
        salesDelta = -amount;
        balanceDelta = -amount;
      }

      const updated = await tx.supplier.update({
        where: { id },
        data: {
          totalSalesValue: { increment: salesDelta },
          totalPayments: { increment: paymentsDelta },
          pendingBalance: { increment: balanceDelta },
        },
      });

      return { transaction, updated };
    });

    // Send email notification
    sendSupplierTransactionEmail({
      to: supplier.email,
      supplierName: supplier.supplierName,
      type,
      amount,
      referenceNo: referenceNo || '',
      description: description || '',
      newBalance: result.updated.pendingBalance,
    }).catch((err) => console.error('Email send failed:', err));

    res.status(201).json({
      success: true,
      transaction: result.transaction,
      pendingBalance: result.updated.pendingBalance,
    });
  } catch (error) {
    console.error('createSupplierTransaction error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSupplierStats = async (req: Request, res: Response): Promise<void> => {
  try {
    const userId = req.user!.userId;

    const supplier = await prisma.supplier.findUnique({ where: { userId } });
    if (!supplier) {
      res.status(404).json({ error: 'Supplier profile not found' });
      return;
    }

    const recentTransactions = await prisma.supplierTransaction.findMany({
      where: { supplierId: supplier.id },
      orderBy: { createdAt: 'desc' },
      take: 5,
    });

    res.json({
      success: true,
      stats: {
        totalSalesValue: supplier.totalSalesValue,
        totalPayments: supplier.totalPayments,
        pendingBalance: supplier.pendingBalance,
      },
      recentTransactions,
    });
  } catch (error) {
    console.error('getSupplierStats error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ── Super Admin supplier management ────────────────────────────────

export const listAllSuppliers = async (req: Request, res: Response): Promise<void> => {
  try {
    const page = parseInt(toString(req.query.page)) || 1;
    const limit = parseInt(toString(req.query.limit)) || 20;
    const search = toString(req.query.search) || '';

    const where: Record<string, unknown> = {};
    if (search) {
      where.OR = [
        { supplierName: { contains: search } },
        { businessName: { contains: search } },
        { email: { contains: search } },
      ];
    }

    const [suppliers, total] = await Promise.all([
      prisma.supplier.findMany({
        where: where as any,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, email: true, isActive: true } },
          _count: { select: { transactions: true } },
        },
      }),
      prisma.supplier.count({ where: where as any }),
    ]);

    res.json({ success: true, suppliers, total, page, totalPages: Math.ceil(total / limit) });
  } catch (error) {
    console.error('listAllSuppliers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const verifySupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const supplier = await prisma.supplier.findUnique({ where: { id } });
    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    const updated = await prisma.supplier.update({
      where: { id },
      data: { isVerified: !supplier.isVerified },
    });

    res.json({
      success: true,
      isVerified: updated.isVerified,
      message: `Supplier ${updated.isVerified ? 'verified' : 'unverified'}`,
    });
  } catch (error) {
    console.error('verifySupplier error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const toggleSupplierStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const supplier = await prisma.supplier.findUnique({ where: { id } });
    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    const updated = await prisma.supplier.update({
      where: { id },
      data: { isActive: !supplier.isActive },
    });

    await prisma.user.update({
      where: { id: supplier.userId },
      data: { isActive: updated.isActive },
    });

    res.json({ success: true, isActive: updated.isActive });
  } catch (error) {
    console.error('toggleSupplierStatus error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// ── Shop-scoped supplier endpoints for Admin ───────────────────────

export const createShopSupplier = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const {
      supplierName, businessName, phone, email, address,
      city, state, pincode, gstNumber, panNumber,
    } = req.body;

    if (!supplierName || !phone) {
      res.status(400).json({ error: 'supplierName and phone are required' });
      return;
    }

    // Generate a unique email if none provided
    const supplierEmail = email || `supplier_${Date.now()}_${Math.random().toString(36).substring(2, 8)}@local`;

    const passwordHash = await bcrypt.hash(Math.random().toString(36), 12);

    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          shopId,
          email: supplierEmail,
          passwordHash,
          name: supplierName,
          role: 'Supplier',
          isActive: true,
        },
      });

      const supplier = await tx.supplier.create({
        data: {
          userId: user.id,
          supplierName: supplierName || '',
          businessName: businessName || '',
          gstNumber: gstNumber || null,
          panNumber: panNumber || null,
          phone,
          email: supplierEmail,
          address: address || '',
          city: city || '',
          state: state || '',
          pincode: pincode || '',
          isVerified: true,
        },
      });

      return { user, supplier };
    });

    res.status(201).json({
      success: true,
      message: 'Supplier created successfully',
      supplier: result.supplier,
    });
  } catch (error) {
    console.error('createShopSupplier error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getShopSuppliers = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const search = toString(req.query.search) || '';

    // Find suppliers linked via products
    const products = await prisma.product.findMany({
      where: {
        shopId,
        supplierId: { not: null },
        ...(search ? { name: { contains: search } } : {}),
      },
      select: { supplierId: true },
      distinct: ['supplierId'],
    });

    const productSupplierIds = products.map(p => p.supplierId).filter(Boolean) as string[];

    // Also find suppliers created directly by this shop (user.shopId matches)
    const shopUsers = await prisma.user.findMany({
      where: {
        shopId,
        role: 'Supplier',
        ...(search ? { name: { contains: search } } : {}),
      },
      select: { id: true },
    });
    const shopUserIds = shopUsers.map(u => u.id);

    const orConditions: Record<string, unknown>[] = [];
    if (productSupplierIds.length > 0) orConditions.push({ id: { in: productSupplierIds } });
    if (shopUserIds.length > 0) orConditions.push({ userId: { in: shopUserIds } });

    if (orConditions.length === 0) {
      res.json({ success: true, suppliers: [] });
      return;
    }

    const suppliers = await prisma.supplier.findMany({
      where: { OR: orConditions } as any,
      include: {
        user: { select: { id: true, name: true, email: true, isActive: true } },
        _count: { select: { transactions: true } },
      },
      orderBy: { supplierName: 'asc' },
    });

    res.json({ success: true, suppliers });
  } catch (error) {
    console.error('getShopSuppliers error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const createShopSupplierTransaction = async (req: Request, res: Response): Promise<void> => {
  try {
    const id = toString(req.params.id);
    const shopId = req.shopId as string;
    const { type, amount, description, referenceNo } = req.body;

    if (!type || amount === undefined) {
      res.status(400).json({ error: 'type and amount are required' });
      return;
    }

    if (!['PURCHASE', 'PAYMENT', 'RETURN'].includes(type)) {
      res.status(400).json({ error: 'type must be PURCHASE, PAYMENT, or RETURN' });
      return;
    }

    const supplier = await prisma.supplier.findUnique({ where: { id } });
    if (!supplier) {
      res.status(404).json({ error: 'Supplier not found' });
      return;
    }

    // Verify this supplier is linked to this shop (via product or direct creation)
    const linkedProduct = await prisma.product.findFirst({
      where: { shopId, supplierId: id },
    });
    const supplierUser = await prisma.user.findFirst({
      where: { id: supplier.userId, shopId },
    });
    if (!linkedProduct && !supplierUser && req.user?.role !== 'SuperAdmin') {
      res.status(403).json({ error: 'Supplier not linked to your shop' });
      return;
    }

    const result = await prisma.$transaction(async (tx) => {
      const transaction = await tx.supplierTransaction.create({
        data: {
          supplierId: id,
          type,
          amount,
          description: description || null,
          referenceNo: referenceNo || null,
          createdBy: req.user!.userId,
        },
      });

      let salesDelta = 0;
      let paymentsDelta = 0;
      let balanceDelta = 0;

      if (type === 'PURCHASE') {
        salesDelta = amount;
        balanceDelta = amount;
      } else if (type === 'PAYMENT') {
        paymentsDelta = amount;
        balanceDelta = -amount;
      } else if (type === 'RETURN') {
        salesDelta = -amount;
        balanceDelta = -amount;
      }

      const updated = await tx.supplier.update({
        where: { id },
        data: {
          totalSalesValue: { increment: salesDelta },
          totalPayments: { increment: paymentsDelta },
          pendingBalance: { increment: balanceDelta },
        },
      });

      return { transaction, updated };
    });

    res.status(201).json({
      success: true,
      transaction: result.transaction,
      pendingBalance: result.updated.pendingBalance,
    });
  } catch (error) {
    console.error('createShopSupplierTransaction error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
