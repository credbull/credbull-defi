import { CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { expect, test } from '@playwright/test';
import { isAfter, isFuture, isPast } from 'date-fns';
import { ZodError } from 'zod';

import { createUser } from '@/create-user';
import { createVault } from '@/create-vault';
import { makeAdmin } from '@/make-admin';
import { loadConfiguration } from '@/utils/config';
import { supabaseAdminClient } from '@/utils/database';
import { signerFor } from '@/utils/ethers';
import { generateAddress, generatePassword, generateRandomEmail } from '@/utils/generate';
import { deleteUserIfPresent, userByOrUndefined } from '@/utils/user';

const EMPTY_CONFIG = {};
const VALID_ADDRESS = generateAddress();

let config: any | undefined = undefined;

test.beforeAll(async () => {
  // NOTE (JL,2024-06-06): This loads the same configuration as the operations themselves.
  config = loadConfiguration();
});

/*
  TODO - move param validations and tests to separate classes to simplify createVault testing.
  // e.g. helpers.parseUpsideVault() (and associated tests)
 */
// NOTE (JL,2024-06-18): Given that this test suite is Black Box testing, it is proving the API Contract (no pun) of the
//  function. Thus having tests for the validation helper functions (we have some) does not actually test the API
//  Contract of the function under test (just a correlation of it!). So, I don't actually agree with the TODO above!
//  Will discuss with Ian.

test.describe('Create Vault should fail when invoked with', async () => {
  test('an invalid configuration', async () => {
    expect(createVault(EMPTY_CONFIG, false, false, false)).rejects.toThrow(ZodError);
    expect(createVault('I Am Config', false, false, false)).rejects.toThrow(ZodError);
    expect(createVault(42, false, false, false)).rejects.toThrow(ZodError);
    expect(createVault({ api: { url: 'not.a.valid.url' } }, false, false, false)).rejects.toThrow(ZodError);
  });

  test('an invalid Fixed Yield With Upside Vault specification', async () => {
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
});

test.describe('Create Vault', async () => {
  test.describe.configure({ mode: 'serial' });

  let supabaseAdmin: any | undefined = undefined;
  let createdAdminUser: boolean = false;
  let adminSigner: any | undefined = undefined;

  test.beforeAll(async () => {
    supabaseAdmin = supabaseAdminClient(config);
    adminSigner = signerFor(config, config.secret.ADMIN_PRIVATE_KEY);

    // Ensure the admin user exists.
    if (!(await userByOrUndefined(supabaseAdmin, config.users.admin.email_address))) {
      await createUser(config, config.users.admin.email_address, false, config.secret.ADMIN_PASSWORD);
      await makeAdmin(config, config.users.admin.email_address);
      createdAdminUser = true;
    }
  });

  test.afterAll(async () => {
    if (createdAdminUser) await deleteUserIfPresent(supabaseAdmin, config.users.admin.email_address);
  });

  async function verifyVaultContract(address: string, isMatured = false): Promise<void> {
    const vaultContract = CredbullFixedYieldVault__factory.connect(address, adminSigner);
    expect(vaultContract.name()).resolves.toBe('Credbull Liquidity');
    expect(vaultContract.symbol()).resolves.toBe('CLTP');
    expect(vaultContract.isMatured()).resolves.toBe(isMatured);
  }

  test.describe('should create', async () => {
    test('a non-matured, ready, Fixed Yield vault, open for deposits, not-yet open for redemption', async () => {
      const created = await createVault(config, false, false, false);

      expect(created).toMatchObject({ type: 'fixed_yield', status: 'ready' });
      expect(isPast(created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.deposits_closed_at, created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.redemptions_opened_at)).toBe(true);
      expect(isAfter(created.redemptions_opened_at, created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.redemptions_closed_at, created.redemptions_opened_at)).toBe(true);

      const {
        data: [loaded, ...rest],
      } = await supabaseAdmin.from('vaults').select('id, type, status, address').eq('id', created.id);
      expect(loaded).toMatchObject({ id: created.id, type: 'fixed_yield', status: 'ready', address: created.address });
      expect(rest).toEqual([]);

      await verifyVaultContract(created.address);
    });

    test('a non-matured, ready, Fixed Yield vault, closed for deposits/redemption, Maturity Check OFF', async () => {
      const created = await createVault(config, true, false, false);

      expect(created).toMatchObject({ type: 'fixed_yield', status: 'ready' });
      expect(isPast(created.deposits_opened_at)).toBe(true);
      expect(isPast(created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.deposits_closed_at, created.deposits_opened_at)).toBe(true);
      expect(isPast(created.redemptions_opened_at)).toBe(true);
      expect(isPast(created.redemptions_closed_at)).toBe(true);
      expect(isAfter(created.redemptions_opened_at, created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.redemptions_closed_at, created.redemptions_opened_at)).toBe(true);

      const {
        data: [loaded, ...rest],
      } = await supabaseAdmin.from('vaults').select('id, type, status, address').eq('id', created.id);
      expect(loaded).toMatchObject({ id: created.id, type: 'fixed_yield', status: 'ready', address: created.address });
      expect(rest).toEqual([]);

      await verifyVaultContract(created.address);
    });

    test('a non-matured, ready, Upside Fixed Yield vault, linked to itself, open for deposits, pending for redemption', async () => {
      const created = await createVault(config, false, true, false, 'self');
      expect(created).toMatchObject({ type: 'fixed_yield_upside', status: 'ready' });
      expect(isPast(created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.deposits_closed_at, created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.redemptions_opened_at)).toBe(true);
      expect(isAfter(created.redemptions_opened_at, created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.redemptions_closed_at, created.redemptions_opened_at)).toBe(true);

      // Vault
      const {
        data: [vaults, ...restVaults],
      } = await supabaseAdmin.from('vaults').select('id, type, status, address').eq('id', created.id);
      const expected = { id: created.id, type: 'fixed_yield_upside', status: 'ready', address: created.address };
      expect(vaults).toMatchObject(expected);
      expect(restVaults).toEqual([]);

      // Vault Entity
      const {
        data: [vaultEntity, ...restVaultEntity],
      } = await supabaseAdmin.from('vault_entities').select('address').eq('vault_id', created.id).eq('type', 'vault');
      expect(vaultEntity).toMatchObject({ address: created.address });
      expect(restVaultEntity).toEqual([]);

      await verifyVaultContract(created.address);
    });

    test('a non-matured, ready, Upside Fixed Yield vault, linked to another, open for deposits, pending for redemption', async () => {
      test.slow(); // triple the timeout time for this test.  keeps failing with default timeout of 30s.

      const linkToVault = await createVault(config, false, false, false);

      const created = await createVault(config, false, true, false, linkToVault.address);
      expect(created).toMatchObject({ type: 'fixed_yield_upside', status: 'ready' });
      expect(isPast(created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.deposits_closed_at, created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.redemptions_opened_at)).toBe(true);
      expect(isAfter(created.redemptions_opened_at, created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.redemptions_closed_at, created.redemptions_opened_at)).toBe(true);

      // Vault
      const {
        data: [vaults, ...restVaults],
      } = await supabaseAdmin.from('vaults').select('id, type, status, address').eq('id', created.id);
      const expected = { id: created.id, type: 'fixed_yield_upside', status: 'ready', address: created.address };
      expect(vaults).toMatchObject(expected);
      expect(restVaults).toEqual([]);

      // Vault Entity
      const {
        data: [vaultEntity, ...restVaultEntity],
      } = await supabaseAdmin.from('vault_entities').select('address').eq('vault_id', created.id).eq('type', 'vault');
      expect(vaultEntity).toMatchObject({ address: linkToVault.address });
      expect(restVaultEntity).toEqual([]);

      await verifyVaultContract(created.address);
    });

    test('a non-matured, ready, Fixed Yield vault, open for deposits, pending for redemption, with tenant', async () => {
      const tenantUser = await createUser(config, generateRandomEmail('tenant'), false, generatePassword());

      const created = await createVault(config, false, false, true, undefined, tenantUser.email);
      expect(created).toMatchObject({ type: 'fixed_yield', status: 'ready' });
      expect(isPast(created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.deposits_closed_at, created.deposits_opened_at)).toBe(true);
      expect(isFuture(created.redemptions_opened_at)).toBe(true);
      expect(isAfter(created.redemptions_opened_at, created.deposits_closed_at)).toBe(true);
      expect(isAfter(created.redemptions_closed_at, created.redemptions_opened_at)).toBe(true);

      // Vault
      const {
        data: [vaults, ...restVaults],
      } = await supabaseAdmin.from('vaults').select('id, type, status, address, tenant').eq('id', created.id);
      const expected = {
        id: created.id,
        type: 'fixed_yield',
        status: 'ready',
        address: created.address,
        tenant: tenantUser.id,
      };
      expect(vaults).toMatchObject(expected);
      expect(restVaults).toEqual([]);

      await verifyVaultContract(created.address);
      // NOTE (JL,2024-06-19): Deletion fails, due to Referential Integrity checks (Vault row refers to User).
      await deleteUserIfPresent(config, tenantUser.email);
    });
  });
});
