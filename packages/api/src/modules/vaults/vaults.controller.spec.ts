import { ConsoleLogger } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { SupabaseClient } from '@supabase/supabase-js';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

import { SupabaseService } from '../../clients/supabase/supabase.service';
import { logger } from '../../utils/logger';
import { Config } from '../../utils/module';

import { VaultsController } from './vaults.controller';
import { VaultsModule } from './vaults.module';

describe('VaultsController', () => {
  let controller: VaultsController;
  let client: DeepMockProxy<SupabaseClient>;

  beforeEach(async () => {
    client = mockDeep<SupabaseClient>();

    const service = { admin: () => ({}), client: () => client };

    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module(), VaultsModule],
      providers: [{ provide: ConsoleLogger, useValue: logger }],
    })
      .overrideProvider(SupabaseService)
      .useValue(service)
      .compile();

    controller = await module.resolve<VaultsController>(VaultsController);
  });

  it('should return all current ready/matured vaults', async () => {
    const vault = {
      id: 1,
      type: 'fixed_yield',
      status: 'ready',
      address: '0x75537828f2ce51be7289709686A69CbFDbB714F1',
      strategy_address: '0x75537828f2ce51be7289709686A69CbFDbB714F1',
      deposits_opened_at: '2024-01-07T03:00:01+00:00',
      deposits_closed_at: '2024-01-14T02:59:59+00:00',
      redemptions_opened_at: '2024-01-07T03:00:01+00:00',
      redemptions_closed_at: '2024-01-14T02:59:59+00:00',
      owner: null,
      created_at: '2024-01-09T18:58:27.328262+00:00',
    };

    const builder = { select: vi.fn(), neq: vi.fn(), lt: vi.fn() };
    builder.select.mockReturnValueOnce(builder as any);
    builder.neq.mockReturnValueOnce(builder as any);
    builder.lt.mockReturnValueOnce({ data: [vault] } as any);

    client.from.mockReturnValue(builder as any);

    const { data } = await controller.current();

    expect(data.length).toBe(1);
  });

  it('should throw when there is an error', async () => {
    const builder = { select: vi.fn(), neq: vi.fn(), lt: vi.fn() };
    builder.select.mockReturnValueOnce(builder as any);
    builder.neq.mockReturnValueOnce(builder as any);
    builder.lt.mockReturnValueOnce({ error: new Error('Internal Server Error Exception') } as any);

    client.from.mockReturnValue(builder as any);

    try {
      await controller.current();
    } catch (e) {
      expect(e.message).toBe('Internal Server Error Exception');
      expect(e.status).toBe(500);
    }
  });

  it('should throw when data is null', async () => {
    const builder = { select: vi.fn(), neq: vi.fn(), lt: vi.fn() };
    builder.select.mockReturnValueOnce(builder as any);
    builder.neq.mockReturnValueOnce(builder as any);
    builder.lt.mockReturnValueOnce({ data: null } as any);

    client.from.mockReturnValue(builder as any);

    try {
      await controller.current();
    } catch (e) {
      console.log('errorr.......', e);
      expect(e.message).toBe('Not Found');
      expect(e.status).toBe(404);
    }
  });
});
