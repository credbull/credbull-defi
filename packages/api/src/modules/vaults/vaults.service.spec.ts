import { generateMock } from '@anatine/zod-mock';
import { BigNumber } from 'ethers';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { VaultSchema } from '../../types/db.dto';

import { VaultsService } from './vaults.service';

describe('VaultService', () => {
  // Ideally we don't want to test private methods, but given that VaultService relies heavily on
  // external calls, I took that approach of splitting the logic to create the transfers dtos from the main method
  // and test the private methods that create the dtos directly.
  let prepareVaultTransfers: (service: object) => (typeof VaultsService.prototype)['prepareVaultTransfers'];

  beforeEach(async () => {
    prepareVaultTransfers = (service: object) => VaultsService.prototype['prepareVaultTransfers'].bind(service);
  });

  it('should return just a single transfer to a vault', async () => {
    const custodianAddress = '0x555';

    const call = prepareVaultTransfers({
      requiredDataForVaults: vi.fn().mockReturnValue([{ data: BigNumber.from(1100) }, { data: BigNumber.from(2200) }]),
      distributionConfig: vi.fn().mockResolvedValue([]),
    });

    const vault = generateMock(VaultSchema);
    vault.address = '0x1';
    const transfers = await call([vault], custodianAddress);

    expect(transfers.data?.length).toBe(1);
    expect(transfers.data?.[0].address).toBe('0x1');
    expect(transfers.data?.[0].custodian_address).toBe('0x555');
    expect(transfers.data?.[0].custodianAmount.toString()).toBe('2200');
    expect(transfers.data?.[0].amount.toString()).toBe('1100');
  });

  it('should return just a all transfers', async () => {
    const custodianAddress = '0x555';

    const call = prepareVaultTransfers({
      requiredDataForVaults: vi
        .fn()
        .mockReturnValueOnce([{ data: BigNumber.from(1100) }, { data: BigNumber.from(3600) }])
        .mockReturnValueOnce([{ data: BigNumber.from(2200) }, { data: BigNumber.from(3600) }]),
      distributionConfig: vi.fn().mockResolvedValue([]),
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
      distributionConfig: vi.fn().mockResolvedValue([]),
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
      distributionConfig: vi.fn().mockResolvedValue([]),
    });

    const vaults = [generateMock(VaultSchema), generateMock(VaultSchema)];
    const transfers = await call(vaults, custodianAddress);

    expect((transfers.error as AggregateError).errors).toStrictEqual([true, true]);
  });
});
