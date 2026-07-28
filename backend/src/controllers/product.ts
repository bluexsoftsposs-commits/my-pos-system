import { Request, Response } from 'express';
import prisma from '../config/db';
import cloudinary from 'cloudinary';

cloudinary.v2.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Helper function to ensure single string
const toString = (value: any): string => {
  return Array.isArray(value) ? value[0] : (value as string);
};

// GET /api/products
export const getProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const { category, search } = req.query;

    const products = await prisma.product.findMany({
      where: {
        shopId: req.shopId as string,
        isActive: true,
        ...(category ? { category: toString(category) } : {}),
        ...(search
          ? {
            OR: [
              { name: { contains: toString(search) } },
              { sku: { contains: toString(search) } },
              { barcode: { contains: toString(search) } },
            ],
          }
          : {}),
      },
      orderBy: { name: 'asc' },
    });

    res.json(products);
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/products/:id
export const getProduct = async (req: Request, res: Response): Promise<void> => {
  try {
    const productId = toString(req.params.id);

    const product = await prisma.product.findFirst({
      where: {
        id: productId,
        shopId: req.shopId as string
      },
    });

    if (!product) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }

    res.json(product);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/products
export const createProduct = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, description, price, stock, sku, category, imageUrl } = req.body;

    if (!name || price === undefined) {
      res.status(400).json({ error: 'name and price are required' });
      return;
    }

    const shopId = req.shopId as string;

    // Enforce product limit from subscription plan
    const subscription = await prisma.shopSubscription.findFirst({
      where: { shopId, status: 'active' },
      include: { plan: { select: { name: true, productsLimit: true } } },
      orderBy: { createdAt: 'desc' },
    });

    if (subscription) {
      const limit = subscription.plan.productsLimit;
      const existingCount = await prisma.product.count({
        where: { shopId, isActive: true },
      });

      if (existingCount >= limit) {
        res.status(403).json({
          error: `Product limit reached. Your ${subscription.plan.name} plan allows ${limit} products. You have ${existingCount}/${limit}.`,
        });
        return;
      }
    }

    const product = await prisma.product.create({
      data: {
        shopId,
        name,
        description: description || '',
        price: parseFloat(price),
        stock: parseInt(stock) || 0,
        sku: sku || '',
        category: category || 'General',
        imageUrl: imageUrl || '',
        barcode: req.body.barcode || null,
        lowStockThreshold: parseInt(req.body.lowStockThreshold) || 5,
        batchNumber: req.body.batchNumber || null,
        expiryDate: req.body.expiryDate ? new Date(req.body.expiryDate) : null,
        manufacturer: req.body.manufacturer || null,
        composition: req.body.composition || null,
        dosageForm: req.body.dosageForm || null,
        packing: req.body.packing || null,
        isControlled: req.body.isControlled ?? false,
        supplierId: req.body.supplierId || null,
      },
    });

    res.status(201).json(product);
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// PUT /api/products/:id
export const updateProduct = async (req: Request, res: Response): Promise<void> => {
  try {
    const productId = toString(req.params.id);
    const shopId = req.shopId as string;

    const existing = await prisma.product.findFirst({
      where: { id: productId, shopId: shopId },
    });

    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }

    const { name, description, price, stock, sku, category, imageUrl, isActive, barcode, lowStockThreshold } = req.body;

    const product = await prisma.product.update({
      where: { id: productId },
      data: {
        ...(name !== undefined && { name }),
        ...(description !== undefined && { description }),
        ...(price !== undefined && { price: parseFloat(price) }),
        ...(stock !== undefined && { stock: parseInt(stock) }),
        ...(sku !== undefined && { sku }),
        ...(category !== undefined && { category }),
        ...(imageUrl !== undefined && { imageUrl }),
        ...(isActive !== undefined && { isActive }),
        ...(barcode !== undefined && { barcode: barcode || null }),
        ...(lowStockThreshold !== undefined && { lowStockThreshold: parseInt(lowStockThreshold) }),
        ...(req.body.batchNumber !== undefined && { batchNumber: req.body.batchNumber }),
        ...(req.body.expiryDate !== undefined && { expiryDate: req.body.expiryDate ? new Date(req.body.expiryDate) : null }),
        ...(req.body.manufacturer !== undefined && { manufacturer: req.body.manufacturer }),
        ...(req.body.composition !== undefined && { composition: req.body.composition }),
        ...(req.body.dosageForm !== undefined && { dosageForm: req.body.dosageForm }),
        ...(req.body.packing !== undefined && { packing: req.body.packing }),
        ...(req.body.isControlled !== undefined && { isControlled: req.body.isControlled }),
        ...(req.body.supplierId !== undefined && { supplierId: req.body.supplierId }),
      },
    });

    res.json(product);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// DELETE /api/products/:id
export const deleteProduct = async (req: Request, res: Response): Promise<void> => {
  try {
    const productId = toString(req.params.id);
    const shopId = req.shopId as string;

    const existing = await prisma.product.findFirst({
      where: { id: productId, shopId: shopId },
    });

    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }

    await prisma.product.update({
      where: { id: productId },
      data: { isActive: false },
    });

    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/products/low-stock — products where stock <= lowStockThreshold
export const getLowStockProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const products = await prisma.product.findMany({
      where: { shopId, isActive: true },
      select: { id: true, name: true, stock: true, lowStockThreshold: true, sku: true, price: true, imageUrl: true, shopId: true, createdAt: true },
    });
    const lowStock = products.filter((p) => p.stock <= p.lowStockThreshold);
    res.json({ count: lowStock.length, products: lowStock });
  } catch (error) {
    console.error('Get low stock error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/products/categories
export const getCategories = async (req: Request, res: Response): Promise<void> => {
  try {
    const products = await prisma.product.findMany({
      where: { shopId: req.shopId as string, isActive: true },
      select: { category: true },
      distinct: ['category'],
    });

    res.json(products.map((p) => p.category));
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

// GET /api/products/barcode/:barcode
export const getProductByBarcode = async (req: Request, res: Response): Promise<void> => {
  try {
    const barcode = toString(req.params.barcode);
    console.log('BARCODE LOOKUP - received:', JSON.stringify(barcode));

    if (!barcode) {
      res.status(400).json({ error: 'Barcode is required' });
      return;
    }

    const product = await prisma.product.findFirst({
      where: {
        barcode: barcode,
        shopId: req.shopId as string,
        isActive: true,
      },
    });

    if (!product) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }

    res.json(product);
  } catch (error) {
    console.error('Get product by barcode error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// POST /api/products/upload-image
export const uploadImage = async (req: Request, res: Response): Promise<void> => {
  try {
    if (!req.file) {
      res.status(400).json({ error: 'No image file provided' });
      return;
    }

    const { CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET } = process.env;
    if (!CLOUDINARY_CLOUD_NAME || !CLOUDINARY_API_KEY || !CLOUDINARY_API_SECRET) {
      res.status(500).json({ error: 'Cloudinary not configured on server' });
      return;
    }

    const result = await new Promise<any>((resolve, reject) => {
      const stream = cloudinary.v2.uploader.upload_stream(
        { folder: 'bluexsofts/products', resource_type: 'image' },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        },
      );
      stream.end(req.file!.buffer);
    });

    res.json({ imageUrl: result.secure_url });
  } catch (error) {
    console.error('Upload image error:', error);
    res.status(500).json({ error: 'Failed to upload image' });
  }
};

// ── Category-specific product endpoints ────────────────────────────

// Pharmacy: products expiring within N days
export const getExpiringProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const days = parseInt(toString(req.query.days)) || 30;
    const shopId = req.shopId as string;

    const threshold = new Date();
    threshold.setDate(threshold.getDate() + days);

    const products = await prisma.product.findMany({
      where: {
        shopId,
        isActive: true,
        expiryDate: { not: null, lte: threshold },
      },
      orderBy: { expiryDate: 'asc' },
    });

    res.json(products);
  } catch (error) {
    console.error('getExpiringProducts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Pharmacy: count of expiring products
export const getExpiringCount = async (req: Request, res: Response): Promise<void> => {
  try {
    const days = parseInt(toString(req.query.days)) || 30;
    const shopId = req.shopId as string;

    const threshold = new Date();
    threshold.setDate(threshold.getDate() + days);

    const count = await prisma.product.count({
      where: {
        shopId,
        isActive: true,
        expiryDate: { not: null, lte: threshold },
      },
    });

    res.json({ count });
  } catch (error) {
    console.error('getExpiringCount error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Electronics: warranty tracking
export const getWarrantyProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;

    const products = await prisma.product.findMany({
      where: {
        shopId,
        isActive: true,
        warrantyMonths: { not: null },
      },
      orderBy: { name: 'asc' },
    });

    // Compute warranty status for each product
    const now = new Date();
    const withWarranty = products.map(p => {
      let warrantyEnd: Date | null = null;
      let isExpired = false;
      let monthsLeft = 0;
      if (p.warrantyMonths && p.createdAt) {
        warrantyEnd = new Date(p.createdAt);
        warrantyEnd.setMonth(warrantyEnd.getMonth() + p.warrantyMonths);
        isExpired = now > warrantyEnd;
        monthsLeft = !isExpired
          ? Math.round((warrantyEnd.getTime() - now.getTime()) / (30 * 24 * 60 * 60 * 1000))
          : 0;
      }
      return { ...p, warrantyEnd: warrantyEnd?.toISOString(), isExpired, monthsLeft };
    });

    res.json(withWarranty);
  } catch (error) {
    console.error('getWarrantyProducts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Grocery: unit-based low stock alerts
export const getUnitLowStock = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;

    const products = await prisma.product.findMany({
      where: {
        shopId,
        isActive: true,
        unitType: { not: null },
      },
      orderBy: { name: 'asc' },
    });

    const lowStock = products.filter(p => p.stock <= (p.lowStockThreshold || 5));

    res.json(lowStock);
  } catch (error) {
    console.error('getUnitLowStock error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Restaurant: menu items view
export const getMenuItems = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;

    const items = await prisma.product.findMany({
      where: {
        shopId,
        isActive: true,
        isMenuItem: true,
      },
      orderBy: { name: 'asc' },
    });

    res.json(items);
  } catch (error) {
    console.error('getMenuItems error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

// Clothing: season-based inventory
export const getSeasonalProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const season = toString(req.query.season) || '';

    const where: Record<string, unknown> = {
      shopId,
      isActive: true,
    };
    if (season) where.season = season;

    const products = await prisma.product.findMany({
      where: where as any,
      orderBy: { name: 'asc' },
    });

    res.json(products);
  } catch (error) {
    console.error('getSeasonalProducts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};