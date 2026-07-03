import { Router } from 'express';
import { authenticate } from '../middlewares/auth';
import { getOnlineOrders, updateOnlineOrderStatus, getPendingOrderCount } from '../controllers/onlineOrder';

const router = Router();

router.use(authenticate);

router.get('/', getOnlineOrders);
router.get('/pending-count', getPendingOrderCount);
router.patch('/:id/status', updateOnlineOrderStatus);

export default router;
