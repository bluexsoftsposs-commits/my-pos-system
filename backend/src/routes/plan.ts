import { Router } from 'express';
import { authenticate } from '../middlewares/auth';
import { listPlans, getShopSubscription } from '../controllers/plan';

const router = Router();

router.use(authenticate);

router.get('/', listPlans);
router.get('/shop/:shopId/subscription', getShopSubscription);

export default router;
