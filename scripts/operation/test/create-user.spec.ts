import { z, ZodError } from 'zod';
import { test, expect, type Page } from '@playwright/test';

import { createUser, main } from '@/create-user';
import { loadConfiguration } from '@/utils/config';
import { supabase, userByEmail } from '@/utils/helpers';

const EMAIL_ADDRESS = 'minion@under.test';
const PASSWORD = 'DoNotForget';
const EMPTY_CONFIG = {};

let config: any | undefined = undefined;
let supabaseClient: any | undefined = undefined;
let subscription: any | undefined = undefined;

test.beforeAll(() => {
  // NOTE (JL,2024-05-31): This loads the same configuration as the operations themselves.
  config = loadConfiguration();

  supabaseClient = supabase(config, { admin: true });
  ({ data: { subscription } } = supabaseClient.auth.onAuthStateChange((event: any, session: any) => {
    console.log(' => Supabase Auth Event: %s, Session: %s', event, session);
  }));
});

test.afterAll(() => {
  subscription.unsubscribe();
});

test.describe('Create User', async () => {
  test('should fail with an invalid configuration', async () => {
    expect(createUser(EMPTY_CONFIG, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser('I Am Config', EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser(42, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser({ app: { url: 'not.a.valid.url' } }, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
  });

  test('should fail with an invalid email address', async () => {
    expect(createUser(config, '', false)).rejects.toThrow(ZodError);
    expect(createUser(config, ' \t \n ', false)).rejects.toThrow(ZodError);
    expect(createUser(config, 'someone@here', false)).rejects.toThrow(ZodError);
    expect(createUser(config, 'no one@here.com', false)).rejects.toThrow(ZodError);
  });

  test('should fail with an empty or blank password', async () => {
    expect(createUser(config, EMAIL_ADDRESS, false, '')).rejects.toThrow(ZodError);
    expect(createUser(config, EMAIL_ADDRESS, false, ' \t \n ')).rejects.toThrow(ZodError);
  });
});

test.describe('Create User CLI Invocation', async () => {
  test('should fail with an absent parameters configuration', async () => {
    expect(() => main({ channel: false })).toThrow(Error);
  });

  // NOTE (JL,2024-06-04): Internal async invocation means no other impact possible. 
  test('should fail with an invalid parameters, but does not', async () => {
    expect(() => main({ channel: false }, { email: '' })).toPass();
    expect(() => main({ channel: false }, { email: ' \t \n ' })).toPass();
    expect(() => main({ channel: false }, { email: 'someone@here' })).toPass();
    expect(() => main({ channel: false }, { email: 'no one@here.com' })).toPass();
  });
});

async function deleteTestUserIfPresent(emailAddress: string) {
  await userByEmail(config, emailAddress)
    .then((user) => {
      supabaseClient.auth.admin.deleteUser(user.id, false);
    }).catch((error) => {
      // Ignore.
    });
}

// NOTE (JL,2024-06-04): These tests failed non-deterministically, with database errors, when using the same 
//  Email Address. Waiting did not work. Serial invocation did not work. 
//  The workaround solution is to use 1 Email Per Test.
test.describe('Create User', async () => {

  test('should create a non-channel user with specified email address and password', async () => {
    const emailAddress = 'minion1@under.test.com';
    await expect(userByEmail(config, emailAddress)).rejects.toThrow(Error);

    const expectedUser = { email: emailAddress };
    const actualUser = await createUser(config, emailAddress, false, PASSWORD);
    expect(actualUser).toMatchObject(expectedUser);

    // Can log in with PASSWORD.
    const { data: { user }, error } = await supabaseClient.auth.signInWithPassword({
      email: emailAddress,
      password: PASSWORD
    });
    expect(error, 'Error logging in created User').toBeNull();
    expect(user, 'Logged in user does not match created.').toMatchObject(expectedUser);

    // Is not a channel (read `app_metadata` for `partner_type` === 'channel')
    expect(user.app_metadata.partner_type, 'Partner Type is set.').toBeUndefined();

    await supabaseClient.auth.signOut('local');
    await deleteTestUserIfPresent(emailAddress);
  });

  test('should create a channel user with specified email address and password', async () => {
    const emailAddress = 'minion2@under.test.com';
    await expect(userByEmail(config, emailAddress)).rejects.toThrow(Error);

    const expectedUser = { email: emailAddress };
    const actualUser = await createUser(config, emailAddress, true, PASSWORD);
    expect(actualUser).toMatchObject(expectedUser);

    // Can log in with PASSWORD.
    const { data: { user }, error } = await supabaseClient.auth.signInWithPassword({
      email: emailAddress,
      password: PASSWORD
    });
    expect(error, 'Error logging in created User').toBeNull();
    expect(user, 'Logged in user does not match created.').toMatchObject(expectedUser);

    // Is not a channel (read `app_metadata` for `partner_type` === 'channel')
    const expectedPartnerType = { partner_type: 'channel' };
    expect(user.app_metadata, 'Partner Type is not set.').toMatchObject(expectedPartnerType);

    await supabaseClient.auth.signOut('local');
    await deleteTestUserIfPresent(emailAddress);
  });

  test('should create a non-channel user with specified email address and a generated password', async () => {
    const emailAddress = 'minion3@under.test.com';
    await expect(userByEmail(config, emailAddress)).rejects.toThrow(Error);

    const actualUser = await createUser(config, emailAddress, false);
    const expectedUser = { email: emailAddress, generated_password: actualUser.generated_password };
    expect(actualUser).toMatchObject(expectedUser);

    // Can log in with `generated_password` value.
    const { data: { user }, error } = await supabaseClient.auth.signInWithPassword({
      email: emailAddress,
      password: actualUser.generated_password
    });
    expect(error, 'Error logging in created User').toBeNull();
    expect(user, 'Logged in user does not match created.').toMatchObject({ email: emailAddress });

    // Is not a channel (read `app_metadata` for `partner_type` === 'channel')
    expect(user.app_metadata.partner_type, 'Partner Type is set.').toBeUndefined();

    await supabaseClient.auth.signOut('local');
    await deleteTestUserIfPresent(emailAddress);
  });

  test('should create a channel user with specified email address and a generated password', async () => {
    const emailAddress = 'minion4@under.test.com';
    await expect(userByEmail(config, emailAddress)).rejects.toThrow(Error);

    const actualUser = await createUser(config, emailAddress, true);
    const expectedUser = { email: emailAddress, generated_password: actualUser.generated_password };
    expect(actualUser).toMatchObject(expectedUser);

    // Can log in with `generated_password` value.
    const { data: { user }, error } = await supabaseClient.auth.signInWithPassword({
      email: emailAddress,
      password: actualUser.generated_password
    });
    expect(error, 'Error logging in created User').toBeNull();
    expect(user, 'Logged in user does not match created.').toMatchObject({ email: emailAddress });

    // Is not a channel (read `app_metadata` for `partner_type` === 'channel')
    const expectedPartnerType = { partner_type: 'channel' };
    expect(user.app_metadata, 'Partner Type is not set.').toMatchObject(expectedPartnerType);

    await supabaseClient.auth.signOut('local');
    await deleteTestUserIfPresent(emailAddress);
  });
});
