/// <reference types="node" />
import { PrismaClient } from '../app/generated/prisma';
import * as bcrypt from 'bcryptjs';

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
    {
      name: 'Premium Basmati Rice 5kg',
      description: 'Aged extra-long grain basmati rice, perfect for biryani and pulao.',
      price: 1850,
      stock: 50,
      category: 'Groceries',
      sku: 'GRC-001',
    },
    {
      name: 'Fresh Chicken Breast 1kg',
      description: 'Hormone-free, farm-fresh chicken breast cuts.',
      price: 920,
      stock: 30,
      category: 'Meat & Poultry',
      sku: 'MTP-001',
    },
    {
      name: 'Shan Biryani Masala 60g',
      description: 'Authentic blend of spices for delicious homemade biryani.',
      price: 145,
      stock: 120,
      category: 'Spices & Condiments',
      sku: 'SPC-001',
    },
    {
      name: 'Nestle Fruita Vitals Chaunsa Mango Juice 1L',
      description: '100% pure chaunsa mango juice with no added preservatives.',
      price: 310,
      stock: 80,
      category: 'Beverages',
      sku: 'BEV-001',
    },
    {
      name: 'Dawn Bread Large White',
      description: 'Soft and fluffy large white bread loaf, baked fresh daily.',
      price: 180,
      stock: 40,
      category: 'Bakery',
      sku: 'BAK-001',
    },
  ];

  for (const product of products) {
    await prisma.product.upsert({
      where: {
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

  console.log(`✅ ${products.length} PKR demo products seeded`);
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
