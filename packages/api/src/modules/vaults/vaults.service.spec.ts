import { BigNumber } from 'ethers';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { VaultsService } from './vaults.service';

describe('VaultService', () => {
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

    const transfers = await call(
      [
        {
          address: '0x123',
          asset_address: '0x456',
          opened_at: '2024-01-07T03:00:01+00:00',
          closed_at: '2024-01-14T02:59:59+00:00',
          type: 'fixed_yield',
          status: 'ready',
          strategy_address: '0x789',
          tenant: '1',
          id: 1,
          created_at: '2024-01-09T18:58:27.328262+00:00',
        },
      ],
      custodianAddress,
    );

    expect(transfers.data?.length).toBe(1);
    expect(transfers.data?.[0].address).toBe('0x123');
    expect(transfers.data?.[0].custodian_address).toBe('0x555');
    expect(transfers.data?.[0].custodianAmount.toString()).toBe('2200');
    expect(transfers.data?.[0].amount.toString()).toBe('1100');
  });
});
