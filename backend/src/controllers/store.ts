import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

/** GET /api/store/:slug/products */
export const getStoreProducts = async (req: Request, res: Response): Promise<void> => {
  try {
    const slug = toString(req.params.slug);

    const shop = await prisma.shop.findUnique({
      where: { slug },
      include: {
        subscriptions: {
          where: { status: 'active' },
          include: { plan: { select: { onlineStore: true } } },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Store not found' });
      return;
    }

    const sub = shop.subscriptions[0];
    const hasOnlineStore = sub?.plan?.onlineStore === true;

    if (!hasOnlineStore) {
      res.status(404).json({ error: 'This store is not available online', storeUnavailable: true });
      return;
    }

    const products = await prisma.product.findMany({
      where: {
        shopId: shop.id,
        isActive: true,
        isVisibleOnline: true,
        stock: { gt: 0 },
      },
      select: {
        id: true,
        name: true,
        description: true,
        price: true,
        stock: true,
        category: true,
        imageUrl: true,
        sku: true,
      },
      orderBy: { name: 'asc' },
    });

    res.json({ shop: { name: shop.shopName }, products });
  } catch (error) {
    console.error('getStoreProducts error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/** POST /api/store/:slug/orders */
export const createStoreOrder = async (req: Request, res: Response): Promise<void> => {
  try {
    const slug = toString(req.params.slug);
    const { customerName, customerPhone, customerAddress, items } = req.body;

    // Validate required fields
    if (!customerName || !customerName.trim()) {
      res.status(400).json({ error: 'Customer name is required' });
      return;
    }
    if (!customerPhone || !customerPhone.trim()) {
      res.status(400).json({ error: 'Customer phone is required' });
      return;
    }
    if (!customerAddress || !customerAddress.trim()) {
      res.status(400).json({ error: 'Customer address is required' });
      return;
    }
    if (!items || !Array.isArray(items) || items.length === 0) {
      res.status(400).json({ error: 'Items array is required with at least one item' });
      return;
    }

    const shop = await prisma.shop.findUnique({
      where: { slug },
      include: {
        subscriptions: {
          where: { status: 'active' },
          include: { plan: { select: { onlineStore: true } } },
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    if (!shop || shop.shopName === '__super_admin__') {
      res.status(404).json({ error: 'Store not found' });
      return;
    }

    const sub = shop.subscriptions[0];
    if (!sub?.plan?.onlineStore) {
      res.status(403).json({ error: 'This store is not available for online orders' });
      return;
    }

    // Create order atomically with stock validation
    const order = await prisma.$transaction(async (tx) => {
      let totalAmount = 0;
      const orderItemData: Array<{
        productId: string;
        quantity: number;
        price: number;
        subtotal: number;
      }> = [];

      for (const item of items) {
        const productId = toString(item.productId);
        const quantity = parseInt(item.quantity) || 0;

        if (quantity <= 0) {
          throw new Error(`Invalid quantity for product ${productId}`);
        }

        const product = await tx.product.findUnique({ where: { id: productId } });

        if (!product || product.shopId !== shop.id) {
          throw new Error(`Product ${productId} not found`);
        }

        if (!product.isActive || !product.isVisibleOnline) {
          throw new Error(`${product.name} is not available`);
        }

        if (product.stock < quantity) {
          throw new Error(`Insufficient stock for ${product.name}. Available: ${product.stock}, requested: ${quantity}`);
        }

        const subtotal = product.price * quantity;
        totalAmount += subtotal;

        orderItemData.push({
          productId: product.id,
          quantity,
          price: product.price,
          subtotal,
        });

        // Decrement stock
        await tx.product.update({
          where: { id: product.id },
          data: { stock: { decrement: quantity } },
        });
      }

      const newOrder = await tx.onlineOrder.create({
        data: {
          shopId: shop.id,
          customerName: customerName.trim(),
          customerPhone: customerPhone.trim(),
          customerAddress: customerAddress.trim(),
          totalAmount,
          source: 'online_store',
          items: {
            create: orderItemData,
          },
        },
        include: { items: true },
      });

      return newOrder;
    });

    res.status(201).json({
      success: true,
      order: {
        id: order.id,
        totalAmount: order.totalAmount,
        customerName: order.customerName,
        createdAt: order.createdAt,
      },
    });
  } catch (error: any) {
    console.error('createStoreOrder error:', error);
    const message = error.message || 'Internal server error';
    res.status(400).json({ error: message });
  }
};
