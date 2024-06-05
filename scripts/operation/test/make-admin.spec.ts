import { ZodError } from 'zod';
import { test, expect } from '@playwright/test';

import { loadConfiguration } from '@/utils/config';
import { deleteUserIfPresent, supabase, userByOrThrow } from '@/utils/helpers';
import { makeAdmin, main } from '@/make-admin';
import { createUser } from '@/create-user';

const PASSWORD = 'DoNotForget';

let config: any | undefined = undefined;
let supabaseAdmin: any | undefined = undefined;
let subscription: any | undefined = undefined;

test.beforeAll(() => {
  config = loadConfiguration();

  supabaseAdmin = supabase(config, { admin: true });
  ({ data: { subscription } } = supabaseAdmin.auth.onAuthStateChange((event: any, session: any) => {
    console.log(' => Supabase Auth Event: %s, Session: %s', event, session);
  }));

});

test.afterAll(() => {
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

test.describe('Make Admnin should update', async () => {

  test('an existing non-admin account to be an admin account', async () => {
    const email = 'admin1@make.admin.test';
    const user = await createUser(config, email, false, PASSWORD);
    expect(user.app_metadata.roles).toBeUndefined();

    const updated = await makeAdmin(config, email);
    expect(updated).toMatchObject({ email: email });
    const expectedRoles = { roles: ['admin'] };
    expect(updated.app_metadata, 'Admin Role is not set.').toMatchObject(expectedRoles);

    await deleteUserIfPresent(supabaseAdmin, email);
  });
});

test.describe('Make Admin Main should fail with', async () => {

  test('an absent parameters configuration', async () => {
    expect(() => main({})).toThrow(Error);
  });

  test('an invalid email parameter, but does not detectably', async () => {
    expect(() => main({}, { email: '' })).toPass();
    expect(() => main({}, { email: ' \t \n ' })).toPass();
    expect(() => main({}, { email: 'someone@here' })).toPass();
    expect(() => main({}, { email: 'no one@here.com' })).toPass();
  });
});

test.describe('Make Admin Main should update', async () => {

  test('an existing non-admin account to be an admin account', async () => {
    const email = 'admin2@make.admin.test';
    const user = await createUser(config, email, false, PASSWORD);
    expect(user.app_metadata.roles).toBeUndefined();

    expect(() => main({}, { email: email })).toPass();

    // Poll the database until the User is updated, or test is timed out after 1 minute.
    await expect.poll(async () => { 
      const updated = await userByOrThrow(supabaseAdmin, email); 
      return updated.app_metadata.roles?.includes('admin') || false; 
    }, { 
      timeout: 30_000 
    }).toEqual(true);

    await deleteUserIfPresent(supabaseAdmin, email);
  });
});
