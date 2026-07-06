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
  triggerBackupManual,
  createPlan,
  updatePlan,
  deactivatePlan,
  listShopsSubscriptions,
  changeShopSubscription,
  deleteAdmin,
  deleteShop,
} from '../controllers/superadmin';

const router = Router();

// Cron-triggered backup (authenticated via CRON_SECRET query param, no JWT needed)
router.get('/backup', triggerBackup);

router.use(authenticate);
router.use(requireSuperAdmin);

// Manual backup trigger (superadmin-only, for testing without waiting 30 min)
router.post('/backup/trigger', triggerBackupManual);

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

// Plan management
router.post('/plans', createPlan);
router.put('/plans/:id', updatePlan);
router.delete('/plans/:id', deactivatePlan);

// Shop subscriptions
router.get('/shops-subscriptions', listShopsSubscriptions);
router.put('/shops/:shopId/subscription', changeShopSubscription);

// Delete endpoints
router.delete('/admins/:userId', deleteAdmin);
router.delete('/shops/:shopId', deleteShop);

export default router;
