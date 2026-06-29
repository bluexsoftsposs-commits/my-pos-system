import crypto from 'crypto';
import prisma from '../config/db';

const JAZZCASH_MERCHANT_ID = process.env.JAZZCASH_MERCHANT_ID || '';
const JAZZCASH_PASSWORD = process.env.JAZZCASH_PASSWORD || '';
const JAZZCASH_INTEGRITY_SALT = process.env.JAZZCASH_INTEGRITY_SALT || '';
const JAZZCASH_RETURN_URL = process.env.JAZZCASH_RETURN_URL || 'http://localhost:3000/api/payment/jazzcash/callback';
const JAZZCASH_API_URL = process.env.JAZZCASH_API_URL || 'https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/MerchantRegTransactionRequest';

interface JazzCashResponse {
  pp_ResponseCode: string;
  pp_ResponseMessage: string;
  pp_RetreivalReferenceNo?: string;
  pp_RedirectURL?: string;
  pp_SecureHash?: string;
  [key: string]: unknown;
}

export async function initiateJazzCashPayment(params: {
  amount: number;
  orderId: string;
  description: string;
  paymentId: string;
}): Promise<{ success: boolean; redirectUrl?: string; error?: string; transactionId?: string; simulated?: boolean }> {
  if (!JAZZCASH_MERCHANT_ID || !JAZZCASH_INTEGRITY_SALT) {
    return simulatePayment(params);
  }

  try {
    const pp_TxnDateTime = new Date().toISOString().replace(/[-:T.Z]/g, '').slice(0, 14);
    const pp_TxnExpiryDateTime = new Date(Date.now() + 24 * 60 * 60 * 1000)
      .toISOString().replace(/[-:T.Z]/g, '').slice(0, 14);
    const pp_Amount = Math.round(params.amount * 100);

    const integrityString = [
      JAZZCASH_INTEGRITY_SALT,
      JAZZCASH_MERCHANT_ID,
      JAZZCASH_RETURN_URL,
      params.orderId,
      params.description,
      'PKR',
      pp_Amount.toString(),
      pp_TxnDateTime,
      pp_TxnExpiryDateTime,
    ].join('&');

    const pp_SecureHash = crypto.createHash('sha256').update(integrityString).digest('hex');

    const payload = {
      pp_Version: '2.0',
      pp_TxnType: 'MWALLET',
      pp_Language: 'EN',
      pp_MerchantID: JAZZCASH_MERCHANT_ID,
      pp_Password: JAZZCASH_PASSWORD,
      pp_TxnRefNo: params.orderId,
      pp_Amount: pp_Amount.toString(),
      pp_TxnCurrency: 'PKR',
      pp_TxnDateTime,
      pp_TxnExpiryDateTime,
      pp_BillReference: params.orderId,
      pp_Description: params.description,
      pp_ReturnURL: JAZZCASH_RETURN_URL,
      pp_SecureHash,
      ppmpf_1: params.paymentId,
      ppmpf_2: params.orderId,
      ppmpf_3: '3',
      ppmpf_4: '4',
      ppmpf_5: '5',
    };

    const response = await fetch(JAZZCASH_API_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    const data: JazzCashResponse = await response.json() as JazzCashResponse;

    if (data.pp_ResponseCode === '000') {
      return {
        success: true,
        redirectUrl: data.pp_RedirectURL || JAZZCASH_RETURN_URL,
        transactionId: data.pp_RetreivalReferenceNo || params.orderId,
      };
    }

    return {
      success: false,
      error: data.pp_ResponseMessage || 'JazzCash payment failed',
    };
  } catch (error) {
    console.error('JazzCash API error:', error);
    return { success: false, error: 'Failed to connect to JazzCash. Check your credentials.' };
  }
}

export async function handleJazzCashCallback(query: Record<string, string>): Promise<{
  success: boolean;
  transactionId?: string;
  paymentId?: string;
}> {
  try {
    const transactionId = query.pp_RetreivalReferenceNo || query.pp_TxnRefNo || '';
    const responseCode = query.pp_ResponseCode || '';
    const paymentId = query.ppmpf_1 || '';

    if (responseCode === '000') {
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
    console.error('JazzCash callback error:', error);
    return { success: false };
  }
}

async function simulatePayment(params: { amount: number; orderId: string; description: string; paymentId: string }) {
  console.log(`\n🔔 SIMULATED JAZZCASH PAYMENT`);
  console.log(`   Payment: ${params.description}`);
  console.log(`   Amount: PKR ${params.amount.toFixed(2)}`);
  console.log(`   Order: ${params.orderId}`);
  console.log(`   Status: COMPLETED (simulated)\n`);

  return {
    success: true,
    transactionId: `SIM-JC-${params.orderId}-${Date.now()}`,
    simulated: true,
  };
}
