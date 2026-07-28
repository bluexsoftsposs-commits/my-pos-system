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
  getExpiringProducts,
  getExpiringCount,
  getWarrantyProducts,
  getUnitLowStock,
  getMenuItems,
  getSeasonalProducts,
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

// Category-specific product endpoints
router.get('/expiring', authenticate, getExpiringProducts);
router.get('/expiring-count', authenticate, getExpiringCount);
router.get('/warranty', authenticate, getWarrantyProducts);
router.get('/unit-low-stock', authenticate, getUnitLowStock);
router.get('/menu-items', authenticate, getMenuItems);
router.get('/seasonal', authenticate, getSeasonalProducts);

export default router;
