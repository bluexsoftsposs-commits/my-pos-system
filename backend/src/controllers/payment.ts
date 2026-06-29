import { Request, Response } from 'express';
import prisma from '../config/db';
import { initiateJazzCashPayment, handleJazzCashCallback } from '../services/jazzcash';
import { initiateEasyPaisaPayment, handleEasyPaisaCallback } from '../services/easypaisa';

const toString = (val: any): string => (Array.isArray(val) ? val[0] : (val as string));

const PLAN_PRICES: Record<string, number> = {
  BASIC: 5000,
  PLATINUM: 10000,
  PREMIUM: 15000,
};

const PLAN_DURATION_DAYS: Record<string, number> = {
  BASIC: 30,
  PLATINUM: 30,
  PREMIUM: 30,
};

export const getPlans = (_req: Request, res: Response): void => {
  res.json([
    { id: 'BASIC', name: 'Basic', price: 5000, priceLabel: 'PKR 5,000/month', popular: false,
      features: ['Up to 500 products', 'Basic reports', 'Email support', 'Single user'] },
    { id: 'PLATINUM', name: 'Platinum', price: 10000, priceLabel: 'PKR 10,000/month', popular: true,
      features: ['Up to 2,000 products', 'Advanced reports', 'Priority support', 'Up to 5 users', 'Offline mode'] },
    { id: 'PREMIUM', name: 'Premium', price: 15000, priceLabel: 'PKR 15,000/month', popular: false,
      features: ['Unlimited products', 'Advanced reports & charts', '24/7 support', 'Unlimited users', 'Offline mode', 'Receipt printing', 'API access'] },
  ]);
};

export const initiatePayment = async (req: Request, res: Response): Promise<void> => {
  try {
    const { plan, paymentMethod } = req.body;
    const shopId = req.shopId!;

    if (!plan || !paymentMethod) {
      res.status(400).json({ error: 'Plan and payment method are required' });
      return;
    }

    const price = PLAN_PRICES[plan as string];
    if (!price) {
      res.status(400).json({ error: 'Invalid plan. Choose BASIC, PLATINUM, or PREMIUM' });
      return;
    }

    if (!['JAZZCASH', 'EASIPAISA'].includes(paymentMethod as string)) {
      res.status(400).json({ error: 'Invalid payment method. Choose JAZZCASH or EASIPAISA' });
      return;
    }

    const existingPayment = await prisma.payment.findFirst({
      where: { shopId, status: 'PENDING' },
    });
    if (existingPayment) {
      res.status(400).json({
        error: 'A payment is already pending. Complete or cancel it first.',
        paymentId: existingPayment.id,
      });
      return;
    }

    const payment = await prisma.payment.create({
      data: {
        shopId,
        amount: price,
        plan: plan as string,
        paymentMethod: paymentMethod as string,
        transactionId: `TXN-${shopId.slice(0, 8)}-${Date.now()}`,
        status: 'PENDING',
      },
    });

    await prisma.shop.update({
      where: { id: shopId },
      data: { subscriptionPlan: plan as string, subscriptionStatus: 'PENDING' },
    });

    let result;
    if (paymentMethod === 'JAZZCASH') {
      result = await initiateJazzCashPayment({
        amount: price,
        orderId: payment.transactionId,
        description: `BluexSofts POS - ${plan} Plan`,
        paymentId: payment.id,
      });
    } else {
      result = await initiateEasyPaisaPayment({
        amount: price,
        orderId: payment.transactionId,
        description: `BluexSofts POS - ${plan} Plan`,
        paymentId: payment.id,
      });
    }

    if (result.success) {
      await prisma.payment.update({
        where: { id: payment.id },
        data: {
          transactionId: result.transactionId || payment.transactionId,
          status: result.simulated ? 'COMPLETED' : 'PENDING',
        },
      });

      if (result.simulated) {
        const endsAt = new Date();
        endsAt.setDate(endsAt.getDate() + (PLAN_DURATION_DAYS[plan as string] || 30));
        await prisma.shop.update({
          where: { id: shopId },
          data: { subscriptionPlan: plan as string, subscriptionStatus: 'ACTIVE', subscriptionEndsAt: endsAt },
        });

        res.json({
          success: true,
          simulated: true,
          message: `Payment simulated! ${plan} plan activated for ${PLAN_DURATION_DAYS[plan as string]} days.`,
          plan,
          paymentId: payment.id,
          endsAt,
        });
        return;
      }

      res.json({
        success: true,
        redirectUrl: result.redirectUrl,
        transactionId: result.transactionId,
        paymentId: payment.id,
        plan,
      });
    } else {
      await prisma.payment.update({ where: { id: payment.id }, data: { status: 'FAILED' } });
      await prisma.shop.update({ where: { id: shopId }, data: { subscriptionPlan: 'NONE', subscriptionStatus: 'NONE' } });
      res.status(400).json({ error: result.error || 'Payment initiation failed' });
    }
  } catch (error) {
    console.error('Payment initiation error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const jazzCashCallback = async (req: Request, res: Response): Promise<void> => {
  const result = await handleJazzCashCallback(req.body as Record<string, string>);
  if (result.success) {
    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:3000'}/payment/success?paymentId=${result.paymentId}`);
  } else {
    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:3000'}/payment/failed`);
  }
};

export const easyPaisaCallback = async (req: Request, res: Response): Promise<void> => {
  const result = await handleEasyPaisaCallback(req.body as Record<string, unknown>);
  if (result.success) {
    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:3000'}/payment/success?paymentId=${result.paymentId}`);
  } else {
    res.redirect(`${process.env.FLUTTER_APP_URL || 'http://localhost:3000'}/payment/failed`);
  }
};

export const checkPaymentStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const paymentId = toString(req.params.paymentId);
    const payment = await prisma.payment.findUnique({ where: { id: paymentId } });

    if (!payment) {
      res.status(404).json({ error: 'Payment not found' });
      return;
    }

    const completed = payment.status === 'COMPLETED';
    res.json({
      status: payment.status,
      completed,
      plan: payment.plan,
      paymentMethod: payment.paymentMethod,
    });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const verifyPayment = async (req: Request, res: Response): Promise<void> => {
  try {
    const paymentId = toString(req.params.paymentId);
    const shopId = req.shopId!;

    const payment = await prisma.payment.findFirst({
      where: { id: paymentId, shopId },
    });

    if (!payment) {
      res.status(404).json({ error: 'Payment not found' });
      return;
    }

    if (payment.status === 'COMPLETED') {
      const endsAt = new Date();
      endsAt.setDate(endsAt.getDate() + (PLAN_DURATION_DAYS[payment.plan] || 30));

      await prisma.shop.update({
        where: { id: shopId },
        data: { subscriptionPlan: payment.plan, subscriptionStatus: 'ACTIVE', subscriptionEndsAt: endsAt },
      });

      res.json({ success: true, message: 'Payment verified! Plan activated.', plan: payment.plan, endsAt });
    } else {
      res.json({ success: false, status: payment.status, message: 'Payment not yet completed.' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const getSubscriptionStatus = async (req: Request, res: Response): Promise<void> => {
  try {
    const shopId = req.shopId!;
    const shop = await prisma.shop.findUnique({
      where: { id: shopId },
      select: { subscriptionPlan: true, subscriptionStatus: true, subscriptionEndsAt: true },
    });
    const payment = await prisma.payment.findFirst({
      where: { shopId, status: 'COMPLETED' },
      orderBy: { createdAt: 'desc' },
      select: { amount: true, plan: true, paymentMethod: true, createdAt: true },
    });
    res.json({ shop, lastPayment: payment });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};
