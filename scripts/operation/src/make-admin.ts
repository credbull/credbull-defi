import { loadConfiguration } from './utils/config';
import { supabase, userByEmail } from './utils/helpers';

/**
 * Updates the `email` Corporate User Account to add the Administrator Role.
 * 
 * @param config The applicable configuration object. 
 * @param email The `string` email address of the Corporate Account.
 * @throws AuthError if the account does not exist or the update fails.
 * @throws ZodError if the `config` object does not satisfy all configuration needs.
 */
export const makeAdmin = async (config: any, email: string) => {
  const user = await userByEmail(config, email);
  const client = supabase(config, { admin: true });
  const updateUserById = await client.auth.admin.updateUserById(user.id, {
    app_metadata: { ...user.app_metadata, roles: ['admin'] },
  });
  if (updateUserById.error) throw updateUserById.error;

  console.log('='.repeat(80));
  console.log('  Corporate Account ' + email + ' is now an Administrator.');
  console.log('='.repeat(80));
}

/**
 * Invoked by the command line processor, updates a specific Corporate Account User to add the 
 * Administrator Role. 
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
    makeAdmin(loadConfiguration(), params!.email);
  }, 1000);
};

export default { main };
