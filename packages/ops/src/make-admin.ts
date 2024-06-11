import { z } from 'zod';

import { loadConfiguration } from './utils/config';
import { supabase, userByOrThrow } from './utils/helpers';

// TODO (JL,2024-06-05): Add `update-metadata` script and use for Make Admin/Channel.

// Zod Schemas for parameter and configuration validation.
const emailSchema = z.string().email();

/**
 * Updates the `email` Corporate User Account to add the Administrator Role.
 * 
 * @param config The applicable configuration object. 
 * @param email The `string` email address of the Corporate Account.
 * @returns The updated User object.
 * @throws Error if the User was not found.
 * @throws AuthError if the update fails.
 * @throws ZodError if the parameters or configuration are invalid.
 */
export const makeAdmin = async (config: any, email: string): Promise<any> => {
  emailSchema.parse(email);

  const supabaseAdmin = supabase(config, { admin: true });
  const toUpdate = await userByOrThrow(supabaseAdmin, email);
  const { data: { user }, error } = await supabaseAdmin.auth.admin.updateUserById(toUpdate.id, {
    app_metadata: { ...toUpdate.app_metadata, roles: ['admin'] },
  });
  if (error) throw error;

  console.log('='.repeat(80));
  console.log('  Corporate Account ' + email + ' is now an Administrator.');
  console.log('='.repeat(80));

  return user;
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
  if (!params?.email) throw new Error('Email is required');
  setTimeout(async () => {
    makeAdmin(loadConfiguration(), params!.email);
  }, 1000);
};

export default { main };