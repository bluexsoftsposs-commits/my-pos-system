import { Router } from 'express';
import { getSales, getSale, createSale, bulkSyncSales, getSalesSummary } from '../controllers/sale';
import { authenticate } from '../middlewares/auth';

const router = Router();

router.use(authenticate);

router.get('/summary', getSalesSummary);
router.get('/', getSales);
router.get('/:id', getSale);
router.post('/', createSale);
router.post('/bulk-sync', bulkSyncSales);

export default router;
