import { Router } from 'express';
import { getUsers, createUser, updateUser, deleteUser } from '../controllers/user';
import { authenticate, requireAdmin } from '../middlewares/auth';

const router = Router();

router.use(authenticate);
router.use(requireAdmin);

router.get('/', getUsers);
router.post('/', createUser);
router.put('/:id', updateUser);
router.delete('/:id', deleteUser);

export default router;
