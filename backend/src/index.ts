import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import authRoutes from './routes/auth';
import productRoutes from './routes/product';
import saleRoutes from './routes/sale';
import invoiceRoutes from './routes/invoice';
import userRoutes from './routes/user';
import paymentRoutes from './routes/payment';
import superAdminRoutes from './routes/superadmin';
import ledgerRoutes from './routes/ledger';
import planRoutes from './routes/plan';
import storeRoutes from './routes/store';
import onlineOrderRoutes from './routes/onlineOrder';
import branchRoutes from './routes/branch';
import reportRoutes from './routes/report';
import subAdminRoutes from './routes/subadmin';
import supplierRoutes from './routes/supplier';
import auditRoutes from './routes/audit';
import categoryRoutes from './routes/category';
import emergencyRoutes from './routes/emergency';
import { maintenanceLock } from './middlewares/maintenanceLock';
import path from 'path';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: '*', // In production, specify your Flutter app's origin
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

process.env.ORIGINAL_JWT_SECRET = process.env.JWT_SECRET;

const EMERGENCY_PREFIX = process.env.EMERGENCY_ROUTE || '/api/.sys/ops';

// Health check
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'BluexSofts POS API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

app.use(maintenanceLock(EMERGENCY_PREFIX));

// API Routes
app.use(EMERGENCY_PREFIX, emergencyRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/sales', saleRoutes);
app.use('/api/invoices', invoiceRoutes);
app.use('/api/users', userRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/superadmin', superAdminRoutes);
app.use('/api/ledger', ledgerRoutes);
app.use('/api/plans', planRoutes);
app.use('/api/store', storeRoutes);
app.use('/api/orders/online', onlineOrderRoutes);
app.use('/api/branches', branchRoutes);
app.use('/api/reports', reportRoutes);
app.use('/api/subadmins', subAdminRoutes);
app.use('/api/suppliers', supplierRoutes);
app.use('/api/audit', auditRoutes);
app.use('/api/categories', categoryRoutes);

// Serve the storefront HTML at /store/:slug
app.get('/store/:slug', (_req, res) => {
  res.sendFile(path.join(__dirname, '..', 'views', 'storefront.html'));
});

// 404 handler
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

import prisma from './config/db';
import { startBackupScheduler } from './services/backup-scheduler';
import { initEmergencyState } from './services/emergencyState';

const server = app.listen(PORT, async () => {
  console.log(`\n🚀 BluexSofts POS Server running on port ${PORT}`);
  console.log(`📡 API: http://localhost:${PORT}/api`);
  console.log(`❤️  Health: http://localhost:${PORT}/health\n`);

  await initEmergencyState();

  // Start automated backups (30-min cycle, stored in Cloudinary)
  startBackupScheduler();
});

// Graceful shutdown: disconnect Prisma pool on server stop
async function shutdown(signal: string) {
  console.log(`\n${signal} received — shutting down gracefully...`);
  server.close(async () => {
    await prisma.$disconnect();
    console.log('Prisma disconnected. Goodbye.');
    process.exit(0);
  });
  // Force exit after 10s if graceful shutdown hangs
  setTimeout(() => {
    console.error('Forced exit after timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

export default app;
