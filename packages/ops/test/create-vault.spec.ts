import { CredbullFixedYieldVault__factory } from '@credbull/contracts';
import { expect, test } from '@playwright/test';
import Bottleneck from 'bottleneck';
import { isAfter, isFuture, isPast } from 'date-fns';
import { ZodError } from 'zod';

import { createUser } from '@/create-user';
import { createVault, main } from '@/create-vault';
import { makeAdmin } from '@/make-admin';
import { loadConfiguration } from '@/utils/config';
import { deleteUserIfPresent, generateAddress, signer, supabase, userByOrUndefined } from '@/utils/helpers';

const EMPTY_CONFIG = {};
const VALID_ADDRESS = generateAddress();

let config: any | undefined = undefined;

const limiter = new Bottleneck({
  minTime: 1000, // Minimum time between requests in ms
});

test.beforeAll(async () => {
  // NOTE (JL,2024-06-06): This loads the same configuration as the operations themselves.
  config = loadConfiguration();
});

const createVaultWithPause = limiter.wrap(
  async (
    config: any,
    isMatured: boolean,
    isUpside: boolean,
    isTenant: boolean,
    upsideVault?: string,
    tenantEmail?: string,
    override?: { treasuryAddress: string; activityRewardAddress: string; collateralPercentage: number },
  ): Promise<any> => {
    return createVault(config, isMatured, isUpside, isTenant, upsideVault, tenantEmail, override);
  },
);

/*
  TODO - move param validations and tests to separate classes to simplfy createVault testing.
  // e.g. helpers.parseUsideVault() (and associated tests)
 */
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

test.describe('Create Vault Main should fail when invoked with', async () => {
  // NOTE (JL,2024-06-04): Internal async invocation means no other impact possible.
  test('Throws error if invalid parameters', async () => {
    const scenarios = { matured: false, upside: true, tenant: false };

    await expect(main(scenarios, { upsideVault: VALID_ADDRESS, tenantEmail: 'someone@here' })).rejects.toThrow(
      ZodError,
    );
    await expect(
      main(scenarios, { upsideVault: '0x123456789abcdef', tenantEmail: 'someone@here.com' }),
    ).rejects.toThrow(ZodError);
  });
});

test.describe('Create Vault', async () => {
  test.describe.configure({ mode: 'serial' });

  let supabaseAdmin: any | undefined = undefined;
  let createdAdminUser: boolean = false;
  let adminSigner: any | undefined = undefined;

  test.beforeAll(async () => {
    supabaseAdmin = supabase(config, { admin: true });
    adminSigner = signer(config, config.secret.ADMIN_PRIVATE_KEY);

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

  async function numberOfVaults(): Promise<number> {
    return supabaseAdmin
      .from('vaults')
      .select('*', { count: 'exact', head: true })
      .then((data: any) => {
        return data.count;
      });
  }

  async function verifyVaultContract(address: string, isMatured = false): Promise<void> {
    const vaultContract = CredbullFixedYieldVault__factory.connect(address, adminSigner);
    expect(vaultContract.name()).resolves.toBe('Credbull Liquidity');
    expect(vaultContract.symbol()).resolves.toBe('CLTP');
    expect(vaultContract.isMatured()).resolves.toBe(isMatured);
  }

  test.describe('should create', async () => {
    test('a non-matured, ready, Fixed Yield vault, open for deposits, not-yet open for redemption', async () => {
      const created = await createVaultWithPause(config, false, false, false);

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
    }, 20000); // Increase the timeout to 20000ms (20 seconds)

    test('a non-matured, ready, Fixed Yield vault, closed for deposits/redemption, Maturity Check OFF', async () => {
      const created = await createVaultWithPause(config, true, false, false);

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
    }, 20000); // Increase the timeout to 20000ms (20 seconds)

    test.fixme(
      'a non-matured, ready, Upside Fixed Yield vault, open for deposits, pending for redemption',
      async () => {
        const created = await createVaultWithPause(config, false, true, false, 'self');
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
        const expected = { id: created.id, type: 'fixed_yield', status: 'ready', address: created.address };
        expect(loaded).toMatchObject(expected);
        expect(rest).toEqual([]);

        await verifyVaultContract(created.address);
      },
    );
  });

  // TODO: lucasia - do we really need to test the main function that is a pass through to createVault?
  test.describe.skip('Main should create', async () => {
    test.skip('a non-matured, ready, Fixed Yield vault, open for deposits, not-yet open for redemption', async () => {
      const countBefore = await numberOfVaults();
      expect(() => main({ matured: false, upside: false, tenant: false })).toPass();

      await expect
        .poll(
          async () => {
            return numberOfVaults();
          },
          { timeout: 30_000 },
        )
        .toBe(countBefore + 1);
      // NOTE (JL,2024-06-07): Assume that the latest created vault pertains to this test and has the highest ID.
      const { data: loaded } = await supabaseAdmin
        .from('vaults')
        .select(
          'id, type, status, address, deposits_opened_at, deposits_closed_at, redemptions_opened_at, redemptions_closed_at',
        )
        .order('id', { ascending: false })
        .limit(1)
        .single();
      expect(loaded).toMatchObject({ type: 'fixed_yield', status: 'ready' });

      expect(isPast(loaded.deposits_opened_at)).toBe(true);
      expect(isFuture(loaded.deposits_closed_at)).toBe(true);
      expect(isAfter(loaded.deposits_closed_at, loaded.deposits_opened_at)).toBe(true);
      expect(isFuture(loaded.redemptions_opened_at)).toBe(true);
      expect(isAfter(loaded.redemptions_opened_at, loaded.deposits_closed_at)).toBe(true);
      expect(isAfter(loaded.redemptions_closed_at, loaded.redemptions_opened_at)).toBe(true);

      await verifyVaultContract(loaded.address);
    });
  });
});
