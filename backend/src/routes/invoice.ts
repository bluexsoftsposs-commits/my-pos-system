import { Router } from 'express';
import { getInvoices, getInvoice } from '../controllers/invoice';
import { authenticate } from '../middlewares/auth';

const router = Router();

router.use(authenticate);

router.get('/', getInvoices);
router.get('/:id', getInvoice);

export default router;
