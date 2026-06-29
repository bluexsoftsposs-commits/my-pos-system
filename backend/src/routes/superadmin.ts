import { Router } from 'express';
import { authenticate, requireSuperAdmin } from '../middlewares/auth';
import {
  getDashboardStats,
  listShops,
  listUsers,
  toggleShopStatus,
  deleteUser,
  createShopUser,
  extendSubscription,
} from '../controllers/superadmin';

const router = Router();

router.use(authenticate);
router.use(requireSuperAdmin);

router.get('/stats', getDashboardStats);
router.get('/shops', listShops);
router.get('/users', listUsers);
router.put('/shops/:id/toggle', toggleShopStatus);
router.put('/shops/:id/extend', extendSubscription);
router.delete('/users/:id', deleteUser);
router.post('/users', createShopUser);

export default router;
