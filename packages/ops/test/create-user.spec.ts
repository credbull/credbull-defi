import { expect, test } from '@playwright/test';
import { ZodError } from 'zod';

import { createUser, main } from '@/create-user';
import { loadConfiguration } from '@/utils/config';
import { supabaseAdminClient } from '@/utils/database';
import { deleteUserIfPresent, userByOrUndefined } from '@/utils/user';

const EMAIL_ADDRESS = 'minion@create.user.test';
const PASSWORD = 'DoNotForget';
const EMPTY_CONFIG = {};

let config: any | undefined = undefined;
let supabaseAdmin: any | undefined = undefined;
let subscription: any | undefined = undefined;

test.beforeAll(() => {
  // NOTE (JL,2024-05-31): This loads the same configuration as the operations themselves.
  config = loadConfiguration();

  supabaseAdmin = supabaseAdminClient(config);
  ({
    data: { subscription },
  } = supabaseAdmin.auth.onAuthStateChange((event: any, session: any) => {
    console.log(' => Supabase Auth Event: %s, Session: %s', event, session);
  }));
});

test.afterAll(() => {
  subscription.unsubscribe();
});

test.describe('Create User should fail when invoked with', async () => {
  test('an invalid configuration', async () => {
    expect(createUser(EMPTY_CONFIG, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser('I Am Config', EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser(42, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
    expect(createUser({ app: { url: 'not.a.valid.url' } }, EMAIL_ADDRESS, false)).rejects.toThrow(ZodError);
  });

  test('an invalid email address', async () => {
    expect(createUser(config, '', false)).rejects.toThrow(ZodError);
    expect(createUser(config, ' \t \n ', false)).rejects.toThrow(ZodError);
    expect(createUser(config, 'someone@here', false)).rejects.toThrow(ZodError);
    expect(createUser(config, 'no one@here.com', false)).rejects.toThrow(ZodError);
  });

  test('an empty or blank password', async () => {
    expect(createUser(config, EMAIL_ADDRESS, false, '')).rejects.toThrow(ZodError);
    expect(createUser(config, EMAIL_ADDRESS, false, ' \t \n ')).rejects.toThrow(ZodError);
  });
});

test.describe('Create User Main should fail with', async () => {
  test('an absent parameters configuration', async () => {
    expect(() => main({ channel: false })).toThrow(Error);
  });
});

// NOTE (JL,2024-06-04): These tests failed non-deterministically, with database errors, when using the same
//  Email Address. Waiting did not work. Removing parallelism did not work.
//  The workaround solution is to use 1 Email Per Test.
test.describe('Create User should create', async () => {
  test.describe.configure({ mode: 'serial' });

  async function assertUserCreatedWith(email: string, isChannel: boolean, passwordMaybe?: string) {
    await expect(userByOrUndefined(supabaseAdmin, email)).resolves.toBeUndefined();

    const actualUser = await createUser(config, email, isChannel, passwordMaybe);
    const expectedUser = passwordMaybe
      ? { email: email }
      : { email: email, generated_password: actualUser.generated_password };
    expect(actualUser).toMatchObject(expectedUser);

    const {
      data: { user },
      error,
    } = await supabaseAdmin.auth.signInWithPassword({
      email: email,
      password: passwordMaybe || actualUser.generated_password,
    });
    expect(error, 'Error logging in created User').toBeNull();
    expect(user, 'Logged in user does not match created.').toMatchObject({ email: email });

    if (!isChannel) {
      expect(user.app_metadata.partner_type, 'Partner Type is set.').toBeUndefined();
    } else {
      const expectedPartnerType = { partner_type: 'channel' };
      expect(user.app_metadata, 'Partner Type is not set.').toMatchObject(expectedPartnerType);
    }

    await supabaseAdmin.auth.signOut('local');
    await deleteUserIfPresent(supabaseAdmin, email);
  }

  test('a non-channel user with specified email address and password', async () => {
    await assertUserCreatedWith('minion1@create.user.test', false, PASSWORD);
  });

  test('a channel user with specified email address and password', async () => {
    await assertUserCreatedWith('minion2@create.user.test', true, PASSWORD);
  });

  test('a non-channel user with specified email address and a generated password', async () => {
    await assertUserCreatedWith('minion3@create.user.test', false);
  });

  test('a channel user with specified email address and a generated password', async () => {
    await assertUserCreatedWith('minion4@create.user.test', true);
  });
});

test.describe('Create User Main should create', async () => {
  test.describe.configure({ mode: 'serial' });

  async function assertUserCreatedWith(email: string, isChannel: boolean) {
    expect(() => main({ channel: isChannel }, { email: email })).toPass();

    // Poll the database until the User is found to exist, or test is timed out after 1 minute.
    await expect
      .poll(async () => await userByOrUndefined(supabaseAdmin, email), { timeout: 30_000 })
      .toMatchObject({ email: email });

    // NOTE (JL,2024-06-05): I can't get the value from the `poll`, so re-query.
    const user = await userByOrUndefined(supabaseAdmin, email);
    if (!isChannel) {
      expect(user.app_metadata.partner_type, 'Partner Type is set.').toBeUndefined();
    } else {
      const expectedPartnerType = { partner_type: 'channel' };
      expect(user.app_metadata, 'Partner Type is not set for= ' + email).toMatchObject(expectedPartnerType);
    }

    await deleteUserIfPresent(supabaseAdmin, email);
  }

  test('an non-channel user with specified email address', async () => {
    await assertUserCreatedWith('minion5@create.user.test', false);
  });

  test('a channel user with specified email address', async () => {
    await assertUserCreatedWith('minion6@create.user.test', true);
  });
});
