import { ZodError } from 'zod';
import { test, expect } from '@playwright/test';

import { CredbullFixedYieldVault__factory } from '@credbull/contracts';

import { createUser } from '@/create-user';
import { createVault, main } from '@/create-vault';
import { makeAdmin } from '@/make-admin';
import { loadConfiguration } from '@/utils/config';
import { deleteUserIfPresent, generateAddress, signer, supabase, userByOrUndefined } from '@/utils/helpers';

const EMPTY_CONFIG = {};
const VALID_ADDRESS = generateAddress();

let config: any | undefined = undefined;

test.beforeAll(async () => {
  // NOTE (JL,2024-06-06): This loads the same configuration as the operations themselves.
  config = loadConfiguration();
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

test.describe('Create Vault Main should fail when invoked with', async () => {

  // NOTE (JL,2024-06-04): Internal async invocation means no other impact possible.
  test('any invalid parameter, does not due to asynchronous invocation', async () => {
    const scenarios = { matured: false, upside: true, tenant: false };
    expect(() => main(scenarios, { upsideVault: VALID_ADDRESS, tenantEmail: 'someone@here' })).toPass();
    expect(() => main(scenarios, { upsideVault: '0x123456789abcdef', tenantEmail: 'someone@here.com' })).toPass();
  });
});

test.describe('Create Vault', async () => {
  let supabaseAdmin: any | undefined = undefined;
  let createdAdminUser: boolean = false;
  let adminSigner: any | undefined = undefined;

  test.beforeAll(async () => {
    supabaseAdmin = supabase(config, { admin: true });
    adminSigner = signer(config, config.secret.ADMIN_PRIVATE_KEY);

    // Ensure the admin user exists.
    if (!await userByOrUndefined(supabaseAdmin, config.users.admin.email_address)) {
      await createUser(config, config.users.admin.email_address, false, config.secret.ADMIN_PASSWORD);
      await makeAdmin(config, config.users.admin.email_address);
      createdAdminUser = true;
    }
  });

  test.afterAll(async () => {
    if (createdAdminUser) await deleteUserIfPresent(supabaseAdmin, config.users.admin.email_address);
  });

  async function countVaults(): Promise<number> {
    return supabaseAdmin.from('vaults').select('*', { count: 'exact', head: true })
      .then((data: any) => { return data.count; });
  }

  test.describe('should create', async () => {

    test('a Fixed Yield vault that is ready', async () => {
      const countBefore = await countVaults();
      const created = await createVault(config, false, false, false);
      expect(created).toMatchObject({ type: 'fixed_yield', status: 'ready' });

      const countAfter = await countVaults();
      expect(countAfter === countBefore + 1, 'No Vault was created').toBe(true);

      const { data: [loaded, ...rest] } = await supabaseAdmin
        .from('vaults')
        .select('id, type, status')
        .eq('id', created.id);
      expect(loaded).toMatchObject({ id: created.id, type: 'fixed_yield', status: 'ready' });
      expect(rest).toEqual([]);

      const vaultContract = CredbullFixedYieldVault__factory.connect(created.address, adminSigner);
      const name = await vaultContract.name();
      const symbol = await vaultContract.symbol();
      expect(name).toBe('Credbull Liquidity');
      expect(symbol).toBe('CLTP');
    });
  });

  test.skip('Main should create', async () => {

    test('a specific vault', async () => {
    });
  });

});
