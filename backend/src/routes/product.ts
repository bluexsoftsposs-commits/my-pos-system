import { Router } from 'express';
import multer from 'multer';
import {
  getProducts,
  getProduct,
  createProduct,
  updateProduct,
  deleteProduct,
  getCategories,
  getProductByBarcode,
  uploadImage,
  getLowStockProducts,
} from '../controllers/product';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.use(authenticate);

router.get('/low-stock', getLowStockProducts);
router.get('/categories', getCategories);
router.get('/barcode/:barcode', getProductByBarcode);
router.get('/', getProducts);
router.get('/:id', getProduct);
router.post('/', requireAdmin, createProduct);
router.post('/upload-image', requireAdmin, upload.single('image'), uploadImage);
router.put('/:id', requireAdmin, updateProduct);
router.delete('/:id', requireAdmin, deleteProduct);

export default router;
