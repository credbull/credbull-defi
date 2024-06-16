import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';

import { AppModule } from '../app.module';

describe('Throttling', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    await app.listen(3002); // Ensure the app listens on the correct port
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(async () => {
    await app.close();
  });

  it('Should return Status Code 429 ("Too Many Requests" when rate limit is exceeded', async () => {
    const results = [];
    for (let i = 0; i < 20; i++) {
      results.push(request(app.getHttpServer()).get('/').send());
    }

    let foundone = false;
    for (let i = 0; i < results.length; i++) {
      const response = await results[i];

      // 429 is too many requests
      if (response.status == 429) {
        foundone = true;
        console.log(response.status);
      }
    }

    expect(foundone).toBe(true);
  });
});
