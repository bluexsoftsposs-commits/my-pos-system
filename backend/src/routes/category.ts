import { Router } from 'express';
import { authenticate, requireSuperAdmin } from '../middlewares/auth';
import {
  createCategory,
  listCategories,
  getCategoryDefaults,
} from '../controllers/category';

const router = Router();

// Public category listing
router.get('/', listCategories);

router.use(authenticate);

// Category defaults by shop type
router.get('/:category/defaults', getCategoryDefaults);

// Super admin creates categories
router.post('/', requireSuperAdmin, createCategory);

export default router;
