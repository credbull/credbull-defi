import { supabase, userByEmail } from './utils/helpers';

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const user = await userByEmail(process.env.BOB_EMAIL);

    const client = supabase({ admin: true });
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
