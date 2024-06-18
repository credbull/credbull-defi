import { ZodError, z } from 'zod';

import { makeChannel } from './make-channel';
import { loadConfiguration } from './utils/config';
import { assertEmail, generatePassword, supabase } from './utils/helpers';

// Zod Schemas to validate the parameters and configuration.
const configSchema = z.object({ app: z.object({ url: z.string().url() }) });
const nonEmptyStringSchema = z.string().trim().min(1);

/**
 * Creates a Corporate Account User with `email` Email Address and `_password` Password, if provided. If
 * `_password` is not provided, generate a password.
 *
 * The `config` object is validated to provide all configuration items required.
 *
 * @param config The applicable configuration.
 * @param email The `string` email address of the Corporate Account.
 * @param isChannel The Corporate Account is also a Channel.
 * @param passwordMaybe The optional password to use for the Corporate Account. If not specified, a password is generated.
 *  This value is injected in the returned object with the `generated_password` property name.
 * @returns A `Promise` for the Supabase User object.
 * @throws AuthError if the account creation fails.
 * @throws ZodError if the parameters or config are invalid.
 */
export const createUser = async (
  config: any,
  email: string,
  isChannel: boolean,
  passwordMaybe?: string,
): Promise<any> => {
  assertEmail(email);

  nonEmptyStringSchema.optional().parse(passwordMaybe);
  configSchema.parse(config);

  const supabaseAdmin = supabase(config, { admin: true });
  const password = passwordMaybe || generatePassword();
  const {
    data: { user },
    error,
  } = await supabaseAdmin.auth.signUp({
    email: email,
    password: password,
    options: { emailRedirectTo: `${config.app.url}/forgot-password` },
  });

  if (error) {
    if (error.message === 'User already registered') {
      console.log('User already registered. Proceeding without error.');
    } else {
      // Throw other errors
      throw error;
    }
  }

  console.log('='.repeat(80));
  console.log(' Corporate Account created: ');
  console.log('   Email Address: %s', email);
  console.log('   Password: %s', passwordMaybe ? '******' : password);
  console.log('='.repeat(80));

  let toReturn = user;
  if (isChannel) {
    toReturn = await makeChannel(config, email);
  }

  // NOTE (JL,2024-06-04): If we generated the password, include it in the inital user. Ugly.
  if (!passwordMaybe && password) {
    toReturn = Object.assign(toReturn as object, { generated_password: password }) as any;
  }

  return toReturn;
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
  if (!params?.email) throw new Error('Email is required');

  createUser(loadConfiguration(), params!.email, scenarios.channel);
};

export default { main };
