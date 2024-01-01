import { Test, TestingModule } from '@nestjs/testing';
import { beforeEach, describe, expect, it } from 'vitest';

import { AppController } from './app.controller';
import { AppModule } from './app.module';

describe('AppController', () => {
  let controller: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({ imports: [AppModule] }).compile();

    controller = await app.resolve<AppController>(AppController);
  });

  it('should return "0.0.1"', () => {
    expect(controller.version()).toBe('0.0.1');
  });
});
