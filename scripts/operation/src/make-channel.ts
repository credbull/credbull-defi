import { supabase } from './utils/helpers';

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const client = supabase({ admin: true });
    const listUsers = await client.auth.admin.listUsers({ perPage: 10000 });
    if (listUsers.error) throw listUsers.error;

    const user = listUsers.data.users.find((u) => u.email === process.env.BOB_EMAIL);
    if (!user) throw new Error('No User');

    const updateUserById = await client.auth.admin.updateUserById(user.id, {
      app_metadata: { ...user.app_metadata, partner_type: ['channel'] },
    });
    if (updateUserById.error) throw updateUserById.error;

    console.log('user is now a channel');

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
