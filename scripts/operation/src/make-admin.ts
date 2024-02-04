import { supabase, userByEmail } from './utils/helpers';

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const user = await userByEmail(process.env.ADMIN_EMAIL);

    const client = supabase({ admin: true });
    const updateUserById = await client.auth.admin.updateUserById(user.id, {
      app_metadata: { ...user.app_metadata, roles: ['admin'] },
    });
    if (updateUserById.error) throw updateUserById.error;

    console.log('user is now an admin');

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
