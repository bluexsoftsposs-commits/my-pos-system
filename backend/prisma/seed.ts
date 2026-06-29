import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Create Demo Shop
  const shop = await prisma.shop.upsert({
    where: { shopName: 'BluexSofts Demo Shop' },
    update: {},
    create: {
      shopName: 'BluexSofts Demo Shop',
      subscriptionPlan: 'NONE',
      subscriptionStatus: 'NONE',
    },
  });

  console.log('✅ Shop created:', shop.shopName);

  // Create Admin
  const adminHash = await bcrypt.hash('admin123', 12);
  const admin = await prisma.user.upsert({
    where: { shopId_email: { shopId: shop.id, email: 'admin@demo.com' } },
    update: {},
    create: {
      shopId: shop.id,
      name: 'Admin User',
      email: 'admin@demo.com',
      passwordHash: adminHash,
      role: 'ADMIN',
    },
  });

  console.log('✅ Admin created:', admin.email);

  // Create Cashier
  const cashierHash = await bcrypt.hash('cashier123', 12);
  const cashier = await prisma.user.upsert({
    where: { shopId_email: { shopId: shop.id, email: 'cashier@demo.com' } },
    update: {},
    create: {
      shopId: shop.id,
      name: 'John Cashier',
      email: 'cashier@demo.com',
      passwordHash: cashierHash,
      role: 'CASHIER',
    },
  });

  console.log('✅ Cashier created:', cashier.email);

  // Create Super Admin Shop (hidden system shop)
  const superShop = await prisma.shop.upsert({
    where: { shopName: '__super_admin__' },
    update: {},
    create: {
      shopName: '__super_admin__',
      subscriptionPlan: 'PREMIUM',
      subscriptionStatus: 'ACTIVE',
    },
  });

  const superHash = await bcrypt.hash('super123', 12);
  await prisma.user.upsert({
    where: { shopId_email: { shopId: superShop.id, email: 'super@admin.com' } },
    update: {},
    create: {
      shopId: superShop.id,
      name: 'Super Admin',
      email: 'super@admin.com',
      passwordHash: superHash,
      role: 'SUPER_ADMIN',
    },
  });

  console.log('✅ Super Admin created: super@admin.com / super123');

  // Create Demo Products
  const products = [
    { name: 'Coca Cola 330ml', price: 1.5, stock: 100, category: 'Beverages', sku: 'BEV-001' },
    { name: 'Pepsi 330ml', price: 1.5, stock: 80, category: 'Beverages', sku: 'BEV-002' },
    { name: 'Mineral Water 500ml', price: 0.75, stock: 200, category: 'Beverages', sku: 'BEV-003' },
    { name: 'Energy Drink Red Bull', price: 2.99, stock: 50, category: 'Beverages', sku: 'BEV-004' },
    { name: 'Lays Classic Chips', price: 1.25, stock: 120, category: 'Snacks', sku: 'SNK-001' },
    { name: 'Pringles Original', price: 2.5, stock: 60, category: 'Snacks', sku: 'SNK-002' },
    { name: 'Oreo Cookies', price: 1.75, stock: 90, category: 'Snacks', sku: 'SNK-003' },
    { name: 'Kit Kat Chocolate', price: 1.0, stock: 150, category: 'Snacks', sku: 'SNK-004' },
    { name: 'White Bread Loaf', price: 2.25, stock: 40, category: 'Bakery', sku: 'BAK-001' },
    { name: 'Brown Bread Loaf', price: 2.5, stock: 35, category: 'Bakery', sku: 'BAK-002' },
    { name: 'Croissant', price: 1.5, stock: 25, category: 'Bakery', sku: 'BAK-003' },
    { name: 'Milk 1L', price: 1.2, stock: 75, category: 'Dairy', sku: 'DAI-001' },
    { name: 'Yogurt 500g', price: 1.8, stock: 50, category: 'Dairy', sku: 'DAI-002' },
    { name: 'Cheddar Cheese 200g', price: 3.5, stock: 30, category: 'Dairy', sku: 'DAI-003' },
    { name: 'Paracetamol 500mg', price: 3.99, stock: 60, category: 'Pharmacy', sku: 'PHA-001' },
    { name: 'Ibuprofen 400mg', price: 4.5, stock: 45, category: 'Pharmacy', sku: 'PHA-002' },
    { name: 'Hand Sanitizer 250ml', price: 2.75, stock: 80, category: 'Hygiene', sku: 'HYG-001' },
    { name: 'Face Mask (10 pack)', price: 3.0, stock: 100, category: 'Hygiene', sku: 'HYG-002' },
    { name: 'Cigarettes Marlboro', price: 5.5, stock: 200, category: 'Tobacco', sku: 'TOB-001' },
    { name: 'Lighter', price: 0.99, stock: 150, category: 'Accessories', sku: 'ACC-001' },
  ];

  for (const product of products) {
    await prisma.product.upsert({
      where: {
        // Use a composite check - find by shopId + sku
        id: `seed-${product.sku}`,
      },
      update: {},
      create: {
        id: `seed-${product.sku}`,
        shopId: shop.id,
        ...product,
      },
    });
  }

  console.log(`✅ ${products.length} products seeded`);
  console.log('\n🎉 Database seeded successfully!');
  console.log('\n📋 Demo Credentials:');
  console.log('   Shop Name: BluexSofts Demo Shop (NONE plan - buy a plan first!)');
  console.log('   Admin: admin@demo.com / admin123');
  console.log('   Cashier: cashier@demo.com / cashier123');
  console.log('   Super Admin: super@admin.com / super123\n');
}

main()
  .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
