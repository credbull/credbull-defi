import { Test, TestingModule } from '@nestjs/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { Config } from '../../utils/module';

import { AccountsController } from './accounts.controller';
import { AccountsModule } from './accounts.module';

describe('AccountsController', () => {
  let controller: AccountsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      imports: [Config.module(), AccountsModule],
    }).compile();

    controller = await module.resolve<AccountsController>(AccountsController);
  });

  it('should have a status method', () => {
    expect(controller.status).toBeDefined();
  });
});
