import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { getStoreProducts, createStoreOrder } from '../controllers/store';

const router = Router();

// Rate limiting: 60 requests/15min for product listing, 20 requests/15min for order creation
const productsLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 60,
  message: { error: 'Too many requests, please try again later' },
});

const ordersLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many order attempts, please try again later' },
});

router.get('/:slug/products', productsLimiter, getStoreProducts);
router.post('/:slug/orders', ordersLimiter, createStoreOrder);

export default router;
