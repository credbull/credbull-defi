import { ConsoleLogger } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { logger } from '../../utils/logger';
import { TomlConfigService } from '../../utils/tomlConfig';

import { EthersService } from './ethers.service';

describe('EthersService', () => {
  let service: EthersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [EthersService, TomlConfigService, { provide: ConsoleLogger, useValue: logger }],
    }).compile();

    service = await module.resolve<EthersService>(EthersService);
  });

  it('should have a deployer method', () => {
    expect(service.operator).toBeDefined();
  });
});
