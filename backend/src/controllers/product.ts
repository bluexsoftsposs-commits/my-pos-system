import { Request, Response } from 'express';
import prisma from '../config/db';

// GET /api/products
export const getProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const { category, search } = req.query;

    const products = await prisma.product.findMany({
      where: {
        shopId: req.shopId,
        isActive: true,
        ...(category ? { category: category as string } : {}),
        ...(search
          ? {
            OR: [
              { name: { contains: search as string } },
              { sku: { contains: search as string } },
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
    const product = await prisma.product.findFirst({
      where: {
        id: Array.isArray(req.params.id) ? req.params.id[0] : req.params.id,
        shopId: req.shopId
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
        shopId: req.shopId!,
        name,
        description: description || '',
        price: parseFloat(price),
        stock: parseInt(stock) || 0,
        sku: sku || '',
        category: category || 'General',
        imageUrl: imageUrl || '',
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
    const existing = await prisma.product.findFirst({
      where: { id: req.params.id, shopId: req.shopId },
    });

    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }

    const { name, description, price, stock, sku, category, imageUrl, isActive } = req.body;

    const product = await prisma.product.update({
      where: { id: req.params.id },
      data: {
        ...(name !== undefined && { name }),
        ...(description !== undefined && { description }),
        ...(price !== undefined && { price: parseFloat(price) }),
        ...(stock !== undefined && { stock: parseInt(stock) }),
        ...(sku !== undefined && { sku }),
        ...(category !== undefined && { category }),
        ...(imageUrl !== undefined && { imageUrl }),
        ...(isActive !== undefined && { isActive }),
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
    const existing = await prisma.product.findFirst({
      where: { id: req.params.id, shopId: req.shopId },
    });

    if (!existing) {
      res.status(404).json({ error: 'Product not found' });
      return;
    }

    // Soft delete
    await prisma.product.update({
      where: { id: req.params.id },
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
      where: { shopId: req.shopId, isActive: true },
      select: { category: true },
      distinct: ['category'],
    });

    res.json(products.map((p) => p.category));
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
