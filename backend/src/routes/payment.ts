import { Router } from 'express';
import { authenticate } from '../middlewares/auth';
import {
  getPlans,
  initiatePayment,
  verifyPayment,
  getSubscriptionStatus,
  jazzCashCallback,
  easyPaisaCallback,
  checkPaymentStatus,
} from '../controllers/payment';

const router = Router();

router.get('/plans', getPlans);
router.post('/initiate', authenticate, initiatePayment);
router.post('/jazzcash/callback', jazzCashCallback);
router.post('/easypaisa/callback', easyPaisaCallback);
router.get('/status/:paymentId', checkPaymentStatus);
router.get('/verify/:paymentId', authenticate, verifyPayment);
router.get('/status', authenticate, getSubscriptionStatus);

export default router;
