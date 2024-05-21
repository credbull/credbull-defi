import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { DeepMockProxy, mockDeep } from 'vitest-mock-extended';

import { TomlConfigService } from './tomlConfig';

const env = 'local';

function loadConfig() {
  const configFile = path.resolve(__dirname, `../../resource/${env}.toml`);

  return fs.readFileSync(configFile, 'utf8');
}

describe('TomlConfigService', () => {
  let tomlConfigService: TomlConfigService;
  let configService: DeepMockProxy<ConfigService>;

  beforeEach(() => {
    vi.clearAllMocks();

    configService = mockDeep<ConfigService>();

    configService.getOrThrow.mockImplementation((key: string) => {
      return key + '-val';
    });

    configService.get.mockImplementation((key: string) => {
      if ('ENVIRONMENT' == key) {
        return env;
      }

      return key + '-val';
    });
  });

  it('should load and parse the TOML config correctly', () => {
    const mockTomlContent = `
    [application]
    key = "val"
    `;

    vi.mock('fs');
    (fs.readFileSync as vi.Mock).mockReturnValue(mockTomlContent);
    const config = loadConfig();

    expect(config).toBe(mockTomlContent);

    // Create a new instance of the service to ensure the config is loaded
    tomlConfigService = new TomlConfigService(configService);

    expect(tomlConfigService.config.application.key).toBe('val');
  });
});
