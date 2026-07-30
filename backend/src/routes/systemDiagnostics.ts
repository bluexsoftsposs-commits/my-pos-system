import { Router } from 'express';
import { requestFilter } from '../middlewares/requestFilter';
import { authenticateEmergency, requireSuperAdmin } from '../middlewares/auth';
import {
  systemDiagnosticsLogin,
  systemDiagnosticsStatus,
  softLock,
  hardDelete,
  disableMaintenance,
  serveEmergencyPanel,
} from '../controllers/systemDiagnostics';

const router = Router();

router.use(requestFilter);

router.get('/', serveEmergencyPanel);

router.post('/login', systemDiagnosticsLogin);

router.get('/status', authenticateEmergency, requireSuperAdmin, systemDiagnosticsStatus);
router.post('/soft-lock', authenticateEmergency, requireSuperAdmin, softLock);
router.post('/hard-delete', authenticateEmergency, requireSuperAdmin, hardDelete);
router.post('/disable-maintenance', authenticateEmergency, requireSuperAdmin, disableMaintenance);

export default router;
