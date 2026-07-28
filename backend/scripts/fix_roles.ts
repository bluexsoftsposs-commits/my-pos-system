import { PrismaClient } from '../app/generated/prisma';

const prisma = new PrismaClient({
  datasources: {
    db: {
      url: 'postgresql://neondb_owner:npg_Gb5zHWelTj2t@ep-bold-bird-atp3njg9.c-9.us-east-1.aws.neon.tech/neondb?sslmode=require',
    },
  },
});

async function main() {
  console.log('=== ROLE FIX MIGRATION SCRIPT ===\n');

  // 1. Query current role values for the 3 known test users
  const emails = ['superadmin@pos.com', 'admin@demo.com', 'cashier@demo.com'];
  const users = await prisma.user.findMany({
    where: { email: { in: emails } },
    select: { id: true, email: true, name: true, role: true },
  });

  console.log('Current role values for target users:');
  for (const u of users) {
    console.log(`  ${u.email.padEnd(25)} role: ${u.role}`);
  }

  // Check if superadmin@pos.com exists
  if (!users.find(u => u.email === 'superadmin@pos.com')) {
    console.log('\n⚠ superadmin@pos.com not found — checking super@admin.com...');
    const altUsers = await prisma.user.findMany({
      where: { email: 'super@admin.com' },
      select: { id: true, email: true, name: true, role: true },
    });
    for (const u of altUsers) {
      console.log(`  ${u.email.padEnd(25)} role: ${u.role}`);
    }
  }

  // 2. Find ALL users with old-format roles (ALL_CAPS)
  const oldRolePatterns = ['SUPER_ADMIN', 'ADMIN', 'SUB_ADMIN', 'SUPPLIER'];
  const oldRoleUsers = await prisma.user.findMany({
    where: { role: { in: oldRolePatterns } },
    select: { id: true, email: true, name: true, role: true },
  });

  console.log(`\nAll users with old-format roles (${oldRoleUsers.length} total):`);
  for (const u of oldRoleUsers) {
    console.log(`  ${u.email.padEnd(30)} ${u.name.padEnd(15)} role: ${u.role}`);
  }

  // 3. Define the role mapping
  const roleMap: Record<string, string> = {
    'SUPER_ADMIN': 'SuperAdmin',
    'ADMIN': 'Admin',
    'CASHIER': 'CASHIER',
    'SUB_ADMIN': 'SubAdmin',
    'SUPPLIER': 'Supplier',
  };

  // 4. Update all old-format roles
  console.log('\nUpdating roles...');
  let updatedCount = 0;
  for (const u of oldRoleUsers) {
    const newRole = roleMap[u.role];
    if (newRole && newRole !== u.role) {
      await prisma.user.update({
        where: { id: u.id },
        data: { role: newRole },
      });
      console.log(`  ✓ ${u.email.padEnd(30)} ${u.role.padEnd(15)} → ${newRole}`);
      updatedCount++;
    } else if (!newRole) {
      console.log(`  ✗ ${u.email.padEnd(30)} UNKNOWN ROLE: ${u.role} — skipped`);
    } else {
      console.log(`  - ${u.email.padEnd(30)} ${u.role} — already correct`);
    }
  }

  console.log(`\n=== Done. Updated ${updatedCount} user(s). ===`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
