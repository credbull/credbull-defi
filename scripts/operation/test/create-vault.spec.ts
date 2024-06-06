import { ZodError } from 'zod';
import { test, expect } from '@playwright/test';

import { createUser } from '@/create-user';
import { createVault, main } from '@/create-vault';
import { loadConfiguration } from '@/utils/config';
import { deleteUserIfPresent, generateAddress, supabase, userByOrUndefined } from '@/utils/helpers';

const EMPTY_CONFIG = {};
const VALID_ADDRESS = generateAddress();

let config: any | undefined = undefined;
let supabaseAdmin: any | undefined = undefined;
let createdAdminUser: boolean = false;

test.beforeAll(async () => {
  // NOTE (JL,2024-05-31): This loads the same configuration as the operations themselves.
  config = loadConfiguration();

  supabaseAdmin = supabase(config, { admin: true });
  
  // Ensure the admin user exists.
  if (!await userByOrUndefined(supabaseAdmin, config.users.admin.email_address)) {
    await createUser(config, config.users.admin.email_address, false, config.secret.ADMIN_PASSWORD);
    createdAdminUser = true;
  }
});

test.afterAll(async () => {
  if (createdAdminUser) await deleteUserIfPresent(supabaseAdmin, config.users.admin.email_address); 
});

test.describe('Create Vault should fail when invoked with', async () => {
  test('an invalid configuration', async () => {
    expect(createVault(EMPTY_CONFIG, false, false, false)).rejects.toThrow(ZodError);
    expect(createVault('I Am Config', false, false, false)).rejects.toThrow(ZodError);
    expect(createVault(42, false, false, false)).rejects.toThrow(ZodError);
    expect(createVault({ api: { url: 'not.a.valid.url' } }, false, false, false)).rejects.toThrow(ZodError);
  });

  test('an invalid Fixed Yield With Upside Vault specification', async () => {
    expect(createVault(config, false, true, false, '')).rejects.toThrow(ZodError);
    expect(createVault(config, false, true, false, ' \t \n ')).rejects.toThrow(ZodError);
    expect(createVault(config, false, true, false, 'self ')).rejects.toThrow(ZodError);
    expect(createVault(config, false, true, false, 'SELF')).rejects.toThrow(ZodError);
    for (const chr of 'ghijklmnopqrstuvwxyzGHIJKLMNOPQRSTUVWXYZ') {
      const notHex = chr.repeat(40);
      expect(createVault(config, false, true, false, notHex)).rejects.toThrow(ZodError);
      expect(createVault(config, false, true, false, '0x' + notHex)).rejects.toThrow(ZodError);
    }
    for (const chr of '1234567890abcdefABCDEF') {
      const tooSmall = chr.repeat(39);
      const tooBig = chr.repeat(41);
      expect(createVault(config, false, true, false, tooSmall)).rejects.toThrow(ZodError);
      expect(createVault(config, false, true, false, '0x' + tooSmall)).rejects.toThrow(ZodError);
      expect(createVault(config, false, true, false, tooBig)).rejects.toThrow(ZodError);
      expect(createVault(config, false, true, false, '0x' + tooBig)).rejects.toThrow(ZodError);
    }
  });

  test('an invalid tenant email address', async () => {
    expect(createVault(config, false, false, true, VALID_ADDRESS, '')).rejects.toThrow(ZodError);
    expect(createVault(config, false, false, true, VALID_ADDRESS, ' \t \n ')).rejects.toThrow(ZodError);
    expect(createVault(config, false, false, true, VALID_ADDRESS, 'someone@here')).rejects.toThrow(ZodError);
    expect(createVault(config, false, false, true, VALID_ADDRESS, 'no one@here.com')).rejects.toThrow(ZodError);
    expect(createVault(config, false, false, true, VALID_ADDRESS, 'not.quite@here.com ')).rejects.toThrow(ZodError);
  });
});
