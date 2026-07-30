import { Router } from 'express';
import { authenticate, requireSuperAdmin } from '../middlewares/auth';
import { requireSupplier, requireRole, requireCashierSupplierAccess } from '../middlewares/roleGuard';
import {
  registerSupplier,
  getSupplier,
  updateSupplier,
  getSupplierLedger,
  getSupplierTransactions,
  createSupplierTransaction,
  getSupplierStats,
  listAllSuppliers,
  verifySupplier,
  toggleSupplierStatus,
  getShopSuppliers,
  createShopSupplier,
  createShopSupplierTransaction,
} from '../controllers/supplier';

const router = Router();

// Public registration
router.post('/register', registerSupplier);

router.use(authenticate);

// Supplier self-service
router.get('/stats', requireSupplier, getSupplierStats);

// Shop-scoped supplier endpoints (Admin / Cashier with permission)
router.get('/shop', requireRole('Admin', 'CASHIER', 'SuperAdmin'), requireCashierSupplierAccess, getShopSuppliers);
router.post('/shop/create', requireRole('Admin', 'CASHIER', 'SuperAdmin'), requireCashierSupplierAccess, createShopSupplier);
router.post('/:id/shop-transactions', requireRole('Admin', 'CASHIER', 'SuperAdmin'), requireCashierSupplierAccess, createShopSupplierTransaction);

// Per-supplier routes (access-checked inside controller)
router.get('/:id', getSupplier);
router.put('/:id', updateSupplier);
router.get('/:id/ledger', getSupplierLedger);
router.get('/:id/transactions', getSupplierTransactions);
router.post('/:id/transactions', createSupplierTransaction);

// Super admin management
router.get('/', requireSuperAdmin, listAllSuppliers);
router.put('/:id/verify', requireSuperAdmin, verifySupplier);
router.put('/:id/toggle-status', requireSuperAdmin, toggleSupplierStatus);

export default router;
