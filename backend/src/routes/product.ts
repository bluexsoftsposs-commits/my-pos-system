import { Router } from 'express';
import {
  getProducts,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct,
  getCategories,
  getProductByBarcode,
} from '../controllers/product';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

router.use(authenticate);

router.get('/categories', getCategories);
router.get('/barcode/:barcode', getProductByBarcode);
router.get('/', getProducts);
router.get('/:id', getProduct);
router.post('/', requireAdmin, createProduct);
router.put('/:id', requireAdmin, updateProduct);
router.delete('/:id', requireAdmin, deleteProduct);

export default router;
