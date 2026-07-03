import { Router } from 'express';
import {
  getCustomers,
  createCustomer,
  getCustomer,
  recordPayment,
  createManualDebit,
  getOutstanding,
} from '../controllers/ledger';
import { authenticate } from '../middlewares/auth';

const router = Router();

router.use(authenticate);

router.get('/outstanding', getOutstanding);
router.get('/customers', getCustomers);
router.post('/customers', createCustomer);
router.get('/customers/:id', getCustomer);
router.post('/customers/:id/pay', recordPayment);
router.post('/manual-debit', createManualDebit);

export default router;
