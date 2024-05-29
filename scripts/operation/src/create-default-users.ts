import { z } from 'zod';

import { createUser } from './create-user';
import { makeAdmin } from './make-admin';
import { loadConfiguration } from './utils/config';

const wait = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// NOTE (JL,2024-05-29): This Zod Schema validates the configuration for the 'Create Default Users' operation only.
//  Meaning the config references in this module. Helper function configuration requirements are validated
//  in situ.
const configParser = z.object({
  operation: z.object({
    users: z.object({
      admin: z.object({
        email_address: z.string().email()
      }),
      bob: z.object({
        email_address: z.string().email()
      }),
    })
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

  console.log('='.repeat(100));
  console.log('  Creating default Users.')

  createUser(config.operation.users.admin.email_address, config.secret.ADMIN_PASSWORD!);
  await wait(1000);
  makeAdmin(config, config.operation.users.admin.email_address);
  await wait(1000);
  createUser(config.operation.users.bob.email_address, config.secret.BOB_PASSWORD!);
  await wait(1000);
  createUser('usera@credbull.io', 'usera123');

  console.log('  Done.')
  console.log('='.repeat(100));
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
