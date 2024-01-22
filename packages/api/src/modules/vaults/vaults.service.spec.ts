import { generateMock } from '@anatine/zod-mock';
import { BigNumber } from 'ethers';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { VaultSchema } from '../../types/db.dto';

import { DistributionConfig, DistributionConfigSchema } from './vaults.domain';
import { VaultsService } from './vaults.service';

describe('VaultService', () => {
  // Ideally we don't want to test private methods, but given that VaultService relies heavily on
  // external calls, I took that approach of splitting the logic to create the transfers dtos from the main method
  // and test the private methods that create the dtos directly.
  let prepareVaultTransfers: (service: object) => (typeof VaultsService.prototype)['prepareVaultTransfers'];
  let prepareAllTransfers: (service: object) => (typeof VaultsService.prototype)['prepareAllTransfers'];

  beforeEach(async () => {
    prepareVaultTransfers = (service: object) => VaultsService.prototype['prepareVaultTransfers'].bind(service);
    prepareAllTransfers = (service: object) => VaultsService.prototype['prepareAllTransfers'].bind(service);
  });

  it('should return just a single transfer to a vault', async () => {
    const custodianAddress = '0x555';

    const call = prepareVaultTransfers({
      requiredDataForVaults: vi.fn().mockReturnValue([{ data: BigNumber.from(1100) }, { data: BigNumber.from(1200) }]),
    });

    const vault = generateMock(VaultSchema);
    vault.address = '0x1';
    const transfers = await call([vault], custodianAddress);

    expect(transfers.data?.length).toBe(1);
    expect(transfers.data?.[0].address).toBe('0x1');
    expect(transfers.data?.[0].custodian_address).toBe('0x555');
    expect(transfers.data?.[0].custodianAmount.toString()).toBe('1200');
    expect(transfers.data?.[0].amount.toString()).toBe('1100');
  });

  it('should return just a all transfers', async () => {
    const custodianAddress = '0x555';

    const call = prepareVaultTransfers({
      requiredDataForVaults: vi
        .fn()
        .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { data: BigNumber.from(3600) }])
        .mockReturnValueOnce([{ data: BigNumber.from(2200) }, { data: BigNumber.from(3600) }]),
    });

    const vault1 = generateMock(VaultSchema);
    vault1.address = '0x1';

    const vault2 = generateMock(VaultSchema);
    vault2.address = '0x2';
    const transfers = await call([vault1, vault2], custodianAddress);

    expect(transfers.data?.length).toBe(2);
    expect(transfers.data?.[0].address).toBe('0x1');
    expect(transfers.data?.[0].custodianAmount.toString()).toBe('3600');
    expect(transfers.data?.[0].amount.toString()).toBe('1100');

    expect(transfers.data?.[1].address).toBe('0x2');
    expect(transfers.data?.[1].custodianAmount.toString()).toBe('3600');
    expect(transfers.data?.[1].amount.toString()).toBe('2200');
  });

  it('should return an error if there is not enough to cover all vaults', async () => {
    const custodianAddress = '0x555';

    const call = prepareVaultTransfers({
      requiredDataForVaults: vi
        .fn()
        .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { data: BigNumber.from(3000) }])
        .mockReturnValueOnce([{ data: BigNumber.from(2200) }, { data: BigNumber.from(3000) }]),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, custodianAddress);

    expect((transfers.error as Error).message).toBe('Custodian amount should be bigger or same as expected amount');
  });

  it('should return an error if any of the external calls fails', async () => {
    const custodianAddress = '0x555';

    const call = prepareVaultTransfers({
      requiredDataForVaults: vi
        .fn()
        .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { error: true }])
        .mockReturnValueOnce([{ error: true }, { data: BigNumber.from(3000) }]),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, custodianAddress);

    expect((transfers.error as AggregateError).errors).toStrictEqual([true, true]);
  });

  it('should return just transfers to a vault and its entities', async () => {
    const custodianAddress = '0x555';

    const config: DistributionConfig[] = [
      generateMock(DistributionConfigSchema),
      generateMock(DistributionConfigSchema),
    ];
    config[0].percentage = 0.8;
    config[1].percentage = 1;

    const call = prepareAllTransfers({
      prepareVaultTransfers: prepareVaultTransfers({
        requiredDataForVaults: vi
          .fn()
          .mockReturnValue([{ data: BigNumber.from(1100) }, { data: BigNumber.from(1200) }]),
      }),
      distributionConfig: vi.fn().mockReturnValue({ data: config }),
    });

    const vault = generateMock(VaultSchema);
    vault.address = '0x1';
    const transfers = await call([vault], [{ vaults: { id: vault.id } } as any], custodianAddress);

    expect(transfers.data?.length).toBe(3);
    expect(transfers.data?.[0].address).toBe('0x1');
    expect(transfers.data?.[0].custodian_address).toBe('0x555');
    expect(transfers.data?.[0].amount.toString()).toBe('1100');

    expect(transfers.data?.[1].address).toBe(config[0].vault_distribution_entities?.address);
    expect(transfers.data?.[1].custodian_address).toBe('0x555');
    expect(transfers.data?.[1].amount.toString()).toBe('80');

    expect(transfers.data?.[2].address).toBe(config[1].vault_distribution_entities?.address);
    expect(transfers.data?.[2].custodian_address).toBe('0x555');
    expect(transfers.data?.[2].amount.toString()).toBe('20');
  });

  it('should return a proportional split between multiple vaults and entities', async () => {
    const custodianAddress = '0x555';

    const config: DistributionConfig[] = [
      generateMock(DistributionConfigSchema),
      generateMock(DistributionConfigSchema),
    ];
    config[0].percentage = 0.8;
    config[1].percentage = 1;

    const call = prepareAllTransfers({
      prepareVaultTransfers: prepareVaultTransfers({
        requiredDataForVaults: vi
          .fn()
          .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { data: BigNumber.from(3600) }])
          .mockReturnValueOnce([{ data: BigNumber.from(2200) }, { data: BigNumber.from(3600) }]),
      }),
      distributionConfig: vi.fn().mockReturnValue({ data: config }),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, vaults.map((v) => ({ vaults: v })) as any, custodianAddress);

    expect(transfers.data?.length).toBe(6);
    expect(transfers.data?.[0].address).toBe(vaults[0].address);
    expect(transfers.data?.[0].custodian_address).toBe('0x555');
    expect(transfers.data?.[0].amount.toString()).toBe('1100');

    expect(transfers.data?.[1].address).toBe(vaults[1].address);
    expect(transfers.data?.[1].custodian_address).toBe('0x555');
    expect(transfers.data?.[1].amount.toString()).toBe('2200');

    expect(transfers.data?.[2].address).toBe(config[0].vault_distribution_entities?.address);
    expect(transfers.data?.[2].custodian_address).toBe('0x555');
    expect(transfers.data?.[2].amount.toString()).toBe('80');

    expect(transfers.data?.[3].address).toBe(config[1].vault_distribution_entities?.address);
    expect(transfers.data?.[3].custodian_address).toBe('0x555');
    expect(transfers.data?.[3].amount.toString()).toBe('20');

    expect(transfers.data?.[4].address).toBe(config[0].vault_distribution_entities?.address);
    expect(transfers.data?.[4].custodian_address).toBe('0x555');
    expect(transfers.data?.[4].amount.toString()).toBe('160');

    expect(transfers.data?.[5].address).toBe(config[1].vault_distribution_entities?.address);
    expect(transfers.data?.[5].custodian_address).toBe('0x555');
    expect(transfers.data?.[5].amount.toString()).toBe('40');
  });

  it('should return an error if there is not enough in the custodian to cover all vault transfer', async () => {
    const custodianAddress = '0x555';

    const config: DistributionConfig[] = [
      generateMock(DistributionConfigSchema),
      generateMock(DistributionConfigSchema),
    ];
    config[0].percentage = 0.8;
    config[1].percentage = 1;

    const call = prepareAllTransfers({
      prepareVaultTransfers: prepareVaultTransfers({
        requiredDataForVaults: vi
          .fn()
          .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { data: BigNumber.from(3000) }])
          .mockReturnValueOnce([{ data: BigNumber.from(2200) }, { data: BigNumber.from(3000) }]),
      }),
      distributionConfig: vi.fn().mockReturnValue({ data: config }),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, vaults.map((v) => ({ vaults: v })) as any, custodianAddress);

    expect((transfers.error as Error).message).toBe('Custodian amount should be bigger or same as expected amount');
  });

  it('should return an error if any of the external calls fail', async () => {
    const custodianAddress = '0x555';

    const config: DistributionConfig[] = [
      generateMock(DistributionConfigSchema),
      generateMock(DistributionConfigSchema),
    ];
    config[0].percentage = 0.8;
    config[1].percentage = 1;

    const call = prepareAllTransfers({
      prepareVaultTransfers: prepareVaultTransfers({
        requiredDataForVaults: vi
          .fn()
          .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { error: true }])
          .mockReturnValueOnce([{ error: true }, { data: BigNumber.from(3000) }]),
      }),
      distributionConfig: vi.fn().mockReturnValue({ data: config }),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, vaults.map((v) => ({ vaults: v })) as any, custodianAddress);

    expect((transfers.error as AggregateError).errors).toStrictEqual([true, true]);
  });

  it('should return an error if the distribution config call fails', async () => {
    const custodianAddress = '0x555';

    const config: DistributionConfig[] = [
      generateMock(DistributionConfigSchema),
      generateMock(DistributionConfigSchema),
    ];
    config[0].percentage = 0.8;
    config[1].percentage = 1;

    const call = prepareAllTransfers({
      prepareVaultTransfers: prepareVaultTransfers({
        requiredDataForVaults: vi
          .fn()
          .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { data: BigNumber.from(3600) }])
          .mockReturnValueOnce([{ data: BigNumber.from(2200) }, { data: BigNumber.from(3600) }]),
      }),
      distributionConfig: vi.fn().mockReturnValueOnce({ data: config }).mockReturnValueOnce({ error: true }),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, vaults.map((v) => ({ vaults: v })) as any, custodianAddress);

    expect((transfers.error as AggregateError).errors).toStrictEqual([true]);
  });

  it('should return an error if the distribution underflows', async () => {
    const custodianAddress = '0x555';

    const config: DistributionConfig[] = [
      generateMock(DistributionConfigSchema),
      generateMock(DistributionConfigSchema),
    ];
    config[0].percentage = 0.0008;
    config[1].percentage = 1;

    const call = prepareAllTransfers({
      prepareVaultTransfers: prepareVaultTransfers({
        requiredDataForVaults: vi
          .fn()
          .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { data: BigNumber.from(3600) }])
          .mockReturnValueOnce([{ data: BigNumber.from(2200) }, { data: BigNumber.from(3600) }]),
      }),
      distributionConfig: vi.fn().mockReturnValue({ data: config }),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, vaults.map((v) => ({ vaults: v })) as any, custodianAddress);

    expect((transfers.error as AggregateError).errors).toBeDefined();
  });
});
