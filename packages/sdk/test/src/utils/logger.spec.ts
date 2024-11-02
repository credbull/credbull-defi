import { expect, test } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

import { createProcessedLogger, initProcessedLogCache, processedLogCache } from '../utils/logger';

const testLogFilePath = path.join(__dirname, '../../../logs/test-staking-processed.json');

test.describe('Logger Initialization with Custom File Path', () => {
  test.beforeEach(() => {
    // Create test log file with sample entries
    fs.writeFileSync(
      testLogFilePath,
      [
        JSON.stringify({
          level: 'info',
          message: { chainId: 31137, VaultDeposit: { id: 1, receiver: '0x123', depositAmount: '1000' } },
          timestamp: '2024-11-02T00:00:00Z',
        }),
        JSON.stringify({
          level: 'info',
          message: { chainId: 31137, VaultDeposit: { id: 2, receiver: '0x456', depositAmount: '2000' } },
          timestamp: '2024-11-02T01:00:00Z',
        }),
      ].join('\n'),
    );

    initProcessedLogCache(testLogFilePath); // Load cache from the test file
  });

  test.afterEach(() => {
    fs.unlinkSync(testLogFilePath); // Clean up the test log file
    processedLogCache.length = 0; // Clear in-memory log cache
  });

  test('should load processedLogCache with entries from a custom file path', () => {
    createProcessedLogger(testLogFilePath); // Use the test-specific logger

    expect(processedLogCache).toHaveLength(2);
    expect(processedLogCache).toEqual([
      {
        level: 'info',
        message: { chainId: 31137, VaultDeposit: { id: 1, receiver: '0x123', depositAmount: '1000' } },
        timestamp: '2024-11-02T00:00:00Z',
      },
      {
        level: 'info',
        message: { chainId: 31137, VaultDeposit: { id: 2, receiver: '0x456', depositAmount: '2000' } },
        timestamp: '2024-11-02T01:00:00Z',
      },
    ]);
  });
});
