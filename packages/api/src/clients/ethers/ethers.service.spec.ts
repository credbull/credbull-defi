import { ConsoleLogger } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { logger } from '../../utils/logger';
import { Config } from '../../utils/module';

import { EthersService } from './ethers.service';

describe('EthersService', () => {
  let service: EthersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module()],
      providers: [EthersService, { provide: ConsoleLogger, useValue: logger }],
    }).compile();

    service = await module.resolve<EthersService>(EthersService);
  });

  it('should have a deployer method', () => {
    expect(service.deployer).toBeDefined();
  });
});
