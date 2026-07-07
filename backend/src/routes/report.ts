import { Router } from 'express';
import { getSalesReport } from '../controllers/report';
import { authenticate } from '../middlewares/auth';

const router = Router();

router.use(authenticate);

router.get('/sales', getSalesReport);

export default router;
