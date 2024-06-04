import { SupabaseClient } from '@supabase/supabase-js';
import { loadConfiguration } from './utils/config';
import { supabase, userByEmail } from './utils/helpers';

/**
 * Updates the `email` Corporate User Account to be a Channel.
 * 
 * @param config The applicable configuration object. 
 * @param email The `string` email address of the Corporate Account.
 * @returns The updated User object.
 * @throws AuthError if the account does not exist or the update fails.
 * @throws ZodError if the `config` object does not satisfy all configuration needs.
 */
export const makeChannel = async (config: any, email: string): Promise<any> => {
  const toUpdate = await userByEmail(config, email);
  const supabaseClient = supabase(config, { admin: true });
  const { data: { user }, error } = await supabaseClient.auth.admin.updateUserById(toUpdate.id, {
    app_metadata: { ...toUpdate.app_metadata, partner_type: 'channel' },
  });
  if (error) throw error;

  console.log('='.repeat(80));
  console.log('  Corporate Account ' + email + ' is now a Channel.');
  console.log('='.repeat(80));

  return user;
};

/**
 * Invoked by the command line processor, updates a specific Corporate Account User to be a 
 * Channel. 
 * 
 * @param scenarios Ignored.
 * @param params Optional parameters object with an `email` property specifying the account to update.
 * @throws Error if no `email` value is specified.
 * @throws AuthError if the account does not exist or the update fails.
 * @throws ZodError if the loaded configuration does not satisfy all configuration needs.
 */
export const main = (scenarios: object, params?: { email: string }) => {
  setTimeout(async () => {
    if (!params?.email) throw new Error('Email is required');
    makeChannel(loadConfiguration(), params!.email);
  }, 1000);
};

export default { main };
