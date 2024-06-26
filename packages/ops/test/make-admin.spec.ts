import { expect, test } from '@playwright/test';
import { ZodError } from 'zod';

import { createUser } from '@/create-user';
import { makeAdmin } from '@/make-admin';
import { loadConfiguration } from '@/utils/config';
import { supabaseAdminClient } from '@/utils/database';
import { generateRandomEmail } from '@/utils/generate';
import { deleteUserIfPresent, userByOrThrow } from '@/utils/user';

const PASSWORD = 'DoNotForget';

let config: any | undefined = undefined;
let supabaseAdmin: any | undefined = undefined;
let subscription: any | undefined = undefined;

let email1: string;
let email2: string;

test.beforeAll(() => {
  config = loadConfiguration();
  email1 = generateRandomEmail('test-admin1');
  email2 = generateRandomEmail('test-admin2');

  supabaseAdmin = supabaseAdminClient(config);
  ({
    data: { subscription },
  } = supabaseAdmin.auth.onAuthStateChange((event: any, session: any) => {
    console.log(' => Supabase Auth Event: %s, Session: %s', event, session);
  }));
});

test.afterAll(async () => {
  await deleteUserIfPresent(supabaseAdmin, email2);
  await deleteUserIfPresent(supabaseAdmin, email1);

  subscription.unsubscribe();
});

test.describe('Make Admin should fail with', async () => {
  test('an invalid email address', async () => {
    expect(makeAdmin(config, '')).rejects.toThrow(ZodError);
    expect(makeAdmin(config, ' \t \n ')).rejects.toThrow(ZodError);
    expect(makeAdmin(config, 'someone@here')).rejects.toThrow(ZodError);
    expect(makeAdmin(config, 'no one@here.com')).rejects.toThrow(ZodError);
  });
});

test.describe('Make Admin should update', async () => {
  test('an existing non-admin account to be an admin account', async () => {
    const user = await createUser(config, email1, false, PASSWORD);
    expect(user.app_metadata.roles).toBeUndefined();

    const updated = await makeAdmin(config, email1);
    expect(updated).toMatchObject({ email: email1 });
    const expectedRoles = { roles: ['admin'] };
    expect(updated.app_metadata, 'Admin Role is not set.').toMatchObject(expectedRoles);
  });
});
