import { assertEmail } from './utils/assert';
import { supabaseAdminClient } from './utils/database';
import { userByOrThrow } from './utils/user';

/**
 * Updates the `email` Corporate User Account to add the `updateMetaData` to the User Meta Data.
 *
 * @param config The applicable configuration object.
 * @param email The `string` email address of the Corporate Account.
 * @param updateMetaData The `any` object that is the User Meta Data update.
 * @returns The updated User object.
 * @throws Error if the User was not found.
 * @throws AuthError if the update fails.
 * @throws ZodError if the parameters or configuration are invalid.
 */
export async function updateMetadata(config: any, email: string, updateMetaData: any): Promise<any> {
  assertEmail(email);

  const supabaseAdmin = supabaseAdminClient(config);
  const toUpdate = await userByOrThrow(supabaseAdmin, email);
  const {
    data: { user },
    error,
  } = await supabaseAdmin.auth.admin.updateUserById(toUpdate.id, {
    app_metadata: { ...toUpdate.app_metadata, ...updateMetaData },
  });
  if (error) throw error;
  return user;
}
