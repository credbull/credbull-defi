import { Test, TestingModule } from '@nestjs/testing';
import { SupabaseClient } from '@supabase/supabase-js';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

import { SupabaseService } from '../../clients/supabase/supabase.service';
import { Config } from '../../utils/module';

import { KYCStatus } from './account-status.dto';
import { AccountsController } from './accounts.controller';
import { AccountsModule } from './accounts.module';

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
    insert.mockResolvedValueOnce({ statusText: 'OK' } as any);

    admin.from.mockReturnValue({ select, insert } as any);

    const { status } = await controller.whitelist({ address });

    expect(insert.mock.calls[0][0]).toStrictEqual({ address, user_id, event_name: 'accepted' });
    expect(status).toBe(KYCStatus.ACTIVE);
  });
});
