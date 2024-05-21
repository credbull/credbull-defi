import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

import { TomlConfigService } from './tomlConfig';

vi.mock('fs');

function loadConfig(envString: string) {
  const configFile = path.resolve(__dirname, `../../resource/${envString}.toml`);

  return fs.readFileSync(configFile, 'utf8');
}

describe('TomlConfigService', () => {
  let tomlConfigService: TomlConfigService;
  let configService: DeepMockProxy<ConfigService>;

  beforeEach(() => {
    vi.clearAllMocks();

    configService = mockDeep<ConfigService>();

    // simple mock that just adds -val to any key
    configService.getOrThrow.mockImplementation((key: string) => {
      return key + '-val';
    });

    // simple mock that just adds -val to any key
    configService.get.mockImplementation((key: string) => {
      return key + '-val';
    });
  });

  it('should load and parse the TOML config correctly', () => {
    const mockTomlContent = `
    [application]
    key = "val"
    `;

    (fs.readFileSync as vi.Mock).mockReturnValue(mockTomlContent);
    const config = loadConfig('local');

    expect(config).toBe(mockTomlContent);

    // Create a new instance of the service to ensure the config is loaded
    tomlConfigService = new TomlConfigService(configService);

    expect(tomlConfigService.config.application.key).toBe('val');
  });
});
