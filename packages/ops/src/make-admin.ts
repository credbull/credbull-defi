import { updateMetadata } from './update-metadata';
import { loadConfiguration } from './utils/config';

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
export async function makeAdmin(config: any, email: string): Promise<any> {
  return updateMetadata(config, email, { roles: ['admin'] });
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
export async function main(scenarios: object, params?: { email: string }) {
  if (!params?.email) throw new Error('Email is required');

  await makeAdmin(loadConfiguration(), params!.email);
}

export default { main };
