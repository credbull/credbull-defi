import { Test, TestingModule } from '@nestjs/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { Config } from '../../utils/module';

import { EthersService } from './ethers.service';

describe('EthersService', () => {
  let service: EthersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module()],
      providers: [EthersService],
    }).compile();

    service = await module.resolve<EthersService>(EthersService);
  });

  it('should have a deployer method', () => {
    expect(service.deployer).toBeDefined();
  });
});
