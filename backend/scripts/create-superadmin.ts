import 'dotenv/config';
import prisma from '../src/config/db';
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 12;
const EMAIL = 'ayyankingop56@gmail.com';
const PASSWORD = 'ayyanfaizan1122';
const NAME = 'Ayyan King';

async function main() {
  const shop = await prisma.shop.findUnique({
    where: { shopName: '__super_admin__' },
    select: { id: true, shopName: true },
  });

  if (!shop) {
    console.error('FATAL: __super_admin__ shop not found in the database.');
    console.error('You must create it first before adding SuperAdmin users.');
    process.exit(1);
  }

  const existing = await prisma.user.findUnique({
    where: { email: EMAIL },
    select: { id: true, email: true, role: true },
  });

  if (existing) {
    console.error(`User "${EMAIL}" already exists — skipping creation.`);
    console.log(`  id:    ${existing.id}`);
    console.log(`  email: ${existing.email}`);
    console.log(`  role:  ${existing.role}`);
    process.exit(0);
  }

  const passwordHash = await bcrypt.hash(PASSWORD, SALT_ROUNDS);

  const user = await prisma.user.create({
    data: {
      email: EMAIL,
      passwordHash,
      role: 'SuperAdmin',
      name: NAME,
      shopId: shop.id,
      isActive: true,
    },
    select: {
      id: true,
      email: true,
      role: true,
      shopId: true,
      isActive: true,
      name: true,
    },
  });

  console.log('SuperAdmin user created successfully:');
  console.log(`  id:       ${user.id}`);
  console.log(`  email:    ${user.email}`);
  console.log(`  role:     ${user.role}`);
  console.log(`  shopId:   ${user.shopId}`);
  console.log(`  isActive: ${user.isActive}`);
  console.log(`  name:     ${user.name}`);
  console.log('');
  console.log('Existing SuperAdmin accounts were NOT modified.');
}

main()
  .catch((err) => {
    console.error('Failed to create SuperAdmin user:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
