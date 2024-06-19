import { SupabaseClient } from '@supabase/supabase-js';

import { Schema } from './schema';

// An ad-hoc Query Page Size for User Queries.
const PAGE_SIZE = 1_000;

/**
 * Searches for the `email` User, returning `undefined` if not found.
 * Only throws an error in a unrecoverable scenario.
 *
 * @param supabaseAdmin A `SupabaseClient` with administrative access.
 * @param email The `string` email address. Must be valid.
 * @returns A `Promise` of a User `any` or `undefined` if not found.
 * @throws ZodError if `email` is not an email address.
 * @throws PostgrestError if there is an error searching for the User.
 * @throws AuthError if there is an error accessing the database.
 * @throws Error if there is a system error or if the result pagination mechanism is broken.
 */
export const userByOrUndefined = async (supabaseAdmin: SupabaseClient, email: string): Promise<any | undefined> => {
  Schema.EMAIL.parse(email);

  const {
    data: { users },
    error,
  } = await supabaseAdmin.auth.admin.listUsers({ perPage: PAGE_SIZE });
  if (error) throw error;
  if (users.length === PAGE_SIZE) throw Error('Implement pagination');
  return users.find((u) => u.email === email);
};

export const userByOrThrow = async (supabaseAdmin: SupabaseClient, email: string) => {
  const user = await userByOrUndefined(supabaseAdmin, email);
  if (!user) throw new Error('No User for ' + email);
  return user;
};

export const deleteUserIfPresent = async (supabaseAdmin: SupabaseClient, email: string) => {
  await userByOrThrow(supabaseAdmin, email)
    .then((user) => {
      supabaseAdmin.auth.admin.deleteUser(user.id, false);
    })
    .catch((error) => {
      // Ignore.
    });
};
