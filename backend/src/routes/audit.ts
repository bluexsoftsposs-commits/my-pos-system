import { Router } from 'express';
import { authenticate, requireSuperAdmin } from '../middlewares/auth';
import {
  getAuditLogs,
  getPendingApprovals,
  approveOrReject,
} from '../controllers/audit';

const router = Router();

router.use(authenticate);
router.use(requireSuperAdmin);

router.get('/logs', getAuditLogs);
router.get('/pending-approvals', getPendingApprovals);
router.put('/pending-approvals/:id', approveOrReject);

export default router;
