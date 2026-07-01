import { Request, Response } from 'express';
import prisma from '../config/db';

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

    const product = await prisma.product.create({
      data: {
        shopId: req.shopId as string,
        name,
        description: description || '',
        price: parseFloat(price),
        stock: parseInt(stock) || 0,
        sku: sku || '',
        category: category || 'General',
        imageUrl: imageUrl || '',
        barcode: req.body.barcode || null,
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

    const { name, description, price, stock, sku, category, imageUrl, isActive, barcode } = req.body;

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
    const barcode = req.params.barcode;
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