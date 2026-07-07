import { Router } from 'express';
import {
  getBranches,
  createBranch,
  deleteBranch,
  getBranchReport,
} from '../controllers/branch';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

router.use(authenticate);

router.get('/', getBranches);
router.post('/', requireAdmin, createBranch);
router.delete('/:id', requireAdmin, deleteBranch);
router.get('/:branchId/report', getBranchReport);

export default router;
