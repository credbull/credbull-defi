import { supabase } from './utils/helpers';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const adminEmail = process.env.ADMIN_EMAIL!;
    const adminPassword = process.env.ADMIN_PASSWORD!;

    const userA = 'usera@credbull.io';
    const userAPassword = 'usera123';

    const userB = process.env.BOB_EMAIL!;
    const userBPassword = process.env.BOB_PASSWORD!;

    const client = supabase({ admin: true });

    const adminAuth = await client.auth.signUp({
      email: adminEmail,
      password: adminPassword,
      options: {  },
    });
    if (adminAuth.error) throw adminAuth.error;

    await wait(1000);

    const userAAuth = await client.auth.signUp({
      email: userA,
      password: userAPassword,
      options: { },
    });

    if (userAAuth.error) throw userAAuth.error;

    await wait(1000);

    const userBAuth = await client.auth.signUp({
      email: userB,
      password: userBPassword,
      options: { },
    });

    if (userBAuth.error) throw userBAuth.error;

    console.log('Admin and user accounts created!');

    console.log('\n');
    console.log('=====================================');
    console.log('\n');

  }, 1000);
};
