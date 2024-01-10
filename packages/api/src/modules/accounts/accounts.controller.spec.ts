import { Test, TestingModule } from '@nestjs/testing';
import { SupabaseClient } from '@supabase/supabase-js';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

import { SupabaseService } from '../../clients/supabase/supabase.service';
import { Config } from '../../utils/module';

import { AccountsController } from './accounts.controller';
import { AccountsModule } from './accounts.module';
import { KYCStatus } from './kyc.dto';

describe('AccountsController', () => {
  let controller: AccountsController;
  let client: DeepMockProxy<SupabaseClient>;
  let admin: DeepMockProxy<SupabaseClient>;
  beforeEach(async () => {
    client = mockDeep<SupabaseClient>();
    admin = mockDeep<SupabaseClient>();

    const service = { client: () => client, admin: () => admin };

    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module(), AccountsModule],
    })
      .overrideProvider(SupabaseService)
      .useValue(service)
      .compile();

    controller = await module.resolve<AccountsController>(AccountsController);
  });

  it('should whitelist an existing account', async () => {
    const user_id = '1';
    const address = '0x0000000000';

    const select = vi.fn();
    const eq = vi.fn();
    const single = vi.fn();
    select.mockReturnValueOnce({ eq } as any);
    eq.mockReturnValueOnce({ single } as any);
    single.mockResolvedValueOnce({ data: { user_id } } as any);

    const insert = vi.fn();
    insert.mockResolvedValueOnce({ data: {} } as any);

    admin.from.mockReturnValue({ select, insert } as any);

    const { status } = await controller.whitelist({ address });

    expect(insert.mock.calls[0][0]).toStrictEqual({ address, user_id, event_name: 'accepted' });
    expect(status).toBe(KYCStatus.ACTIVE);
  });

  it('should verify the signature and link the wallet', async () => {
    const user_id = '1';
    const dto = {
      message:
        'localhost:3000 wants you to sign in with your Ethereum account:\n0xA57FCEE8db30A62b1FE8Fab0431Ac2d2A6aBbAfB\n\nBy connecting your wallet, you agree to the Terms of Service and Privacy Policy.\n\nURI: http://localhost:3000\nVersion: 1\nChain ID: 10\nNonce: zIok3D7zIKBu3VAnl\nIssued At: 2024-01-10T09:22:45.985Z',
      signature:
        '0x9bc8fd1dd2c25bead1582e3ecd4a949ee6093ef47d3d1bcd82c5cf08e71f7fc33979d365cddcb3c1172b4e72fab0775b53ab60af990b23f0fa0bdc8cca03059c1b',
    };

    const insert = vi.fn();
    insert.mockResolvedValueOnce({ data: { user_id } } as any);

    client.auth.getUser.mockResolvedValueOnce({ data: { user: { id: user_id } } } as any);
    client.from.mockReturnValue({ insert } as any);

    const data = await controller.linkWallet(dto);

    expect(data.user_id).toBe(user_id);
  });

  it('should not verify the signature and throw an error', async () => {
    const user_id = '1';
    const dto = {
      message:
        'localhost:3000 wants you to sign in with your Ethereum account:\n0xA57FCEE8db30A62b1FE8Fab0431Ac2d2A6aBbAfB\n\nBy connecting your wallet, you agree to the Terms of Service and Privacy Policy.\n\nURI: http://localhost:3000\nVersion: 1\nChain ID: 10\nNonce: zIok3D7zIKBu3VAnl\nIssued At: 2024-01-10T09:22:45.985Z',
      signature:
        '0xd4a949ee6093ef47d3d1bcd82c5cf08e71f7fc33979d365cddcb3c1172b4e72fab0775b53ab60af990b23f0fa0bdc8cca03059c1b',
    };

    client.auth.getUser.mockResolvedValueOnce({ data: { user: { id: user_id } } } as any);

    try {
      await controller.linkWallet(dto);
    } catch (e) {
      expect(e.error.type).toBe('Signature does not match address of the message.');
    }
  });
});
