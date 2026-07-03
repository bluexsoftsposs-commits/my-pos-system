import { Request, Response } from 'express';
import prisma from '../config/db';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

/** GET /api/orders/online — list orders for the shop, filterable by status */
export const getOnlineOrders = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const status = toString(req.query.status);

    const where: Record<string, unknown> = { shopId };
    if (status) where.status = status;

    const orders = await prisma.onlineOrder.findMany({
      where: where as any,
      include: {
        items: {
          include: { product: { select: { name: true, imageUrl: true } } },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(orders);
  } catch (error) {
    console.error('getOnlineOrders error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/** PATCH /api/orders/online/:id/status — update order status */
export const updateOnlineOrderStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const orderId = toString(req.params.id);
    const { status } = req.body;

    const validStatuses = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'COMPLETED', 'CANCELLED'];
    if (!status || !validStatuses.includes(status)) {
      res.status(400).json({ error: `Invalid status. Must be one of: ${validStatuses.join(', ')}` });
      return;
    }

    const order = await prisma.onlineOrder.findFirst({
      where: { id: orderId, shopId },
      include: { items: true },
    });

    if (!order) {
      res.status(404).json({ error: 'Order not found' });
      return;
    }

    // If cancelling, restore stock atomically
    if (status === 'CANCELLED' && order.status !== 'CANCELLED') {
      await prisma.$transaction(async (tx) => {
        await tx.onlineOrder.update({
          where: { id: orderId },
          data: { status },
        });

        for (const item of order.items) {
          await tx.product.update({
            where: { id: item.productId },
            data: { stock: { increment: item.quantity } },
          });
        }
      });
    } else {
      await prisma.onlineOrder.update({
        where: { id: orderId },
        data: { status },
      });
    }

    const updated = await prisma.onlineOrder.findUnique({
      where: { id: orderId },
      include: {
        items: {
          include: { product: { select: { name: true, imageUrl: true } } },
        },
      },
    });

    res.json(updated);
  } catch (error) {
    console.error('updateOnlineOrderStatus error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

/** GET /api/orders/online/pending-count — get pending order count for badge */
export const getPendingOrderCount = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId as string;
    const count = await prisma.onlineOrder.count({
      where: { shopId, status: 'PENDING' },
    });
    res.json({ count });
  } catch (error) {
    console.error('getPendingOrderCount error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
