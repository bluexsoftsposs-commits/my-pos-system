import { Router } from 'express';
import { authenticate, requireSuperAdmin } from '../middlewares/auth';
import {
  getDashboardStats,
  listShops,
  listUsers,
  toggleShopStatus,
  deleteUser,
  createShopUser,
  createAdmin,
  toggleAdminStatus,
  extendSubscription,
  updateShop,
  triggerBackup,
} from '../controllers/superadmin';

const router = Router();

// Cron-triggered backup (authenticated via CRON_SECRET query param, no JWT needed)
router.get('/backup', triggerBackup);

router.use(authenticate);
router.use(requireSuperAdmin);

router.get('/stats', getDashboardStats);
router.get('/shops', listShops);
router.get('/users', listUsers);
router.put('/shops/:id', updateShop);
router.put('/shops/:id/toggle', toggleShopStatus);
router.put('/shops/:id/extend', extendSubscription);
router.delete('/users/:id', deleteUser);
router.post('/users', createShopUser);
router.post('/create-admin', createAdmin);
router.put('/users/:id/toggle', toggleAdminStatus);

export default router;
