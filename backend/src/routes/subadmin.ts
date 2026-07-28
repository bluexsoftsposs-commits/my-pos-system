import { Router } from 'express';
import { authenticate, requireSuperAdmin } from '../middlewares/auth';
import { requireSubAdmin } from '../middlewares/roleGuard';
import {
  createSubAdmin,
  listSubAdmins,
  updateSubAdmin,
  deleteSubAdmin,
  getSubAdminShops,
  subAdminCreateAdmin,
  subAdminEditAdmin,
  subAdminListAdmins,
  subAdminCreateShop,
  subAdminEditShop,
  subAdminListShops,
  subAdminChangePlan,
  subAdminReports,
} from '../controllers/subadmin';

const router = Router();

// ── Super Admin manages Sub-Admins ─────────────────────────────────
router.use(authenticate);

router.post('/', requireSuperAdmin, createSubAdmin);
router.get('/', requireSuperAdmin, listSubAdmins);
router.put('/:id', requireSuperAdmin, updateSubAdmin);
router.delete('/:id', requireSuperAdmin, deleteSubAdmin);
router.get('/:id/shops', requireSuperAdmin, getSubAdminShops);

// ── Sub-Admin actions ──────────────────────────────────────────────
router.post('/admins', requireSubAdmin, subAdminCreateAdmin);
router.put('/admins/:id', requireSubAdmin, subAdminEditAdmin);
router.get('/admins', requireSubAdmin, subAdminListAdmins);

router.post('/shops', requireSubAdmin, subAdminCreateShop);
router.put('/shops/:id', requireSubAdmin, subAdminEditShop);
router.get('/shops', requireSubAdmin, subAdminListShops);

router.put('/shops/:shopId/plan', requireSubAdmin, subAdminChangePlan);
router.get('/reports', requireSubAdmin, subAdminReports);

export default router;
