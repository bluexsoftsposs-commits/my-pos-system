import { Router } from 'express';
import { emergencyBouncer } from '../middlewares/emergencyBouncer';
import { authenticateEmergency, requireSuperAdmin } from '../middlewares/auth';
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

router.get('/status', authenticateEmergency, requireSuperAdmin, emergencyStatus);
router.post('/soft-lock', authenticateEmergency, requireSuperAdmin, softLock);
router.post('/hard-delete', authenticateEmergency, requireSuperAdmin, hardDelete);
router.post('/disable-maintenance', authenticateEmergency, requireSuperAdmin, disableMaintenance);

export default router;
