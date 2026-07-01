import prisma from '../config/db';

const EASIPAISA_MERCHANT_ID = process.env.EASIPAISA_MERCHANT_ID || '';
const EASIPAISA_API_KEY = process.env.EASIPAISA_API_KEY || '';
const EASIPAISA_RETURN_URL = process.env.EASIPAISA_RETURN_URL || 'https://my-pos-system-2.onrender.com/api/payment/easypaisa/callback';
const EASIPAISA_API_URL = process.env.EASIPAISA_API_URL || 'https://sandbox.easypaisa.com.pk/gateway/';

interface EasyPaisaResponse {
  status: string;
  transactionId?: string;
  redirectUrl?: string;
  message?: string;
  [key: string]: unknown;
}

export async function initiateEasyPaisaPayment(params: {
  amount: number;
  orderId: string;
  description: string;
  paymentId: string;
}): Promise<{ success: boolean; redirectUrl?: string; error?: string; transactionId?: string; simulated?: boolean }> {
  if (!EASIPAISA_MERCHANT_ID || !EASIPAISA_API_KEY) {
    return simulatePayment(params);
  }

  try {
    const payload = {
      merchantId: EASIPAISA_MERCHANT_ID,
      apiKey: EASIPAISA_API_KEY,
      orderId: params.orderId,
      amount: params.amount.toFixed(2),
      currency: 'PKR',
      description: params.description,
      returnUrl: EASIPAISA_RETURN_URL,
      paymentId: params.paymentId,
      timestamp: new Date().toISOString(),
    };

    const response = await fetch(EASIPAISA_API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    const data: EasyPaisaResponse = await response.json() as EasyPaisaResponse;

    if (data.status === 'SUCCESS') {
      return {
        success: true,
        redirectUrl: data.redirectUrl || EASIPAISA_RETURN_URL,
        transactionId: data.transactionId || params.orderId,
      };
    }

    return {
      success: false,
      error: data.message || 'EasyPaisa payment failed',
    };
  } catch (error) {
    console.error('EasyPaisa API error:', error);
    return { success: false, error: 'Failed to connect to EasyPaisa. Check your credentials.' };
  }
}

export async function handleEasyPaisaCallback(body: Record<string, unknown>): Promise<{
  success: boolean;
  transactionId?: string;
  paymentId?: string;
}> {
  try {
    const transactionId = (body.transactionId as string) || '';
    const status = (body.status as string) || '';
    const paymentId = (body.paymentId as string) || '';

    if (status === 'SUCCESS' || status === 'COMPLETED') {
      if (paymentId) {
        const payment = await prisma.payment.findUnique({ where: { id: paymentId } });
        if (payment && payment.status === 'PENDING') {
          const endsAt = new Date();
          endsAt.setDate(endsAt.getDate() + 30);

          await prisma.payment.update({
            where: { id: paymentId },
            data: { transactionId, status: 'COMPLETED' },
          });

          await prisma.shop.update({
            where: { id: payment.shopId },
            data: {
              subscriptionPlan: payment.plan,
              subscriptionStatus: 'ACTIVE',
              subscriptionEndsAt: endsAt,
            },
          });
        }
      }
      return { success: true, transactionId, paymentId };
    }

    return { success: false, transactionId, paymentId };
  } catch (error) {
    console.error('EasyPaisa callback error:', error);
    return { success: false };
  }
}

async function simulatePayment(params: { amount: number; orderId: string; description: string; paymentId: string }) {
  console.log(`\n🔔 SIMULATED EASIPAISA PAYMENT`);
  console.log(`   Payment: ${params.description}`);
  console.log(`   Amount: PKR ${params.amount.toFixed(2)}`);
  console.log(`   Order: ${params.orderId}`);
  console.log(`   Status: COMPLETED (simulated)\n`);

  return {
    success: true,
    transactionId: `SIM-EP-${params.orderId}-${Date.now()}`,
    simulated: true,
  };
}
