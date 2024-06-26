import { makeChannel } from './make-channel';
import { assertEmail } from './utils/assert';
import { loadConfiguration } from './utils/config';
import { supabaseAdminClient } from './utils/database';
import { generatePassword } from './utils/generate';
import { Schema } from './utils/schema';

/**
 * Creates a Corporate Account User with `email` Email Address and `passwordMaybe` Password, if provided. If
 * `passwordMaybe` is not provided, generate a password.
 *
 * The `config` object is validated to provide all configuration items required.
 *
 * @param config The applicable configuration.
 * @param email The `string` email address of the Corporate Account.
 * @param isChannel The Corporate Account is also a Channel.
 * @param passwordMaybe The optional password to use for the Corporate Account. If not specified, a password is
 *  generated. This value is injected in the returned object with the `generated_password` property name.
 * @returns A `Promise` for the Supabase User object.
 * @throws AuthError if the account creation fails.
 * @throws ZodError if the parameters or config are invalid.
 */
export async function createUser(config: any, email: string, isChannel: boolean, passwordMaybe?: string): Promise<any> {
  Schema.CONFIG_APP_URL.parse(config);
  Schema.NON_EMPTY_STRING.optional().parse(passwordMaybe);
  assertEmail(email);

  const supabaseAdmin = supabaseAdminClient(config);
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
}

/**
 * Invoked by the command line processor, creates a Corporate Account User according to the
 * `params`. If `scenarios.channel` is set, also makes the created user a Channel.
 *
 * @param scenarios Object that determines whether the created user account is also a Channel or not.
 * @param params Optional(?) parameters object containing the `email` for the account to create.
 * @throws Error if `params.email` is not provided.
 * @throws ZodError if the loaded configuration does not satisfy all configuration needs.
 */
export async function main(scenarios: { channel: boolean }, params?: { email: string }) {
  if (!params?.email) throw new Error('Email is required');

  await createUser(loadConfiguration(), params!.email, scenarios.channel);
}

export default { main };
