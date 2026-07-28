import prisma from '../src/config/db';
import bcrypt from 'bcryptjs';

const SALT_ROUNDS = 12;
const EMAIL = 'superadmin@pos.com';
const NEW_PASSWORD = 'super123';

async function main() {
  const user = await prisma.user.findUnique({ where: { email: EMAIL } });
  if (!user) {
    console.error(`User with email "${EMAIL}" not found.`);
    process.exit(1);
  }

  const hashed = await bcrypt.hash(NEW_PASSWORD, SALT_ROUNDS);

  const updated = await prisma.user.update({
    where: { id: user.id },
    data: { passwordHash: hashed },
    select: { id: true, email: true, role: true },
  });

  console.log('Password reset successful:');
  console.log(`  id:    ${updated.id}`);
  console.log(`  email: ${updated.email}`);
  console.log(`  role:  ${updated.role}`);
}

main()
  .catch((err) => {
    console.error('Failed to reset password:', err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
