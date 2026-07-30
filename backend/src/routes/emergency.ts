import { Router } from 'express';
import { emergencyBouncer } from '../middlewares/emergencyBouncer';
import { authenticate } from '../middlewares/auth';
import { requireSuperAdmin } from '../middlewares/auth';
import {
  emergencyLogin,
  emergencyStatus,
  softLock,
  hardDelete,
  disableMaintenance,
  serveEmergencyPanel,
} from '../controllers/emergency';

const router = Router();

router.use(emergencyBouncer);

router.get('/', serveEmergencyPanel);

router.post('/login', emergencyLogin);

router.get('/status', authenticate, requireSuperAdmin, emergencyStatus);
router.post('/soft-lock', authenticate, requireSuperAdmin, softLock);
router.post('/hard-delete', authenticate, requireSuperAdmin, hardDelete);
router.post('/disable-maintenance', authenticate, requireSuperAdmin, disableMaintenance);

export default router;
