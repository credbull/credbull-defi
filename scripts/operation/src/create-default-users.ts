import { z } from 'zod';

import { createUser } from './create-user';
import { makeAdmin } from './make-admin';
import { loadConfiguration } from './utils/config';

// Zod Schema for validating parameters and configuration.
const configParser = z.object({
  users: z.object({
    admin: z.object({
      email_address: z.string().email()
    }),
    bob: z.object({
      email_address: z.string().email()
    }),
  }),
  secret: z.object({
    ADMIN_PASSWORD: z.string(),
    BOB_PASSWORD: z.string(),
  })
});

/**
 * Creates the 'default' Corporate Accounts. 
 * 
 * @param config The applicable configuration object. 
 * @throws ZodError if the `config` object does not satisfy all configuration needs.
 */
export const createDefaultUsers = async (config: any) => {
  configParser.parse(config)

  console.log('='.repeat(90));
  console.log('  Creating default Users.')

  await createUser(config, config.users.admin.email_address, false, config.secret.ADMIN_PASSWORD!);
  await makeAdmin(config, config.users.admin.email_address);
  await createUser(config, config.users.bob.email_address, false, config.secret.BOB_PASSWORD!);
  await createUser(config, 'usera@credbull.io', false, 'usera123');

  console.log('  Done.')
  console.log('='.repeat(90));
};

/**
 * Invoked by the command line processor, creates the default User Accounts.
 * 
 * @throws AuthError if any account creation fails.
 * @throws ZodError if the loaded configuration does not satisfy all configuration needs.
 */
export const main = () => {
  setTimeout(async () => { createDefaultUsers(loadConfiguration()); }, 1000);
};

export default { main };
