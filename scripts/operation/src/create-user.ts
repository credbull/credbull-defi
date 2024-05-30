import { z } from 'zod';

import { makeChannel } from './make-channel';
import { supabase } from './utils/helpers';
import { loadConfiguration } from './utils/config';

// NOTE (JL,2024-05-29): This Zod Schema validates the configuration for the 'Create User' operation only.
//  Meaning the config references in this module. Helper function configuration requirements are validated
//  in situ.
const configParser = z.object({ app: z.object({ url: z.string().url() }) });

/**
 * Creates a Corporate Account User with `email` Email Address and `_password` Password, if provided. If
 * `_password` is not provided, generate a password.
 * 
 * The `config` object is validated to provide all configuration items required.
 * 
 * @param config The applicable configuration. 
 * @param email The `string` email address of the Corporate Account.
 * @param isChannel The Corporate Account is also a Channel.
 * @param _password The optional password to use for the Corporate Account.
 * @throws AuthError if the account creation fails.
 * @throws ZodError if the `config` object does not satisfy all configuration needs.
 */
export const createUser = async (config: any, email: string, isChannel: boolean, _password?: string) => {
  configParser.parse(config)

  const client = supabase(config, { admin: true });
  const password = _password || (Math.random() + 1).toString(36);
  const auth = await client.auth.signUp({
    email: email,
    password: password,
    options: { emailRedirectTo: `${config.app.url}/forgot-password` },
  });
  if (auth.error) throw auth.error;

  console.log('='.repeat(80));
  console.log(' Corporate Account created: ');
  console.log('   Email Address: ' + email);
  console.log('   Password: ' + (_password ? '******' : password));
  console.log('='.repeat(80));

  if (isChannel) {
    makeChannel(config, email);
  }
};

/**
 * Invoked by the command line processor, creates a Corporate Account User according to the 
 * `params`. If `scenarios.channel` is set, also makes the created user a Channel. 
 * 
 * @param scenarios Object that determines whether the created user account is also a Channel or not.
 * @param params Optional(?) parameters object containing the `email` for the account to create.
 * @throws Error if `params.email` is not provided.
 * @throws ZodError if the loaded configuration does not satisfy all configuration needs.
 */
export const main = (scenarios: { channel: boolean }, params?: { email: string }) => {
  setTimeout(async () => {
    if (!params?.email) throw new Error('Email is required');
    createUser(loadConfiguration(), params!.email, scenarios.channel);
  }, 1000);
};

export default { main };
