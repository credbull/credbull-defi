import { Test, TestingModule } from '@nestjs/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { Config } from '../../utils/module';

import { SupabaseService } from './supabase.service';

describe('SupabaseService', () => {
  let service: SupabaseService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module()],
      providers: [SupabaseService],
    }).compile();

    service = await module.resolve<SupabaseService>(SupabaseService);
  });

  it('should have a client method', () => {
    expect(service.client).toBeDefined();
  });
});
