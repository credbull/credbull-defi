import { supabase } from './utils/helpers';

export const main = () => {
  setTimeout(async () => {
    console.log('\n');
    console.log('=====================================');
    console.log('\n');

    const client = supabase({ admin: true });
    const { data, error } = await client.from('vaults').select();

    if (error) throw error;

    if (data.length === 0) {
      console.log('No vault data to clean');
      return;
    }

    const { error: deleteError } = await client.from('vaults').delete().neq('id', 0);

    if (deleteError) throw deleteError;

    console.log('Vault data cleaned');

    console.log('\n');
    console.log('=====================================');
    console.log('\n');
  }, 1000);
};
