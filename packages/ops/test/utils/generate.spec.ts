import { expect, test } from '@playwright/test';

import { assertAddress, assertEmail } from '@/utils/assert';
import { generateAddress, generateRandomEmail } from '@/utils/generate';

test.describe('Generating an address should', async () => {
  test('produce a valid address every iteration', async () => {
    for (let i = 0; i < 20; i++) {
      expect(() => assertAddress(generateAddress())).toPass();
    }
  });
});

test.describe('Generating an email should', async () => {
  test('produce a valid email every iteration', async () => {
    for (let i = 0; i < 20; i++) {
      expect(() => assertEmail(generateRandomEmail('test-' + i))).toPass();
    }
  });
});
