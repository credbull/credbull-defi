import { supabase, userByEmail } from './utils/helpers';

export const main = (scenarios: object, params?: { email: string }) => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    if (!params?.email) throw new Error('Email is required');
    const user = await userByEmail(params?.email);

    const client = supabase({ admin: true });
    const updateUserById = await client.auth.admin.updateUserById(user.id, {
      app_metadata: { ...user.app_metadata, partner_type: 'channel' },
    });
    if (updateUserById.error) throw updateUserById.error;

    console.log('user is now a channel');

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
