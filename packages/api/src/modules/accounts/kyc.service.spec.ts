import { Test, TestingModule } from '@nestjs/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { EthersModule } from '../../clients/ethers/ethers.module';
import { Config } from '../../utils/module';

import { KycService } from './kyc.service';

describe('KycService', () => {
  let service: KycService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module(), EthersModule],
      providers: [KycService],
    }).compile();

    service = await module.resolve<KycService>(KycService);
  });

  it('should have a status method', () => {
    expect(service.status).toBeDefined();
  });
});
