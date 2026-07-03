import { PrismaClient } from '../app/generated/prisma';

const prisma = new PrismaClient();

const plans = [
  // ── Lite ──────────────────────────────────────────
  { name: 'Lite', billingCycle: 'MONTHLY', price: 1999, setupFee: 20999, originalSetupFee: 29999, salesPointsLimit: 1, productsLimit: 1000, fbrConnect: false, techSupport: true, onlineStore: false, updates: true },
  { name: 'Lite', billingCycle: 'ANNUAL', price: 19999, setupFee: 10499, originalSetupFee: 14999, salesPointsLimit: 1, productsLimit: 1000, fbrConnect: false, techSupport: true, onlineStore: false, updates: true },
  { name: 'Lite', billingCycle: 'ONETIME', price: 29999, setupFee: 20999, originalSetupFee: 29999, salesPointsLimit: 1, productsLimit: 1000, fbrConnect: false, techSupport: true, onlineStore: false, updates: true },
  // ── Plus ──────────────────────────────────────────
  { name: 'Plus', billingCycle: 'MONTHLY', price: 3999, setupFee: 13999, originalSetupFee: 19999, salesPointsLimit: 1, productsLimit: 2000, fbrConnect: true, techSupport: true, onlineStore: false, updates: true },
  { name: 'Plus', billingCycle: 'ANNUAL', price: 39999, setupFee: 6999, originalSetupFee: 9999, salesPointsLimit: 1, productsLimit: 2000, fbrConnect: true, techSupport: true, onlineStore: false, updates: true },
  { name: 'Plus', billingCycle: 'ONETIME', price: 39999, setupFee: 13999, originalSetupFee: 19999, salesPointsLimit: 1, productsLimit: 2000, fbrConnect: true, techSupport: true, onlineStore: false, updates: true },
  // ── Pro ───────────────────────────────────────────
  { name: 'Pro', billingCycle: 'MONTHLY', price: 6999, setupFee: 13999, originalSetupFee: 19999, salesPointsLimit: 1, productsLimit: 3000, fbrConnect: true, techSupport: true, onlineStore: true, updates: true },
  { name: 'Pro', billingCycle: 'ANNUAL', price: 69999, setupFee: 13999, originalSetupFee: 19999, salesPointsLimit: 1, productsLimit: 3000, fbrConnect: true, techSupport: true, onlineStore: true, updates: true },
  { name: 'Pro', billingCycle: 'ONETIME', price: 49999, setupFee: 13999, originalSetupFee: 19999, salesPointsLimit: 1, productsLimit: 3000, fbrConnect: true, techSupport: true, onlineStore: true, updates: true },
];

async function main() {
  console.log('Seeding plans...');
  for (const p of plans) {
    await prisma.plan.upsert({
      where: { name_billingCycle: { name: p.name, billingCycle: p.billingCycle } },
      update: p,
      create: p,
    });
    console.log(`  ✓ ${p.name} ${p.billingCycle} — PKR ${p.price.toLocaleString()}`);
  }
  console.log('Seed complete.');

  console.log('\nAssigning default subscriptions to shops without one...');
  const proMonthly = await prisma.plan.findFirst({
    where: { name: 'Pro', billingCycle: 'MONTHLY', isActive: true },
  });
  if (!proMonthly) {
    console.log('  ✗ Pro MONTHLY plan not found — skipping subscription seeding');
    return;
  }

  // Ensure all shops have slugs
  const allShops = await prisma.shop.findMany({
    where: { shopName: { not: '__super_admin__' } },
  });
  for (const shop of allShops) {
    if (!shop.slug) {
      let slug = shop.shopName
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .replace(/^-|-$/g, '');
      const existing = await prisma.shop.findUnique({ where: { slug } });
      if (existing) slug += `-${shop.id.substring(0, 6)}`;
      await prisma.shop.update({ where: { id: shop.id }, data: { slug } });
    }
  }

  const shops = await prisma.shop.findMany({
    where: {
      shopName: { not: '__super_admin__' },
      subscriptions: { none: {} },
    },
  });

  if (shops.length === 0) {
    console.log('  All shops already have a subscription.');
    return;
  }

  const endDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  let count = 0;
  for (const shop of shops) {
    await prisma.shopSubscription.create({
      data: {
        shopId: shop.id,
        planId: proMonthly.id,
        status: 'active',
        endDate,
      },
    });
    // Keep legacy Shop fields in sync
    await prisma.shop.update({
      where: { id: shop.id },
      data: {
        subscriptionPlan: 'Pro',
        subscriptionStatus: 'ACTIVE',
        subscriptionEndsAt: endDate,
      },
    });
    console.log(`  ✓ ${shop.shopName} → Pro MONTHLY (expires ${endDate.toISOString().split('T')[0]})`);
    count++;
  }
  console.log(`Assigned ${count} shop(s).`);
}

main()
  .catch((e) => {
    console.error('Seed failed:', e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
