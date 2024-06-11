import { ZodError } from 'zod';
import { test, expect } from '@playwright/test';

import { loadConfiguration } from '@/utils/config';
import { deleteUserIfPresent, supabase, userByOrThrow } from '@/utils/helpers';
import { makeChannel, main } from '@/make-channel';
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

test.describe('Make Channel should fail with', async () => {
  test('an invalid email address', async () => {
    expect(makeChannel(config, '')).rejects.toThrow(ZodError);
    expect(makeChannel(config, ' \t \n ')).rejects.toThrow(ZodError);
    expect(makeChannel(config, 'someone@here')).rejects.toThrow(ZodError);
    expect(makeChannel(config, 'no one@here.com')).rejects.toThrow(ZodError);
  });
});

test.describe('Make Channel should update', async () => {

  test('an existing non-channel account to be a channel account', async () => {
    const email = 'minion1@make.channel.test';
    const user = await createUser(config, email, false, PASSWORD);
    expect(user.app_metadata.partner_type).toBeUndefined();

    const updated = await makeChannel(config, email);
    expect(updated).toMatchObject({ email: email });
    const expectedPartnerType = { partner_type: 'channel' };
    expect(updated.app_metadata, 'Partner Type is not set.').toMatchObject(expectedPartnerType);

    await deleteUserIfPresent(supabaseAdmin, email);
  });
});

test.describe('Make Channel Main should fail with', async () => {

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

test.describe('Make Channel Main should update', async () => {

  test('an existing non-channel account to be a channel account', async () => {
    const email = 'minion2@make.channel.test';
    const user = await createUser(config, email, false, PASSWORD);
    expect(user.app_metadata.partner_type).toBeUndefined();

    expect(() => main({}, { email: email })).toPass();

    // Poll the database until the User is updated, or test is timed out after 1 minute.
    await expect.poll(async () => { 
      const updated = await userByOrThrow(supabaseAdmin, email); 
      return updated?.app_metadata?.partner_type === 'channel'; 
    }, { 
      timeout: 30_000 
    }).toEqual(true);

    await deleteUserIfPresent(supabaseAdmin, email);
  });
});
