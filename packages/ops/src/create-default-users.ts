import { createUser } from './create-user';
import { makeAdmin } from './make-admin';
import { loadConfiguration } from './utils/config';
import { Schema } from './utils/schema';

/**
 * Creates the 'default' Corporate Accounts.
 *
 * @param config The applicable configuration object.
 * @throws ZodError if the `config` object does not satisfy all configuration needs.
 */
export const createDefaultUsers = async (config: any) => {
  Schema.CONFIG_USERS.parse(config);

  console.log('='.repeat(90));
  console.log('  Creating default Users.');

  await createUser(config, config.users.admin.email_address, false, config.secret.ADMIN_PASSWORD!);
  await makeAdmin(config, config.users.admin.email_address);
  await createUser(config, config.users.alice.email_address, false, config.secret.ALICE_PASSWORD!);
  await createUser(config, config.users.bob.email_address, false, config.secret.BOB_PASSWORD!);

  console.log('  Done.');
  console.log('='.repeat(90));
};

/**
 * Invoked by the command line processor, creates the default User Accounts.
 *
 * @throws AuthError if any account creation fails.
 * @throws ZodError if the loaded configuration does not satisfy all configuration needs.
 */
export const main = () => {
  setTimeout(async () => {
    createDefaultUsers(loadConfiguration());
  }, 1000);
};

export default { main };
