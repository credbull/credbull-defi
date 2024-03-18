import { supabase } from './utils/helpers';

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const adminEmail = 'admin@cbl.com';
    const adminPassword = 'admin123';

    const userA = 'usera@cbl.com';
    const userAPassword = 'usera123';

    const userB = 'userb@cbl.com';
    const userBPassword = 'userb123';

    const client = supabase({ admin: true });

    const adminAuth = await client.auth.signUp({
      email: adminEmail,
      password: adminPassword,
      options: {  },
    });
    if (adminAuth.error) throw adminAuth.error;

    const userAAuth = await client.auth.signUp({
      email: userA,
      password: userAPassword,
      options: { },
    });

    if (userAAuth.error) throw userAAuth.error;

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
